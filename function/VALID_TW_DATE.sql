--------------------------------------------------------
--  DDL for Function VALID_TW_DATE
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."VALID_TW_DATE" (p_date in varchar2)
return boolean
is
  v_data varchar2(7);
  v_tmp_date date;
  v_tmp_num number;
begin
  v_data := trim(p_date);
  v_tmp_num := to_number(substr(v_data, 1, 3));
  if length(v_data) = 7 then
    v_tmp_date := to_date(v_data + 19110000, 'yyyymmdd');
    return true;
  end if;
  return false;
exception
  when others then
    return false;
end valid_tw_date;

/
