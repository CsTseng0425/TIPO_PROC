--------------------------------------------------------
--  DDL for Procedure VALIDATE_PRIORITY_RIGHT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."VALIDATE_PRIORITY_RIGHT" (
  p_in_process_result in char,
  p_in_appl_date in char,
  p_in_priority_right_array in priority_right_tab,
  p_io_error_message_array in out nocopy pair_tab
)
is
  v_tmp_priority_right priority_right_obj;
  v_tmp_num number(4);
/*
105/01/13: ���ƿ�z���G,�W�['49269','49271' 
105/01/29: �ˮ�: �ꤺ�~�u���v���(' || l_idx || ') ��z���ơG�Ӯפ��O�u���v�洫��a,�w�e�u���v���O���i����
           ��P�_�����~elec_trac => priority_doc_flag
*/
  procedure add_error_message(p_key in varchar2, p_message in varchar2)
  is
  begin
    p_io_error_message_array.extend;
    p_io_error_message_array(p_io_error_message_array.last) := pair_obj(p_key, p_message);
  end add_error_message;

  procedure add_error_message(p_message in varchar2)
  is
  begin
    add_error_message('', p_message);
  end add_error_message;

begin
  if p_in_priority_right_array is null
    or p_in_priority_right_array.count = 0 then
    return;
  end if;
  for l_idx in p_in_priority_right_array.first .. p_in_priority_right_array.last
  loop
    v_tmp_priority_right := p_in_priority_right_array(l_idx);
    if v_tmp_priority_right.appl_no is null or v_tmp_priority_right.data_seq is null then
      continue;
    end if;
    if trim(v_tmp_priority_right.priority_flag) is null then
      add_error_message('�ꤺ�~�u���v���(' || l_idx || ') �����z���O����J');
    end if;
    if v_tmp_priority_right.priority_date is not null
      and not valid_date(v_tmp_priority_right.priority_date) then
      add_error_message('�ꤺ�~�u���v���(' || l_idx || ') �u���v����D���T�褸����榡');
    end if;
    if trim(v_tmp_priority_right.priority_nation_id) is not null then
      select count(1)
        into v_tmp_num
        from spmf5 a
       where nvl(a.data_deadline, 9991231) > to_char(sysdate, 'YYYYMMDD') - 19110000 
         and a.national_id = v_tmp_priority_right.priority_nation_id;
      if v_tmp_num = 0 then
        add_error_message('�ꤺ�~�u���v���(' || l_idx || ') �D���T���y�A�Э��s��J!');
      end if;
    end if;
    if v_tmp_priority_right.priority_flag = 1 then
      /*
      �����z���O��"���z", ��� / ���y ����, �B��z���G�����Ƥ���z���G��, �i�H�x�s, ���i�s�Z
      if trim(v_tmp_priority_right.priority_nation_id) is null then
        if p_in_process_result in (
            '49213', '43191', '43199', '43001', '49217', '43015', '49215', '43009', '49243') then
          add_error_message('PROCESS_RESULT', '�ꤺ�~�u���v���(' || l_idx || ') ���y���o���ŭȡA�гB�������z!');
        end if;
      end if;
      */
      if trim(v_tmp_priority_right.priority_date) is null then
        /*
        �����z���O��"���z", ��� / ���y ����, �B��z���G�����Ƥ���z���G��, �i�H�x�s, ���i�s�Z
        if p_in_process_result in (
            '49213', '43191', '43199', '43001', '49217', '43015', '49215', '43009', '49243') then
          add_error_message('PROCESS_RESULT', '�ꤺ�~�u���v���(' || l_idx || ') �u���v������o���ŭȡA�гB�������z!');
        end if;
        */
        null;
      else
        if valid_tw_date(p_in_appl_date)
          and v_tmp_priority_right.priority_date >= p_in_appl_date + 19110000
          and p_in_process_result in (
            '49213', '43191', '43199', '43001', '49217', '43015', '49215', '43009', '49243','49269','49271') then
          add_error_message('PROCESS_RESULT', '�ꤺ�~�u���v���(' || l_idx || ') �ߩ�ε���ӽФ�A�нT�{!');
        end if;
      end if;
    end if;
    if v_tmp_priority_right.priority_revive = '1' and nvl(v_tmp_priority_right.priority_flag, 'X') != '1' then
      add_error_message('�ꤺ�~�u���v���(' || l_idx || ') �u���v�_�v�u�����u���v���z�A�Э��s��J!');
    end if;
   
    if trim(v_tmp_priority_right.access_code) is not null
      or trim(v_tmp_priority_right.ip_type) is not null then
      select count(1)
        into v_tmp_num
        from spmz9
       where sys_id ='03'
         and (class_id ='PDX' or class_id = 'ACC')
         and trim(code_id) = trim(v_tmp_priority_right.priority_nation_id);
      if v_tmp_num = 0 then
        add_error_message('�ꤺ�~�u���v���(' || v_tmp_priority_right.data_seq || ') �D�}���u���v�洫��a�A���i��g�s���X�αM�Q����');
      end if;
    end if;
    
    if p_in_process_result in ('49213', '49215', '49217', '49269', '49271', '43191', '43199', '43001', '43009', '43015')
      and v_tmp_priority_right.priority_flag in ('1', '3') then
      select count(1)
        into v_tmp_num
        from spmz9
       where sys_id ='03'
         and class_id ='ACC'
         and trim(code_id) = trim(v_tmp_priority_right.priority_nation_id);
      if v_tmp_num>0 then
        if (nvl(v_tmp_priority_right.priority_doc_flag, 'N') != 'Y')  and
           ( trim(v_tmp_priority_right.access_code) is null or trim(v_tmp_priority_right.ip_type) is null ) then
          add_error_message('PROCESS_RESULT', '�ꤺ�~�u���v���(' || l_idx || ') ��z���ơG�Ӯ׬��u���v����-�饻-���D�i�u���v�B�L�����z�κM�^�����O�A��u�w�e�u���v�ҩ����v�Ρu�M�Q���O�Φs���X�v�����G�̨䤤����ơA�~�e�\�s�Z�Φs��!');
        end if;
      
      end if;
       select count(1)
        into v_tmp_num
        from spmz9
       where sys_id ='03'
         and class_id ='PDX'
         and trim(code_id) = trim(v_tmp_priority_right.priority_nation_id);
      if v_tmp_num>0 then
        if (nvl(v_tmp_priority_right.priority_doc_flag, 'N') != 'Y') and 
           ( nvl(v_tmp_priority_right.elec_trans, '0') != '1' or  trim(v_tmp_priority_right.ip_type) is null ) then
            add_error_message('PROCESS_RESULT', '�ꤺ�~�u���v���(' || l_idx || ') ��z���ơG�Ӯ׬��u���v�洫��-����-���D�i�u���v�B�L�����z�κM�^�����O�A��u�w�e�u���v�ҩ����v�Ρu�q�l�洫���O�αM�Q���O�v�����G�̨䤤����ơA�~�e�\�s�Z�Φs��!');
        end if;
      end if;
      if nvl(v_tmp_priority_right.priority_doc_flag, '0') = '0' then
         select count(1)
        into v_tmp_num
        from spmz9
       where sys_id ='03'
         and (class_id ='PDX' or class_id = 'ACC')
         and trim(code_id) = trim(v_tmp_priority_right.priority_nation_id);
         if v_tmp_num =0 then
              add_error_message('PROCESS_RESULT', '�ꤺ�~�u���v���(' || l_idx || ') ��z���ơG�Ӯפ��O�u���v�洫��a,�w�e�u���v���O���i����!');
         end if;
       end if;
    end if;
    
     
  end loop;
end validate_priority_right;

/
