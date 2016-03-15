--------------------------------------------------------
--  DDL for Procedure DASHBOARD_APPROVER
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."DASHBOARD_APPROVER" (
  P_IN_OBJECT_ID in varchar2,
  A_TODO out varchar2, -- 線上 公文
  A_TODO_P out varchar2, -- 紙本 公文
  A_TO_APPROVE out varchar2, -- 線上 待呈核
  A_TO_APPROVE_P out varchar2, -- 紙本 待呈核
  A_APPROVED out varchar2, -- 線上 已呈核
  A_APPROVED_P out varchar2, -- 紙本 已呈核
  A_UNSIGN_NEW out varchar2, -- 紙本已領未簽
  A_THISMON_TODO out varchar2, -- 當月應辦
  A_THISMON_DONE out varchar2, -- 當月辦結
  A_TO_EXCEED out varchar2) -- 即將逾期   
is
begin
  /* --------------------------------------------
   DESC: Dashboard for approver
   ModifyDate : 105/01/08
   ModifyItem:
  104/07/08: update the condition for waiting approved form
  104/07/31: update the condition for accept date
  104/09/09: exclude the receives which process_result = 57001
  104/11/20: 紙本個人持有不用排除已監印
  104/12/14: 紙本個人持有仍要參考spt23
  104/12/21: 紙本持有不用再判斷912
  105/01/08: add condition for paper receive:  spt21.accept_date >= '1050101'
  ------------------------------------------------*/
  -- 線上 公文 Online Recieve
  SELECT  COUNT(CASE WHEN s21.PROCESS_RESULT is null  AND RECEIVE.RECEIVE_NO is not null THEN 1 ELSE NULL END) AS TODO,
          COUNT(CASE WHEN s21.PROCESS_RESULT is not null and ( (sd02.SIGN_RESULT = '1' and NODE_STATUS < '130' ) or s56.receive_no is null)    THEN 1 ELSE NULL END) AS DONE,
          COUNT(CASE WHEN (sd02.SIGN_RESULT = '1' and NODE_STATUS > '120' ) 
               THEN 1 ELSE NULL END) AS REJECTED
   INTO A_TODO, A_TO_APPROVE ,A_APPROVED
   FROM  RECEIVE  
   JOIN SPT21 s21 ON s21.RECEIVE_NO = RECEIVE.RECEIVE_NO 
   LEFT JOIN SPM56 s56 ON s56.RECEIVE_NO = RECEIVE.RECEIVE_NO AND s56.processor_no =  RECEIVE.PROCESSOR_NO and s56.record_date >= receive.process_date
   LEFT JOIN ap.sptd02 sd02 ON s56.form_file_a = sd02.form_file_a 
   WHERE  RECEIVE.step_code > '0'
    AND RECEIVE.step_code < '8'
    AND s21.process_result != '57001'
    AND RECEIVE.PROCESSOR_NO IN (
    SELECT PROCESSOR_NO   FROM SPM63 
    WHERE DEPT_NO = '70012' AND SUBSTR(PROCESSOR_NO,1,1)='P' AND QUIT_DATE IS NULL
    )
    AND (s56.form_file_a is null or s56.form_file_a = (select max(form_file_a) from spm56 where s56.receive_no = spm56.receive_no and s56.processor_no = spm56.processor_no))
    ;
  
  -- 紙本 公文
  SELECT COUNT(1)
  INTO A_TODO_P  
  FROM SPT21
  LEFT JOIN SPT23 ON SPT21.receive_no = SPT23.receive_no AND SPT21.OBJECT_ID = Spt23.OBJECT_TO
  WHERE SPT23.data_seq = (select max(data_seq) from spt23 s23 where SPT23.receive_no = s23.receive_no) 
    AND PROCESS_RESULT IS NULL
    AND SPT21.object_id IN (
      SELECT PROCESSOR_NO   FROM SPM63 
     WHERE DEPT_NO = '70012' AND SUBSTR(PROCESSOR_NO,1,1)='P' AND QUIT_DATE IS NULL
    )
 --   AND SPT21.trans_no = '912' -- mark by susan 104/12/21
    AND SPT21.process_result != '57001'
    AND SPT21.accept_date >= '1050101'
    ;
      
-- 紙本 待呈核
  SELECT COUNT(1)
  INTO A_TO_APPROVE_P
  FROM SPT21
   JOIN spt23
  ON spt21.receive_no = spt23.receive_no   AND spt21.trans_seq = spt23.data_seq AND SPT21.OBJECT_ID = Spt23.OBJECT_TO
  WHERE  PROCESS_RESULT IS NOT NULL
      --AND not EXISTS (SELECT RECEIVE_NO FROM SPM56 WHERE RECEIVE_NO = SPT21.RECEIVE_NO AND ISSUE_FLAG = '1')
      AND SPT21.object_id IN (
      SELECT PROCESSOR_NO   FROM SPM63 
      WHERE DEPT_NO = '70012' AND SUBSTR(PROCESSOR_NO,1,1)='P' AND QUIT_DATE IS NULL
    )
 --   AND SPT21.trans_no = '912'  -- -- mark by susan 104/12/21
    AND SPT21.process_result != '57001'
    AND SPT21.accept_date >= '1050101'
    ;
  
 -- 紙本 已呈核
 SELECT COUNT(1)
 INTO A_APPROVED_P
  FROM SPT21
  JOIN spm56 on spm56.form_file_a = (select max(spm56.form_file_a) from spm56 s56 where s56.form_file_a = spm56.form_file_a)
               and spm56.receive_no = spt21.receive_no
  WHERE SPT21.PROCESS_RESULT IS NOT NULL
      AND spm56.Issue_Flag = '1'
      AND SPT21.object_id IN (
      SELECT PROCESSOR_NO   FROM SPM63 
      WHERE DEPT_NO = '70012' AND SUBSTR(PROCESSOR_NO,1,1)='P' AND QUIT_DATE IS NULL
    )
    AND SPT21.PROCESS_RESULT != '57001'
    AND SPT21.accept_date >= '1050101'
    ;
  
  -- 紙本已領未簽
  SELECT COUNT(1)
  INTO A_UNSIGN_NEW 
  FROM SPT23
  WHERE SPT23.data_seq = (select max(data_seq) from spt23 s23 where SPT23.receive_no = s23.receive_no) 
  AND  SUBSTR(SPT23.RECEIVE_NO,4,1) = '2'
      AND SPT23.TRANS_NO = '912'
      AND SPT23.ACCEPT_DATE IS NULL
       AND SPT23.OBJECT_TO IN (
      SELECT PROCESSOR_NO   FROM SPM63 
      WHERE DEPT_NO = '70012' AND SUBSTR(PROCESSOR_NO,1,1)='P' AND QUIT_DATE IS NULL
    )
    AND not exists ( select 1 from spt21 where spt21.receive_no = spt23.receive_no and spt21.process_result = '57001')
    ;
    
       -- 當月應辦 
   SELECT nvl(sum(d),0)  INTO A_THISMON_TODO
   FROM
   ( 
    SELECT  nvl(b.base,0) * nvl(mday.days,0) + nvl(a.factor,0) d
    FROM quota a JOIN quota_base b on a.processor_no = b.processor_no AND a.yyyy = b.yyyy
    LEFT JOIN (SELECT  substr(date_bc,1,6) yyyymm, count(1) days   
    FROM spmff WHERE  date_flag = 1 group by substr(date_bc,1,6) ) mday
    on mday.yyyymm = b.yyyy || a.mm
    WHERE trim(a.processor_no)  IN (
      SELECT PROCESSOR_NO   FROM SPM63 
      WHERE DEPT_NO = '70012' AND SUBSTR(PROCESSOR_NO,1,1)='P' AND QUIT_DATE IS NULL
    )
    AND a.yyyy = to_char(sysdate,'yyyy') AND a.mm = to_char(sysdate,'MM')
    )
    ;
    -- 將逾期
    SELECT  
         SUM( case when to_char(sysdate,'yyyyMMdd') between   cdate.date_bc and to_number(substr( spt21.control_date,1,3))+1911 || substr( spt21.control_date,4,4)
                   and step_code != '4' then 1 else 0 end) 
        INTO A_TO_EXCEED 
    FROM receive join spt21 On receive.receive_no = spt21.receive_no
    LEFT JOIN 
    (
      SELECT row_number() over(partition by spt21.receive_no order by date_chinese desc) d  ,spt21.control_date,  spmff.date_bc ,spt21.receive_no
      FROM spt21 join ap.spmff on spmff.date_bc < to_number(substr( spt21.control_date,1,3))+1911 || substr( spt21.control_date,4,4)
      JOIN receive on spt21.receive_no = receive.receive_no
      WHERE  spmff.date_flag = 1
      AND receive.processor_no between 'P2121' and 'P2124'
      AND process_result != '57001'
     ) cdate on cdate.receive_no = receive.receive_no 
    WHERE  receive.step_code >= '2'
    AND    receive.step_code < '8'
    AND spt21.process_result != '57001'
    AND receive.processor_no   IN (
      SELECT PROCESSOR_NO   FROM SPM63 
      WHERE DEPT_NO = '70012' AND SUBSTR(PROCESSOR_NO,1,1)='P' AND QUIT_DATE IS NULL
    )
    AND cdate.d = 2
    AND substr(to_char(to_number(receive.process_date) + 19110000),1,6)  = to_char(sysdate,'yyyyMM')
    ;
    
   select nvl(sum(1),0) into A_THISMON_DONE  -- 當月辦結
  from receive
  where step_code = '8'
  and not exists (select 1 from spt21 where spt21.process_result = '57001' and spt21.receive_no = receive.receive_no)
  and processor_no  IN (
      SELECT PROCESSOR_NO   FROM SPM63 
      WHERE DEPT_NO = '70012' AND SUBSTR(PROCESSOR_NO,1,1)='P' AND QUIT_DATE IS NULL
    )
   and substr(to_char(to_number(sign_date) + 19110000),1,6)  = to_char(sysdate,'yyyyMM')
   ;
  
end dashboard_approver;

/
