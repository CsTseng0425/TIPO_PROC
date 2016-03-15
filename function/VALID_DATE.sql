--------------------------------------------------------
--  DDL for Function VALID_DATE
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."VALID_DATE" (p_date in varchar2)
return boolean
is
  v_data varchar2(8);
  v_tmp_date date;
begin
  v_data := trim(p_date);
  if length(v_data) = 8 then
    v_tmp_date := to_date(v_data, 'yyyymmdd');
    return true;
  end if;
  return false;
exception
  when others then
    return false;
end valid_date;

/
