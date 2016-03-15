--------------------------------------------------------
--  DDL for Procedure DASHBOARD_OUTSOURCING
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."DASHBOARD_OUTSOURCING" (
  P_IN_OBJECT_ID in varchar2,
  UNSIGN_NEW out varchar2, -- 新案來文
  TODO out varchar2, -- 線上公文 
  TODO_P out varchar2, -- 紙本公文 
  DONE out varchar2, -- 線上已銷號 
  DONE_P out varchar2, --紙本已銷號
  NEW_A out varchar2, -- 線上新申請
  NEW_P out varchar2, -- 紙本新申請
  THISMON_TODO out varchar2, -- 當月應辦
  THISMON_DONE out varchar2, -- 當月辦結
  LASTMON_ACC out varchar2, -- 上月累計
  TO_EXCEED out varchar2) -- 即將逾期
is
begin
  /*
  Desc: DashBoard for OutSourcing
  ModifyDate :  105/01/08
  104/07/09 : change the condition for calcuate close receive (THISMON_DONE) by sign_date (close date of form)
  104/07/22 : UNSIGN_NEW add filter AND RETURN_NO not in ('4','A','B','C');
  104/09/09: exclude the receives which process_result = 57001
  104/11/20: 紙本個人持有不用排除已監印
  104/12/14: 紙本個人持有仍要參考spt23
  104/12/21: 紙本持有不用再判斷912
  105/01/08: add condition for paper receive:  spt21.accept_date >= '1050101'
  */
  -- 紙本已領未簽 新案來文
    SELECT COUNT(1)
    INTO UNSIGN_NEW
    FROM SPT23
    WHERE SPT23.data_seq = (select max(data_seq) from spt23 s23 where SPT23.receive_no = s23.receive_no) 
      AND TRANS_NO = '912'
        AND SUBSTR(RECEIVE_NO,4,1) = '2'
        AND SPT23.ACCEPT_DATE IS NULL
        AND OBJECT_TO = P_IN_OBJECT_ID
        AND not exists ( select 1 from spt21 where spt21.receive_no = spt23.receive_no and spt21.process_result = '57001')
        ;
      
  -- 線上 公文 已銷號
   SELECT
   COUNT(CASE WHEN s21.PROCESS_RESULT is null  AND RECEIVE.RECEIVE_NO is not null THEN 1 ELSE NULL END) AS TODO,
         COUNT(CASE WHEN s21.PROCESS_RESULT is not null AND s21.process_result != '57001'  THEN 1 ELSE NULL END) AS DONE
   INTO TODO, DONE
   FROM  RECEIVE  
   JOIN SPT21 s21 ON s21.RECEIVE_NO = RECEIVE.RECEIVE_NO 
   WHERE s21.PROCESSOR_NO = P_IN_OBJECT_ID
   AND RECEIVE.step_code > '0'
   AND RECEIVE.step_code < '8'
    ;
 
  
  -- 紙本 公文
  SELECT COUNT(1)
  INTO TODO_P
    FROM SPT21 R
    JOIN SPT23 ON R.receive_no = SPT23.receive_no   and R.trans_seq = spt23.data_seq AND R.OBJECT_ID = Spt23.OBJECT_TO
        LEFT JOIN SPM75 T
          ON R.TYPE_NO = T.TYPE_NO
       WHERE PROCESS_RESULT IS  NULL
         AND R.object_id = P_IN_OBJECT_ID
      --   AND R.trans_no = '912'  -- mark by susan 104/12/21
         AND R.process_result != '57001'
         AND  R.accept_date >= '1050101'
         ;
      
  -- 紙本 已銷號
  SELECT COUNT(1)
  INTO DONE_P
  FROM SPT21
  JOIN spt23
  ON spt21.receive_no = spt23.receive_no   AND spt21.trans_seq = spt23.data_seq AND SPT21.OBJECT_ID = Spt23.OBJECT_TO
        LEFT JOIN SPM75
          on SPT21.TYPE_NO = SPM75.TYPE_NO
        WHERE  PROCESS_RESULT IS NOT NULL
         AND SPT21.object_id = P_IN_OBJECT_ID
    --     AND SPT21.trans_no = '912'  -- mark by susan 104/12/21
         AND SPT21.process_result != '57001'
         AND  spt21.accept_date >= '1050101'
         ;
      
  -- 線上 新申請 
  SELECT COUNT(1)
  INTO NEW_A
  FROM RECEIVE
  WHERE STEP_CODE = '0'
  AND doc_complete = '1'
  AND RETURN_NO not in ('4','A','B','C','D')
  AND SUBSTR(RECEIVE_NO,4,1) = '2'
  AND not exists (select 1 from spt21 where spt21.process_result = '57001' and spt21.receive_no = receive.receive_no)
  ;
  
  -- 紙本 新申請
  SELECT COUNT(1)
  INTO NEW_P
  FROM SPT21
  WHERE  SUBSTR(RECEIVE_NO,4,1) = '2'
      AND PROCESS_RESULT IS NULL
      AND OBJECT_ID IN (
          SELECT PROCESSOR_NO 
          FROM SPM63 
          WHERE DEPT_NO ='70012' AND QUIT_DATE IS NULL OR (PROCESSOR_NO='70012' )
      )
      ;
      
     -- 當月應辦 
   SELECT nvl(sum(d),0)  INTO THISMON_TODO
   FROM
   ( 
    SELECT  nvl(b.base,0) * nvl(mday.days,0) + nvl(a.factor,0) d
    FROM quota a JOIN quota_base b on a.processor_no = b.processor_no AND a.yyyy = b.yyyy
    LEFT JOIN (SELECT  substr(date_bc,1,6) yyyymm, count(1) days   
    FROM spmff WHERE  date_flag = 1 group by substr(date_bc,1,6) ) mday
    on mday.yyyymm = b.yyyy || a.mm
    WHERE trim(a.processor_no) = P_IN_OBJECT_ID
    AND a.yyyy = to_char(sysdate,'yyyy') AND a.mm = to_char(sysdate,'MM')
    )
    ;
    -- 個人將逾期
    SELECT  
         SUM( case when to_char(sysdate,'yyyyMMdd') between   cdate.date_bc and to_number(substr( spt21.control_date,1,3))+1911 || substr( spt21.control_date,4,4)
                   and step_code != '4' then 1 else 0 end) 
        INTO TO_EXCEED 
    FROM receive join spt21 On receive.receive_no = spt21.receive_no
    LEFT JOIN 
    (
      SELECT row_number() over(partition by spt21.receive_no order by date_chinese desc) d  ,spt21.control_date,  spmff.date_bc ,spt21.receive_no
      FROM spt21 join ap.spmff on spmff.date_bc < to_number(substr( spt21.control_date,1,3))+1911 || substr( spt21.control_date,4,4)
      JOIN receive on spt21.receive_no = receive.receive_no
      WHERE  spmff.date_flag = 1
      AND spt21.processor_no = P_IN_OBJECT_ID
     ) cdate on cdate.receive_no = receive.receive_no 
    WHERE  receive.step_code >= '2'
    AND    receive.step_code < '8'
    AND spt21.process_result != '57001'
    AND spt21.processor_no = P_IN_OBJECT_ID
    AND cdate.d = 2
     and substr(to_char(to_number(receive.process_date) + 19110000),1,6)  = to_char(sysdate,'yyyyMM')
    ;
    
   select nvl(sum(1),0) into THISMON_DONE  -- 當月辦結
  from receive
  where step_code = '8'
  and processor_no = P_IN_OBJECT_ID
   and substr(to_char(to_number(sign_date) + 19110000),1,6)  = to_char(sysdate,'yyyyMM')
   and not exists (select 1 from spt21 where spt21.process_result = '57001' and spt21.receive_no = receive.receive_no)
   ;
   dbms_output.put_line(THISMON_TODO);
  
end dashboard_outsourcing;

/
