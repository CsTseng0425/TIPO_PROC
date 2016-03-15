--------------------------------------------------------
--  DDL for Procedure ERROR_REPORT_LIST_APPROVER
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."ERROR_REPORT_LIST_APPROVER" (p_in_last  in varchar2,
                                                       p_out_list out sys_refcursor) is
  --錯誤通報清單
begin
  -- 查驗人員
  open p_out_list for
    SELECT RAWTOHEX(A.ID) AS ID,
           A.RECEIVE_NO,
           A.PROCESSOR_NO,
           A.STATUS,
           A.APPL_NO,
           A.MESSAGE,
           B.NAME_C,
           EXTRACT(YEAR FROM A.REPORT_DATE) - 1911 ||
           TO_CHAR(A.REPORT_DATE, 'MMDD HH24:MI') AS REPORT_DATE,
           EXTRACT(YEAR FROM A.STATUS_DATE) - 1911 ||
           TO_CHAR(A.STATUS_DATE, 'MMDD HH24:MI') AS STATUS_DATE
      FROM ERROR_REPORTING A, SPM63 B
     WHERE A.PROCESSOR_NO = B.PROCESSOR_NO
       AND SUBSTR(A.PROCESSOR_NO, 1, 1) = 'P'
       AND A.STATUS_DATE > SYSDATE - p_in_last
     ORDER BY A.REPORT_DATE DESC;

end error_report_list_approver;

/
