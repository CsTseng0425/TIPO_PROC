--------------------------------------------------------
--  DDL for Procedure ERROR_REPORT_SAVE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."ERROR_REPORT_SAVE" (p_in_processor_no in char,
                                              p_in_receive_no   in char,
                                              p_in_appl_no      in varchar2,
                                              p_in_message      in varchar2) is
  --³q³ø
begin

  delete error_reporting
   where receive_no = p_in_receive_no
     and processor_no = p_in_processor_no
     and status = 0;

  INSERT INTO ERROR_REPORTING
    (RECEIVE_NO, PROCESSOR_NO, APPL_NO, MESSAGE)
  VALUES
    (p_in_receive_no, p_in_processor_no, p_in_appl_no, p_in_message);

end error_report_save;

/
