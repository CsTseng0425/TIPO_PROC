--------------------------------------------------------
--  DDL for Procedure LIST_CHEK_RECEIVE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."LIST_CHEK_RECEIVE" (
  p_out_list out sys_refcursor) 
is
begin
  /*
  Desc: statistic the receive is overtime or waiting form signed ...
        公文稽催(同仁+外包) 統計 
  ModifyDate: 104/08/02
  104/09/10 : exclude the receives which process_result = 57001
  105/01/26 : 公文逾期(receive overtime calculate), 工作天改讀取 spmff
  */
  OPEN p_out_list FOR
    SELECT   spm63.processor_no,
          spm63.name_c,
          nvl(s.S_TO_EXCEED,0) S_TO_EXCEED ,
          nvl(s.S_FOR_APPROVE,0) S_FOR_APPROVE,
          nvl(s.S_EXCEEDED,0) S_EXCEEDED
from spm63
left join
(
SELECT   receive.processor_no ,
         SUM( case when to_char(sysdate,'yyyyMMdd') between   cdate.date_bc and to_number(substr( spt21.control_date,1,3))+1911 || substr( spt21.control_date,4,4)
              and step_code != '4' then 1 else 0 end) S_TO_EXCEED ,
         SUM( case when to_char(sysdate,'yyyyMMdd') between   cdate.date_bc and to_number(substr( spt21.control_date,1,3))+1911 || substr( spt21.control_date,4,4)
              and step_code = '4' then 1 else 0 end) S_FOR_APPROVE ,
         SUM( case when to_char(sysdate,'yyyyMMdd') > to_number(substr( spt21.control_date,1,3))+1911 || substr( spt21.control_date,4,4)
              then 1 else 0 end)       S_EXCEEDED 
    FROM  receive 
    join spt21 On receive.receive_no = spt21.receive_no 
    LEFT JOIN SPM56 s56 ON s56.receive_no = spt21.receive_no and s56.processor_no = spt21.processor_no and s56.issue_flag = '1'
    LEFT JOIN 
    (
      SELECT row_number() over(partition by spt21.receive_no order by date_chinese desc) d  ,spt21.control_date,  spmff.date_bc ,spt21.receive_no
      FROM spt21 join ap.spmff on spmff.date_bc < to_number(substr( spt21.control_date,1,3))+1911 || substr( spt21.control_date,4,4)
      JOIN receive on spt21.receive_no = receive.receive_no
      WHERE  spmff.date_flag = 1
      AND (spt21.process_result != '57001' or spt21.process_result is null)
      AND receive.processor_no  IN (
          SELECT PROCESSOR_NO 
          FROM SPM63 
          WHERE DEPT_NO ='70012' AND QUIT_DATE IS NULL )
     ) cdate on cdate.receive_no = receive.receive_no 
    WHERE receive.step_code >= '2'
    AND  receive.step_code < '8'
    AND (spt21.process_result != '57001' or spt21.process_result is null)
    AND cdate.d = 2
  --  AND substr(to_char(to_number(receive.process_date) + 19110000),1,6)  = to_char(sysdate,'yyyyMM')
    group by receive.processor_no 
) s on spm63.processor_no = s.processor_no
where SPM63.DEPT_NO ='70012' 
    AND SPM63.QUIT_DATE IS NULL 
    ORDER BY spm63.PROCESSOR_NO
  ;
  
  
end LIST_CHEK_RECEIVE;

/
