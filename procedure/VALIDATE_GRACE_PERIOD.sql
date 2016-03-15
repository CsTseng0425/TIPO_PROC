--------------------------------------------------------
--  DDL for Procedure VALIDATE_GRACE_PERIOD
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."VALIDATE_GRACE_PERIOD" (
  p_in_process_result in char,
  p_in_grace_period_array in grace_period_tab,
  p_io_error_message_array in out nocopy pair_tab)
is
  v_tmp_grace_period grace_period_obj;
  v_is_complete boolean := p_in_process_result in (
    '49213', '49215', '49217', '49269', '49271', '49207', '49209', '49211', '49221', '49223',
    '49225', '49265', '49267', '49269', '49271', '49273', '49275', '43191', '43199', '43001'
  );
  
  procedure add_error_message(p_message in varchar2)
  is
  begin
    p_io_error_message_array.extend;
    p_io_error_message_array(p_io_error_message_array.last) := pair_obj('', p_message);
  end add_error_message;
  
begin
  if p_in_grace_period_array is null
      or p_in_grace_period_array.count = 0 then
    return;
  end if;
  for l_idx in p_in_grace_period_array.first .. p_in_grace_period_array.last
  loop
    v_tmp_grace_period := p_in_grace_period_array(l_idx);
    if v_tmp_grace_period.appl_no is null or v_tmp_grace_period.data_seq is null then
      continue;
    end if;
    if trim(v_tmp_grace_period.novel_flag) is null
      and trim(v_tmp_grace_period.novel_item) is null
      and trim(v_tmp_grace_period.novel_date) is null then
      add_error_message('優惠期資訊(' || l_idx || ') 未輸入任何資料');
      continue;
    end if;
    if trim(v_tmp_grace_period.novel_item) is null and v_is_complete then
      add_error_message('優惠期資訊(' || l_idx || ') 主張款項為必填。');
    end if;
    if v_tmp_grace_period.novel_date is not null 
      and not valid_tw_date(v_tmp_grace_period.novel_date) then
      add_error_message('優惠期資訊(' || l_idx || ') 優惠日期非正確民國日期格式。');
    end if;
    if trim(v_tmp_grace_period.novel_date) is null and v_is_complete then
      add_error_message('優惠期資訊(' || l_idx || ') 優惠日期為必填。');
    end if;
  end loop;
end validate_grace_period;

/
