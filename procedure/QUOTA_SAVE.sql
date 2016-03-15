--------------------------------------------------------
--  DDL for Procedure QUOTA_SAVE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."QUOTA_SAVE" (p_in_value        in varchar2,
                                       p_in_processor_no in char,
                                       p_in_year         in varchar2,
                                       p_in_month        in varchar2) is

begin

  --儲存基數 
  if p_in_month = '00' then
    UPDATE QUOTA_BASE
       SET BASE = p_in_value
     WHERE PROCESSOR_NO = p_in_processor_no
       AND YYYY = p_in_year;
  else
    --儲存應辦案件數
    UPDATE QUOTA
       SET FACTOR = p_in_value
     WHERE PROCESSOR_NO = p_in_processor_no
       AND YYYY = p_in_year
       AND MM = p_in_month;
  end if;

end quota_save;

/
