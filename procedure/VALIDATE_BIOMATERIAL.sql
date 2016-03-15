--------------------------------------------------------
--  DDL for Procedure VALIDATE_BIOMATERIAL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."VALIDATE_BIOMATERIAL" (
  p_in_process_result in char,
  p_in_biomaterial_array in biomaterial_tab,
  p_io_error_message_array in out nocopy pair_tab
)
is
  v_tmp_biomaterial biomaterial_obj;
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
  if p_in_biomaterial_array is null
      or p_in_biomaterial_array.count = 0 then
    return;
  end if;
  for l_idx in p_in_biomaterial_array.first .. p_in_biomaterial_array.last
  loop
    v_tmp_biomaterial := p_in_biomaterial_array(l_idx);
    if v_tmp_biomaterial.appl_no is null or v_tmp_biomaterial.data_seq is null then
      continue;
    end if;
    if trim(v_tmp_biomaterial.microbe_date) is null
      and trim(v_tmp_biomaterial.microbe_org_id) is null
      and trim(v_tmp_biomaterial.microbe_org_name) is null 
      and trim(v_tmp_biomaterial.microbe_appl_no) is null 
      and trim(v_tmp_biomaterial.national_id) is null then
      add_error_message('�ͪ����Ƹ�T(' || l_idx || ') ����J�����ơC');
      continue;
    end if;
    if v_tmp_biomaterial.microbe_date is not null 
      and not valid_date(v_tmp_biomaterial.microbe_date) then
      add_error_message('�ͪ����Ƹ�T(' || l_idx || ') �ͪ����ƱH�s��D���T�褸����榡�C');
    end if;
    if trim(v_tmp_biomaterial.microbe_date) is null and v_is_complete then
      add_error_message('�ͪ����Ƹ�T(' || l_idx || ') �ͪ����ƱH�s���������C');
    end if;
    if trim(v_tmp_biomaterial.microbe_org_id) is null 
       and trim(v_tmp_biomaterial.microbe_org_name) is null 
       and v_is_complete then
      add_error_message('�ͪ����Ƹ�T(' || l_idx || ') �H�s����������C');
    end if;
    if trim(v_tmp_biomaterial.microbe_appl_no) is null and v_is_complete then
      add_error_message('�ͪ����Ƹ�T(' || l_idx || ') �H�s�ӽЮ׸�������C');
    end if;
    if trim(v_tmp_biomaterial.national_id) is null and v_is_complete then
      add_error_message('�ͪ����Ƹ�T(' || l_idx || ') �H�s��a������C');
    end if;
  end loop;
end validate_biomaterial;

/
