--------------------------------------------------------
--  DDL for Procedure USER_TO_190
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."USER_TO_190" (p_in_emp in char,
                                        p_in_190 out varchar2) is
  -- 轉換e網通帳號成190帳號

begin

  SELECT PROCESSOR_NO
    into p_in_190
    FROM SPM63A
   WHERE EMP_CODE = p_in_emp
     AND SORT_ID = '1';

end user_to_190;

/
