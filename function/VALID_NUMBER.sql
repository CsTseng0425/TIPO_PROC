--------------------------------------------------------
--  DDL for Function VALID_NUMBER
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."VALID_NUMBER" (p_str in varchar2)
return boolean
is
  v_tmp_num number;
begin
  v_tmp_num := to_number(p_str);
  return true;
exception
  when others then
    return false;
end valid_number;

/
