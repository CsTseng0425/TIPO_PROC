--------------------------------------------------------
--  DDL for Function ADD_TWDATE_MONTHS
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."ADD_TWDATE_MONTHS" (
  p_twdate in char,
  p_add_month in number
) 
return char 
is
  v_src_twdate char(7) := trim(p_twdate);
  v_twyear     char(3);
  v_month      char(3);
  v_day        char(3);
  v_tmp_ym     char(6);
  v_tmp_date   date;
begin
  if valid_tw_date(v_src_twdate) and p_add_month >= 0 then
    v_twyear := substr(v_src_twdate, 1, 3);
    v_month := substr(v_src_twdate, 4, 2);
    v_day := substr(v_src_twdate, 6, 2);
    v_tmp_ym := to_char(add_months(to_date((v_twyear || v_month) + 191100, 'yyyymm'), p_add_month), 'yyyymm');
    begin
      v_tmp_date := to_date(v_tmp_ym || v_day, 'yyyymmdd');
      return lpad(v_tmp_ym || v_day - '19110000', 7, '0');
    exception
      when others then
        return lpad((to_char(add_months(to_date((v_twyear || v_month) + 191100, 'yyyymm'), p_add_month + 1), 'yyyymm') || '01') - '19110000', 7, '0');
    end;
  end if;
  return '';
end add_twdate_months;

/
