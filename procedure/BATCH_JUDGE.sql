--------------------------------------------------------
--  DDL for Procedure BATCH_JUDGE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_JUDGE" (p_in_processor_no in char,
                                        p_in_batch_no     in varchar2,
                                        p_in_batch_seq    in varchar2) is
  -- §Pµo
begin
/*
  Desc : §Pµo, Approver approve batch form 
--  Q: if the status will be changed on the moment?

  UPDATE BATCH
     SET STEP_CODE  = CASE PROCESS_RESULT
                        WHEN '1' THEN
                         '3'
                        ELSE
                         '2'
                      END,
         CHECK_DATE = TO_CHAR(TO_NUMBER(TO_CHAR(SYSDATE, 'YYYYMMDD')) -
                              19110000),
         APPROVER   = p_in_processor_no
   WHERE BATCH_NO = p_in_batch_no
     AND BATCH_SEQ = p_in_batch_seq;
*/
  SYS.Dbms_Output.Put_Line('BATCH_JUDGE');
end batch_judge;

/
