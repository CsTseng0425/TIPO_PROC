--------------------------------------------------------
--  DDL for Procedure DASHBOARD_PERSONAL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."DASHBOARD_PERSONAL" (
  P_IN_OBJECT_ID in varchar2,
  NEW_A out varchar2 , -- 線上新申請
  NEW_P out varchar2 , -- 紙本新申請
  APPEND_A out varchar2 , -- 線上後續文
  APPEND_P out varchar2 , --紙本後續文
  TODO out varchar2 , -- 線上公文 
  TODO_P out varchar2 , -- 紙本公文 
  DONE out varchar2 , -- 線上已銷號 
  DONE_P out varchar2 , --紙本已銷號
  REJECTED out varchar2 , -- 線上主管退辦
  REJECTED_P out varchar2 , -- 紙本主管退辦
  UNSIGN_NEW out varchar2 , -- 新案來文
  UNSIGN_APPEND out varchar2 , -- 後續來文
  THISMON_TODO out varchar2 , -- 當月應辦
  THISMON_DONE out varchar2 , -- 當月辦結
  LASTMON_ACC out varchar2 , -- 上月累計
  ALL_ACC out varchar2 , -- 迄今累計
  PERSONAL_EXCEED out varchar2 , -- 個人逾期
  AUTO_SHIFT out varchar2 , --自動輸辦
  OTHER_REJECTED out varchar2 , -- 他科退辦
  CHIEF_DISPATCH out varchar2 , -- 科長分派
  TO_EXCEED out varchar2 , -- 將逾期
  FOR_APPROVE out varchar2 , -- 陳核中
  EXCEEDED out varchar2   -- 已逾期
  )
is
   min_date receive.process_date%type;
begin
  /*
  ModifyDate : 105/01/08
   update THISMON_DONE 當月已辦的計算
  104/07/07 : change the waiting receiver calculating rule => return_no not in ('4','A','B','C')
  104/07/07 : add TO_EXCEED , FOR_APPROVE ,EXCEEDED
  104/07/09 : change the condition for calcuate close receive (THISMON_DONE) by sign_date (close date of form)
  104/07/23 : change conditoin for project  processor_no ,change from spt31.sch_processor_no to appl.appl_no
  104/07/30 : turning 紙本已領未簽 , select spt23 ,not spt21
  104/07/31: update the condition for accept date
  104/09/09: exclude the receives which process_result = 57001
  104/11/20: 紙本個人持有不用排除已監印
  104/12/14: 紙本個人持有仍要參考spt23
   104/12/21: 紙本持有不用再判斷912
   104/12/23: 個人線上辦結條件再加判斷階段別
   105/01/08: add condition for paper receive:  spt21.accept_date >= '1050101'
   105/01/29: 更正個人逾期統計-排除檢核spm56
   105/02/18: update NEW_P, APPEND_P
  */
  -- 線上 新申請 後續文

  SELECT
     COUNT(CASE WHEN SUBSTR(RECEIVE.RECEIVE_NO,4,1) in ('1','2') THEN  1 ELSE null END),
    COUNT(CASE WHEN SUBSTR(RECEIVE.RECEIVE_NO,4,1) = '3' THEN  1 ELSE NULL END)
  INTO NEW_A, APPEND_A 
  FROM RECEIVE
  JOIN SPT21 s21 ON s21.RECEIVE_NO = RECEIVE.RECEIVE_NO 
  WHERE STEP_CODE = '0'
  AND  doc_complete = '1'
  AND RETURN_NO not in ('4','A','B','C','D')
  AND not exists (select 1 from spt21 where spt21.process_result = '57001' and spt21.receive_no = receive.receive_no)
  AND s21.online_flg = 'Y'
  ;
    dbms_output.put_line( NEW_A || ',' || APPEND_A  );
  -- 紙本 新申請後續文
  SELECT
      COUNT(CASE WHEN SUBSTR(SPT21.RECEIVE_NO,4,1) = '2' THEN  1 ELSE NULL END),
      COUNT(CASE WHEN SUBSTR(SPT21.RECEIVE_NO,4,1) = '3' THEN  1 ELSE NULL END)
  INTO NEW_P, APPEND_P
  FROM SPT21  join spt23
   ON SPT21.receive_no = SPT23.receive_no
   and SPT21.object_id = Spt23.OBJECT_TO
   and spt21.trans_seq = spt23.data_seq
  WHERE  PROCESS_RESULT IS NULL
    AND ( spt21.object_id  = '70012' or spt21.object_id  = '60037' )
    AND spt21.accept_date >= '1050101'
    ;
        dbms_output.put_line( NEW_P || ',' || APPEND_P );
  -- 線上 公文 已銷號 主管退辦
  SELECT
   COUNT(CASE WHEN s21.PROCESS_RESULT is null  AND RECEIVE.RECEIVE_NO is not null THEN 1 ELSE NULL END) AS TODO,
          COUNT(CASE WHEN s21.PROCESS_RESULT is not null AND step_code < '5' AND s21.process_result != '57001'  AND return_no not in ('4','A','B','C','D')   THEN 1 ELSE NULL END) AS DONE,
          COUNT(CASE WHEN step_code = '5' and substr(RECEIVE.processor_no,1,1) != 'P'  AND s21.process_result != '57001'
               THEN 1 ELSE NULL END) AS REJECTED     
   INTO TODO, DONE, REJECTED 
  FROM  RECEIVE  
  JOIN SPT21 s21 ON s21.RECEIVE_NO = RECEIVE.RECEIVE_NO 
  WHERE s21.PROCESSOR_NO = P_IN_OBJECT_ID
  AND RECEIVE.step_code > '0'
  AND RECEIVE.step_code < '8'
    ;
    dbms_output.put_line(TODO || ',' || DONE || ',' || REJECTED );
  -- 紙本 公文
  SELECT COUNT(1)
  INTO TODO_P
  FROM SPT21
  JOIN SPT23 ON SPT21.receive_no = SPT23.receive_no   and spt21.trans_seq = spt23.data_seq AND SPT21.OBJECT_ID = Spt23.OBJECT_TO
  WHERE  TRIM(PROCESS_RESULT) IS NULL
    AND SPT21.object_id = P_IN_OBJECT_ID
    AND spt21.accept_date >= '1050101'
 --   AND SPT21.trans_no = '912'  -- mark by susan 104/12/21
    ;
      dbms_output.put_line(TODO_P);
  -- 紙本 已銷號
  SELECT COUNT(1)
  INTO DONE_P
  FROM SPT21
  JOIN spt23
  ON spt21.receive_no = spt23.receive_no   AND spt21.trans_seq = spt23.data_seq AND SPT21.OBJECT_ID = Spt23.OBJECT_TO
  LEFT JOIN SPM75    on SPT21.TYPE_NO = SPM75.TYPE_NO
        WHERE  PROCESS_RESULT IS NOT NULL
         AND SPT21.object_id = P_IN_OBJECT_ID
     --    AND SPT21.trans_no = '912'  -- mark by susan 104/12/21
         AND PROCESS_RESULT != '57001'
         AND spt21.accept_date >= '1050101'
   ;
  -- 紙本 主管退辦
  SELECT '' INTO REJECTED_P from dual;
  /*
  --紙本 主管退辦 無值
  SELECT count(1) INTO REJECTED_P
  FROM spt21
  LEFT join spt41 on spt21.receive_no = spt41.receive_no
  AND spt41.appl_no = spt21.appl_no
  LEFT join SPT23 a on a.receive_no = SPT21.receive_no
  LEFT join SPT23 b  on b.receive_no = SPT21.receive_no
  WHERE  spt21.object_id = P_IN_OBJECT_ID
  AND spt21.process_result != '57001'
  AND a.TRANS_NO in ('921','922','923')
  AND a.OBJECT_FROM in ( select processor_no from spm63 where substr(dept_no,1,3) = '700' and title  in ('科長','專門委員','科員')  
         and processor_no = B.processor_no
        and spm63.quit_date is not null
      )
  AND b.TRANS_NO='913'
  AND b.OBJECT_TO= P_IN_OBJECT_ID
  AND a.DATA_SEQ = b.DATA_SEQ +1
  ;
  */
      dbms_output.put_line(REJECTED_P);
  -- 紙本已領未簽 新案來文 後續來文
      SELECT COUNT(CASE WHEN SUBSTR(spt21.RECEIVE_NO,4,1) = '2' THEN 1 ELSE NULL END),
           COUNT(CASE WHEN SUBSTR(spt21.RECEIVE_NO,4,1) = '3' THEN 1 ELSE NULL END)
    INTO UNSIGN_NEW, UNSIGN_APPEND
    FROM SPT21
    JOIN spt23
    ON spt21.receive_no = spt23.receive_no   AND spt21.trans_seq = spt23.data_seq 
    WHERE  spt23.TRANS_NO = '912'
     AND spt23.ACCEPT_DATE IS NULL
     AND spt23.OBJECT_TO = P_IN_OBJECT_ID
     AND  (spt21.process_result = '57001'  or spt21.process_result  is null)
     ;
   dbms_output.put_line(UNSIGN_NEW || ',' || UNSIGN_APPEND);
   -- 個人逾期 , 自動輪辦 , 他科退辦 ,科長分派
    SELECT count(CASE WHEN appl.divide_code = '1' and appl.is_overtime='1' THEN 1 ELSE null END),
           count(CASE WHEN appl.divide_code = '2' THEN 1 ELSE null END),
           count(CASE WHEN appl.divide_code = '3' THEN 1 ELSE null END),
           count(CASE WHEN appl.divide_code = '4' THEN 1 ELSE null END)
    INTO PERSONAL_EXCEED, AUTO_SHIFT ,OTHER_REJECTED ,CHIEF_DISPATCH
    FROM appl join spt31 on appl.appl_no = spt31.appl_no
    WHERE  appl.processor_no = P_IN_OBJECT_ID;
    dbms_output.put_line(PERSONAL_EXCEED|| ',' || AUTO_SHIFT || ',' ||OTHER_REJECTED || ',' ||CHIEF_DISPATCH);
    -- 個人將逾期, 已逾期
     SELECT SUM(case
               when to_char(sysdate, 'yyyyMMdd') between cdate.date_bc and
                    to_number(substr(spt21.control_date, 1, 3)) + 1911 ||
                    substr(spt21.control_date, 4, 4) and step_code != '4' then
                1
               else
                0
             end),
         SUM(case
               when to_char(sysdate, 'yyyyMMdd') between cdate.date_bc and
                    to_number(substr(spt21.control_date, 1, 3)) + 1911 ||
                    substr(spt21.control_date, 4, 4) and step_code = '4' then
                1
               else
                0
             end),
         SUM(case
               when to_char(sysdate, 'yyyyMMdd') >
                    to_number(substr(spt21.control_date, 1, 3)) + 1911 ||
                    substr(spt21.control_date, 4, 4) then
                1
               else
                0
             end)
    INTO TO_EXCEED , FOR_APPROVE ,EXCEEDED
    FROM receive  join spt21  On receive.receive_no = spt21.receive_no
    LEFT JOIN (SELECT row_number() over(partition by spt21.receive_no order by date_chinese desc) d,
                      spt21.control_date,
                      spmff.date_bc,
                      spt21.receive_no
                 FROM spt21
                 join ap.spmff
                   on spmff.date_bc <
                      to_number(substr(spt21.control_date, 1, 3)) + 1911 ||
                      substr(spt21.control_date, 4, 4)
                 JOIN receive
                   on spt21.receive_no = receive.receive_no
                WHERE spmff.date_flag = 1
                  AND spt21.processor_no = P_IN_OBJECT_ID ) cdate
      on cdate.receive_no = receive.receive_no
   WHERE receive.step_code >= '2'
     AND receive.step_code < '8'
     AND (spt21.process_result != '57001' or spt21.process_result is null)
     AND receive.processor_no = P_IN_OBJECT_ID
     AND cdate.d = 2;
   dbms_output.put_line(TO_EXCEED || ',' || EXCEEDED);
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
    
        
  select nvl(sum(1),0) into THISMON_DONE  -- 當月辦結
  from receive
  where step_code = '8'
   AND processor_no = P_IN_OBJECT_ID
   AND substr(to_char(to_number(sign_date) + 19110000),1,6)  = to_char(sysdate,'yyyyMM')
   AND not exists (select 1 from spt21 where spt21.process_result = '57001' and spt21.receive_no = receive.receive_no)
   ;
   dbms_output.put_line(THISMON_TODO);
   
  select min(yyyy||mm) into min_date from quota;
   
     SELECT  c.s -r.d  into LASTMON_ACC -- 上月累計
      FROM (
           SELECT  sum(nvl(b.base, 0) * nvl(mday.days, 0) + nvl(a.factor, 0)) d
            FROM quota a
            JOIN quota_base b
              on a.processor_no = b.processor_no
             AND a.yyyy = b.yyyy
            LEFT JOIN (SELECT substr(date_bc, 1, 6) yyyymm, count(1) days
                        FROM spmff
                       WHERE date_flag = 1
                       group by substr(date_bc, 1, 6)) mday
              on mday.yyyymm = a.yyyy || a.mm
           where trim(a.processor_no) = P_IN_OBJECT_ID
           and a.yyyy || a.mm >=  min_date
           and a.yyyy || a.mm  <=  to_char(add_months(sysdate,-1),'yyyyMM')
            ) r
          left join 
          (
        select nvl(sum(1),0) s
        from receive
        where step_code = '8'
         AND processor_no = P_IN_OBJECT_ID
         AND substr(to_char(to_number(sign_date) + 19110000),1,6) >=  min_date
         AND substr(to_char(to_number(sign_date) + 19110000),1,6) <= to_char(add_months(sysdate,-1),'yyyyMM')
       AND not exists ( select 1 from spt21 where spt21.receive_no = RECEIVE.receive_no and spt21.process_result = '57001') 
          )  c  on 1=1
            ;
   
  
  SELECT  c.s -  r.d    into ALL_ACC -- 迄今累計
      FROM (
           SELECT  sum(nvl(b.base, 0) * nvl(mday.days, 0) + nvl(a.factor, 0)) d
            FROM quota a
            JOIN quota_base b
              on a.processor_no = b.processor_no
             AND a.yyyy = b.yyyy
            LEFT JOIN (SELECT substr(date_bc, 1, 6) yyyymm, count(1) days
                        FROM spmff
                       WHERE date_flag = 1
                       group by substr(date_bc, 1, 6)) mday
              on mday.yyyymm = b.yyyy || a.mm
           where trim(a.processor_no) = P_IN_OBJECT_ID
            and a.yyyy || a.mm >=  min_date
            and a.yyyy || a.mm <= to_char(sysdate,'yyyyMM')
            ) r
          left join 
          (
        select  nvl(sum(1),0) s
        from receive
        where step_code = '8'
         AND processor_no = P_IN_OBJECT_ID
         AND substr(to_char(to_number(sign_date) + 19110000),1,6) >=  min_date
         AND substr(to_char(to_number(sign_date) + 19110000),1,6)  <= to_char(sysdate,'yyyyMM')
        AND not exists ( select 1 from spt21 where spt21.receive_no = RECEIVE.receive_no and spt21.process_result = '57001') 
          )  c  on 1 =1
            ;
   

end dashboard_personal;

/
