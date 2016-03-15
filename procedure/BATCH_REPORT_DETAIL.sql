--------------------------------------------------------
--  DDL for Procedure BATCH_REPORT_DETAIL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_REPORT_DETAIL" (p_in_batch_no  in varchar2,
                                                p_in_batch_seq in varchar2,
                                                p_out_list     out sys_refcursor) is
  --§å¦¸©ú²Ó
begin
  open p_out_list for
    SELECT BATCH_SEQ, BATCH_NO, APPL_NO, IS_CHECK, IS_DEFECT, REASON
      FROM BATCH_DETAIL
     WHERE BATCH_NO = p_in_batch_no
       AND BATCH_SEQ = p_in_batch_seq
       AND IS_CHECK = '1';

end batch_report_detail;

/
