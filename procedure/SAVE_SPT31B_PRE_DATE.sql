--------------------------------------------------------
--  DDL for Procedure SAVE_SPT31B_PRE_DATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SAVE_SPT31B_PRE_DATE" (
  p_in_appl_no in char,
  p_io_error_message_array in out nocopy pair_tab)
is
  not_a_valid_date exception;
  pragma exception_init(not_a_valid_date, -20001);

  v_priority_date varchar2(8);
  v_appl_date     spt31.appl_date%type;
  v_pre_date      spt31b.pre_date%type;
  
  function to__date(
    p_char_literal in varchar2,
    p_date_format  in varchar2)
  return date 
  is
  begin
    return to_date(p_char_literal, p_date_format);
  exception
    when others then
      raise_application_error(-20001, 'Not a valid date');
  end to__date;
  
  function tw_to_ad(p_tw in varchar2)
  return varchar2
  is
  begin
    return substr(p_tw, 1, 3) + 1911 || substr(p_tw, 4);
  end tw_to_ad;
  
  function ad_to_tw(p_ad in varchar2)
  return varchar2
  is
  begin
    return lpad(p_ad - '19110000', 7, '0');
  end ad_to_tw;
begin
  select appl_date
    into v_appl_date
    from spt31
   where appl_no = p_in_appl_no;
  select nvl(min(priority_date),'29991231')
    into v_priority_date
    from (
      select priority_date 
        from spt32 
       where appl_no = p_in_appl_no 
         and nvl(trim(priority_flag), '1') = '1' 
       order by priority_date
    )
 --  where rownum <= 1;
 ;
  if v_priority_date is not null then
    v_pre_date := ad_to_tw(to_char(
        least(
          to__date(v_priority_date, 'yyyymmdd') + 1, 
          to_date(tw_to_ad(v_appl_date), 'yyyymmdd') + 1
        )
      , 'yyyymmdd'));
  else
    v_pre_date := ad_to_tw(to_char(
        to_date(tw_to_ad(v_appl_date), 'yyyymmdd') + 1
      , 'yyyymmdd'));
  end if;
--  SYS.Dbms_Output.Put_Line('v_pre_date=' || v_pre_date);
  update spt31b 
     set pre_date = v_pre_date
   where appl_no = p_in_appl_no;
exception
  when not_a_valid_date then
    p_io_error_message_array.extend;
    p_io_error_message_array(p_io_error_message_array.last) := pair_obj('', '更新公開準備起始日發生錯誤:' || v_priority_date || ' 不是正確日期');
    raise_application_error(-20010, v_priority_date || 'Not a valid date');
  when no_data_found then null;--不處理
end save_spt31b_pre_date;

/
