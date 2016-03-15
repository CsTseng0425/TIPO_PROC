--------------------------------------------------------
--  DDL for Procedure BATCH_SEND
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_SEND" (p_in_batch_no  in varchar2,
                                       p_in_batch_seq in number,
                                       p_out_msg      out varchar2) IS
 l_message varchar2(2000);                                       

BEGIN
/*
Desc: send for approved by outsoursing ¾ã§å°e§å
ModifyDate : 104/07/14
ModifyItem:
104/05/26:IS_DEFECT is written to next sequence 
104/07/14: check if exists receives haven't create form ,then show message 
*/

--    select batch_FormList(p_in_batch_no,p_in_batch_seq) into l_message
--  from dual;
  
  if length(l_message)>0 then
     p_out_msg := l_message;
     SYS.Dbms_Output.Put_Line('l_message=' || l_message);
  else
  
  update BATCH
     set STEP_CODE    = '1'
   where BATCH_NO = p_in_batch_no
     and BATCH_SEQ = p_in_batch_seq;

  insert into batch
    (BATCH_SEQ,
     BATCH_NO,
     OUTSOURCING,
     APPROVER,
     STEP_CODE,
     PROCESS_DATE,
     CHECK_DATE,
     PROCESS_RESULT)
    select BATCH_SEQ + 1,
           BATCH_NO,
           OUTSOURCING,
           APPROVER,
           '1',
           TO_CHAR(TO_NUMBER(TO_CHAR(SYSDATE, 'YYYYMMDD')) - 19110000),
           null,
           0
      from batch
     where batch_no = p_in_batch_no
       and batch_seq = p_in_batch_seq;

  insert into batch_detail
    (BATCH_SEQ, BATCH_NO, RECEIVE_NO, APPL_NO, IS_CHECK, IS_DEFECT, REASON,IS_REJECTED)
    select BATCH_SEQ + 1,
           BATCH_NO,
           RECEIVE_NO,
           APPL_NO,
           case
             when IS_CHECK >= '1' then
              '2'
             else
              '0'
           end as IS_CHECK,
           '0',
           REASON ,
           IS_REJECTED
      from batch_detail
     where batch_no = p_in_batch_no
       and batch_seq = p_in_batch_seq;
         p_out_msg := '°e®Ö¦¨¥\';
        SYS.Dbms_Output.Put_Line('p_out_msg=' || p_out_msg);
  end if;
  


END BATCH_SEND;

/
