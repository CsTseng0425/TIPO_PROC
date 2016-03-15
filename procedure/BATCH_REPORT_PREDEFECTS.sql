--------------------------------------------------------
--  DDL for Procedure BATCH_REPORT_PREDEFECTS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_REPORT_PREDEFECTS" (p_in_batch_no  in varchar2,
                                                    p_in_batch_seq in varchar2,
                                                    p_out_list     out sys_refcursor) is
  -- 上次瑕疵文號
begin

  open p_out_list for
    SELECT RECEIVE_NO
      FROM BATCH_DETAIL
     WHERE BATCH_NO = p_in_batch_no
       AND BATCH_SEQ = p_in_batch_seq - 1
       AND IS_DEFECT = '1';

end batch_report_predefects;

/
