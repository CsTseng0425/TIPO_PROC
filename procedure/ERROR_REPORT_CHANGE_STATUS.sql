--------------------------------------------------------
--  DDL for Procedure ERROR_REPORT_CHANGE_STATUS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."ERROR_REPORT_CHANGE_STATUS" (p_in_id     in varchar2,
                                                       p_in_status in varchar2) is
  --§ó·sª¬ºA
begin
  UPDATE ERROR_REPORTING
     SET STATUS = p_in_status, STATUS_DATE = SYSDATE
   WHERE ID = p_in_id;
end error_report_change_status;

/
