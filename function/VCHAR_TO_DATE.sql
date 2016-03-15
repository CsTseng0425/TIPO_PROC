--------------------------------------------------------
--  DDL for Function VCHAR_TO_DATE
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."VCHAR_TO_DATE" (p_date in varchar2)
return date
is
  v_data varchar2(8);
  v_tmp_date date:=null;
begin
  if p_date is not null then
    v_data := trim(p_date);
    if length(v_data) = 8 then
        v_tmp_date := to_date(v_data, 'yyyymmdd');
        return v_tmp_date;
    end if;
    
    if length(v_data) = 7 then
        v_tmp_date := to_date(v_data+19110000, 'yyyymmdd');
        return v_tmp_date;
    end if;
  end if;

  return null;
exception
  when others then
    return null;
end VCHAR_TO_DATE;

/
