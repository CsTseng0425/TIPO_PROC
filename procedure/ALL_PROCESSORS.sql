--------------------------------------------------------
--  DDL for Procedure ALL_PROCESSORS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."ALL_PROCESSORS" (p_out_list out sys_refcursor) is
  -- 二科承辦人員資料
begin
  open p_out_list for
    SELECT PROCESSOR_NO, NAME_C
      FROM SPM63
     WHERE DEPT_NO = '70012'
       AND QUIT_DATE IS NULL
     ORDER BY PROCESSOR_NO;

end all_processors;

/
