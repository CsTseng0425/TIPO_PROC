--------------------------------------------------------
--  DDL for Function VALID_TW_DATE2
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."VALID_TW_DATE2" (p_date in varchar2) 
return number
is
  v_data varchar2(7);
  v_tmp_date date;
  v_tmp_num number;
begin
  v_data := trim(p_date);
  v_tmp_num := to_number(substr(v_data, 1, 3));
  if length(v_data) = 7 then
    v_tmp_date := to_date(to_char(v_tmp_num + 1911) || substr(v_data, 4), 'yyyymmdd');
    return 0;
  end if;
  return 1;
exception
  when others then
    return 1;
end valid_tw_date2;

/
