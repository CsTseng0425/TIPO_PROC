--------------------------------------------------------
--  DDL for Procedure SKILL_UPDATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SKILL_UPDATE" (p_in_processor_no in varchar2,
                                         p_in_item         in varchar2,
                                         p_in_value        in varchar2) is
  --儲存輪辦清單
begin
  execute immediate 'UPDATE SKILL SET ' || p_in_item ||
                    ' = :1 WHERE PROCESSOR_NO=:2'
    using p_in_value, p_in_processor_no;

end SKILL_UPDATE;

/
