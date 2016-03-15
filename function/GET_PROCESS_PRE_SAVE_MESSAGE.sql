--------------------------------------------------------
--  DDL for Function GET_PROCESS_PRE_SAVE_MESSAGE
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."GET_PROCESS_PRE_SAVE_MESSAGE" (
  p_appl_no in char,
  p_process_result in char
)
return varchar2_tab 
is
  v_result varchar2_tab := varchar2_tab();
  v_tw_sysdate char(7)  := to_char(sysdate, 'yyyymmdd') - 19110000;
  
  procedure add_message(p_message in varchar2)
  is
  begin
    v_result.extend;
    v_result(v_result.last) := p_message;
  end add_message;
  
begin
 
  if p_process_result in (
      '49213', '43191', '43199', '43001', '49243', '43003', '43007', '43011', '43009', '43015',
      '49215', '49217', '49201', '49203', '49205', '41001', '41003', '41005', '41007', '41011',
      '41025', '41027', '41505', '41515') then
    declare
      v_tmp_num number;
    begin
      select count(1)
        into v_tmp_num
        from spm11
       where id_type = '1'
         and appl_no = p_appl_no
         and (trim(name_c) like '%��'
              or trim(name_c) like '%��'
              or trim(name_c) like '%��'
              or trim(name_c) like '%��'
              or trim(name_c) like '%�u�t'
              or trim(name_c) like '%�����q'
              or trim(name_c) like '%�ưȩ�'
              or trim(name_c) like '%����');
      if v_tmp_num > 0 then
        add_message('�нT�{�ӽФH�O�_�A��');
      end if;
    end;
  end if;
  if p_process_result in ('41505', '43007')
    and substr(p_appl_no, 10, 1) = 'N' then
    declare
      v_charge_expir_date spmf1.charge_expir_date%type;
    begin
      select charge_expir_date
        into v_charge_expir_date
        from spmf1
       where appl_no like substr(p_appl_no, 1, 9) || '%'
         and revoke_flag != '1';
      if v_tw_sysdate > v_charge_expir_date then
        add_message('�~�O���Ĵ����O��');
      end if;
    exception
      when no_data_found then add_message('�L�~�O��T');
    end;
    end if;
  return v_result;
end get_process_pre_save_message;

/
