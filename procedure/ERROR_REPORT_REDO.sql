--------------------------------------------------------
--  DDL for Procedure ERROR_REPORT_REDO
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."ERROR_REPORT_REDO" (p_in_id      in varchar2,
                                              p_in_message in varchar2) is
  --¦A³q³ø
begin
  UPDATE ERROR_REPORTING
     SET STATUS = 0, REPORT_DATE = SYSDATE, MESSAGE = p_in_message
   WHERE ID = p_in_id;
end error_report_redo;

/
