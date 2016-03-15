--------------------------------------------------------
--  DDL for Procedure SAVE_DIRECT_PAGE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SAVE_DIRECT_PAGE" (
  p_in_processor_no in char,
  p_in_draft_flag in number,
  p_in_direct_info_map in pair_tab,
  p_in_priority_right_array in priority_right_tab,
  p_in_biomaterial_array in biomaterial_tab,
  p_in_grace_period_array in grace_period_tab,
  p_out_warn_message_array out varchar2_tab,
  p_out_error_message_array out pair_tab,
  p_out_draft_message_array out pair_tab)
is
  --�`��
  c_yes                     constant char(1) := '1';
  c_no                      constant char(1) := '0';
  --��l���
  g_origin_spt31            spt31%rowtype;
  --�ܼ�
  g_appl_no                 spt31.appl_no%type;
  g_appl_date               spt31.appl_date%type;
  g_twis_flag               spt31.twis_flag%type;
  g_foreign_language        spt31.foreign_language%type;
  g_process_result          spt21.process_result%type;
  g_annex_desc              appl50.annex_desc%type;
  g_annex_code              appl.pre_exam_list%type;
  g_appl_exam_flag          varchar2(1);
  g_appl_priority_exam_flag varchar2(1);
  g_spt31f_receive_no       spt31f.receive_no%type;
  g_spec_total_count        number;
  g_tw_sysdate              char(7);
  g_step_code               spt31a.step_code%type;
  /*
  Desc: �w���f�d
  Last ModifyDate : 105/01/13
  ��z���G  '49213','49215','49217' �� 193 �s�Z���~�C���u�W�f�d�ץ�
  105/01/13: ���ƿ�z���G,�W�['49269','49271' 
  105/01/19: ���������: �o���� and ��z���G��('49213','49217','49215','49269','49271') 
  105/02/25: �������奻�� ���A�Ѯץ�f�d�������w,�G��ƨӷ������Ѹ�Ʈwspt21c �P�_

  */
  procedure add_warn_message(p_message in varchar2)
  --================--
  --�s�Wĵ�i�^�ǰT��--
  --================--
  is
  begin
    p_out_warn_message_array.extend;
    p_out_warn_message_array(p_out_warn_message_array.last) := p_message;
  end add_warn_message;
  
  procedure add_error_message(p_key in varchar2, p_message in varchar2)
  --================--
  --�s�W���~�^�ǰT��--
  --================--
  is
  begin
    p_out_error_message_array.extend;
    p_out_error_message_array(p_out_error_message_array.last) := pair_obj(p_key, p_message);
  end add_error_message;
  
  procedure add_error_message(p_message in varchar2)
  --================--
  --�s�W���~�^�ǰT��--
  --================--
  is
  begin
    add_error_message('', p_message);
  end add_error_message;
  
  procedure init
  --==============--
  --��l�Ƭ����B�z--
  --==============--
  is
    type key_value_map is table of varchar2(1000) index by varchar2(100);
    v_map key_value_map;
    v_pair pair_obj;
  begin
    p_out_warn_message_array := varchar2_tab();
    p_out_error_message_array := pair_tab();
    for l_idx in p_in_direct_info_map.first .. p_in_direct_info_map.last
    loop
      v_pair := p_in_direct_info_map(l_idx);
      v_map(v_pair.key) := v_pair.value;
    end loop;
    g_appl_no := v_map('APPL_NO');
    g_appl_date := v_map('APPL_DATE');
    g_twis_flag := nvl(v_map('TWIS_FLAG'), c_no);
    g_foreign_language := v_map('FOREIGN_LANGUAGE');
    g_process_result := v_map('PROCESS_RESULT');
    g_annex_desc := v_map('ANNEX_DESC');
    g_annex_code := v_map('ANNEX_CODE');
    g_appl_exam_flag := nvl(v_map('APPL_EXAM_FLAG'), c_no);
    g_appl_priority_exam_flag := nvl(v_map('APPL_PRIORITY_EXAM_FLAG'), c_no);
    g_spt31f_receive_no := v_map('SPT31F_RECEIVE_NO');
    g_spec_total_count := v_map('SPEC_TOTAL_COUNT');
    g_tw_sysdate := to_char(sysdate, 'yyyymmdd') - 19110000;
    select *
      into g_origin_spt31
      from spt31
     where appl_no = g_appl_no;
    select step_code
      into g_step_code
      from spt31a
     where appl_no = g_appl_no;
  end init;
  
  procedure check_direct_info
  --====================--
  --²���ץ�򥻸���ˮ�--
  --====================--
  is
  begin
    if g_appl_date is null then
      add_error_message('APPL_DATE', '�ӽФ������J');
    elsif not valid_tw_date(g_appl_date) then
      add_error_message('APPL_DATE', '�ӽФ���D���T�������榡');
    end if;
    if trim(g_process_result) is not null then
      declare
        v_tmp_num number(4);
      begin
        select count(1)
          into v_tmp_num
          from spm75
         where type_no = g_process_result
           and type_no > '40000';
        if v_tmp_num = 0 then
          add_error_message('PROCESS_RESULT', '��z���G�榡���~');
        else
          p_out_error_message_array := 
              p_out_error_message_array multiset union wf_check(
                          g_appl_no,
                          g_appl_date,
                          g_process_result,
                          g_appl_exam_flag,
                          g_appl_priority_exam_flag,
                          null,
                          null,
                          'N');
          if g_process_result in ('49213', '43191', '43199', '43001', '49217', '43015', '49215', '43009','49269','49271' ) 
              and substr(g_appl_no, 4, 1) = '2' then
            if g_origin_spt31.first_day >= '0991011' then
              declare
                v_status spt21c.status%type;
              begin
                 v_tmp_num := 0;
                 select count(1)  into v_tmp_num  from spt21c     where appl_no = g_appl_no;
               
               if v_tmp_num = 0 then
                 add_error_message('PROCESS_RESULT', '�����w�������廡����(�ϻ�),���i�i������Ƴq���@�~!');
               end if;
                  /* Mark by Susan 
                  104/12/10 �]���w���奻��H�C��妸�M090�i��P�B,spt21c ���O��H�Ψӵ��O�O�_�w�M090�P�B
                  �G���A��ץ�f�d���ˬd*/
                      -------------------------------------*/
                      /*
                if trim(v_status) != '9' then
                  add_error_message('PROCESS_RESULT', '�������廡����(�ϻ�)�|�������H�u����,���i�i������Ƴq���@�~!');
                end if;
                */
              exception
                when no_data_found then
                  add_error_message('PROCESS_RESULT', '�������廡����(�ϻ�)�|�������T�{,���i�i������Ƴq���@�~!');
              end;
            end if;
          end if;
        end if;
      end;
    end if;
    if g_process_result in ('49259', '49245', '49255', '49249') or g_step_code < 29 then
      if g_spt31f_receive_no is null then
        add_error_message('�����O���帹�����');
      end if;
    end if;
  end check_direct_info;
  
  procedure save_direct_info
  --================--
  --�x�s�ץ�򥻸��--
  --================--
  is
  begin
    update spt31  
       set appl_date = g_appl_date,
		       patent_status = '3',
			--     sch_processor_no = p_in_processor_no, --> �����^�g  mark by susan 
			--     phy_processor_no = p_in_processor_no, --  > �쥻�N���Φ^�g mark by susan 
           twis_flag = g_twis_flag
     where appl_no = g_appl_no;
     -- update appl.processor_no  add by susan 
     update appl
     set processor_no = p_in_processor_no
      where appl_no = g_appl_no;
    /*if g_process_result in ('43001', '43003', '43007') then
      update spt31
         set f_adt_date = g_tw_sysdate,   
             pre_exam_check = '1' 
       where appl_no = g_appl_no;
    end if;*/
       ---------
    --start  add by susan 2015/12/10
    ---------
    if g_process_result in ( '43001','43003','43009','43011','43007','43015','43023','42003','42007','42015','40109','40111','40113','40115','40117','40119',
 '40123','42101','42103','42107','42109','42111','42113','42115','42117','43025','42031','49207','49209','49211','49245','49247',
 '49257','49249','49243','49265','49267','49213','49215','49217','49269','49271','59001','43051','42129','43061') then
       update spt31
         set f_adt_date = to_char(add_months(sysdate,1),'yyyyMMdd')-19110000,
             pre_exam_check  = '1'
       where appl_no = g_appl_no;
      
    end if;
    ---------
    --end add by susan 2015/12/10
    ---------
    
    save_annex(g_appl_no, g_annex_code, g_annex_desc);
    save_appl_exam(g_appl_no, g_spt31f_receive_no, g_process_result, g_appl_exam_flag, g_appl_priority_exam_flag);
    save_material_appl_date(g_appl_no, g_spt31f_receive_no, g_appl_exam_flag, g_appl_priority_exam_flag);
  end save_direct_info;
  
  procedure draft_check
  --========--
  --�s�Z�ˬd--
  --========--
  is
  begin
    p_out_draft_message_array := pair_tab();
    declare
      v_count number;
    begin
     if  g_process_result = '49213'  and substr(g_appl_no,4,1)= '1' then -- add by susan 104/07/16
      select count(1)
        into v_count
        from spm56 
       where form_id = 'P03-1'
         and issue_flag = '2'
         and appl_no = g_appl_no;
      if v_count > 0   then
        p_out_draft_message_array.extend;
        p_out_draft_message_array(p_out_draft_message_array.last) :=
          pair_obj('', '�w�s�LP03-1�Z�B�w�o��!');
      end if;
     end if; 
    end;
    if substr(g_appl_no, 4, 1) = '1' and g_process_result in ('49213','49217','49215','49269','49271') then
      declare
        v_tmp_count number;
      begin
        select count(1)
          into v_tmp_count
          from appl
         where appl_no = g_appl_no
           and doc_complete = '1';
        if v_tmp_count = 0 then
          p_out_draft_message_array.extend;
          p_out_draft_message_array(p_out_draft_message_array.last) := pair_obj('DOC_COMPLETE', '�|������A���i��z����');
        end if;
      end;
    end if;
    if p_in_priority_right_array is not null
         and p_in_priority_right_array.count > 0 then
      declare
        v_tmp_priority_right priority_right_obj;
      begin
        for l_idx in p_in_priority_right_array.first .. p_in_priority_right_array.last
        loop
          v_tmp_priority_right := p_in_priority_right_array(l_idx);
          if v_tmp_priority_right.appl_no is null or v_tmp_priority_right.data_seq is null then
            continue;
          end if;
          if v_tmp_priority_right.priority_flag = 1 
               and g_process_result is not null then -- ���έ��w���Ƥ���z���G modify by Susan
            if trim(v_tmp_priority_right.priority_nation_id) is null then
              p_out_draft_message_array.extend;
              p_out_draft_message_array(p_out_draft_message_array.last) := pair_obj('PRIORITY_RIGHT_PRIORITY_NATION_ID_' || l_idx, '�ꤺ�~�u���v���(' || l_idx || ') ���y���o���ŭȡA�гB�������z!');
            end if;
            if trim(v_tmp_priority_right.priority_date) is null then
              p_out_draft_message_array.extend;
              p_out_draft_message_array(p_out_draft_message_array.last) := pair_obj('PRIORITY_RIGHT_PRIORITY_DATE_' || l_idx, '�ꤺ�~�u���v���(' || l_idx || ') �u���v������o���ŭȡA�гB�������z!');
            end if;
          end if;
        end loop;
      end;
    end if;
  end draft_check;
  
begin
  
  init;
  
  check_direct_info;
  validate_priority_right(
    g_process_result,
    g_appl_date,
    p_in_priority_right_array,
    p_out_error_message_array);
  if substr(g_appl_no, 4, 1) not in ('2', '3') then
    validate_biomaterial(
      g_process_result,
      p_in_biomaterial_array,
      p_out_error_message_array);
  end if;
  validate_grace_period(
    g_process_result,
    p_in_grace_period_array,
    p_out_error_message_array);
  
  --�ˮ֨S���~�~�i�H�x�s
  if p_out_error_message_array.count = 0 then
      
    save_direct_info;
    save_priority_right(
      g_appl_no,
      g_process_result,
      p_in_priority_right_array,
      p_out_warn_message_array);
    if substr(g_appl_no, 4, 1) not in ('2', '3') then
      save_biomaterial(
        g_appl_no,
        p_in_biomaterial_array);
    end if;
    save_grace_period(
      g_appl_no,
      p_in_grace_period_array);
    
    save_spt31b_pre_date(g_appl_no, p_out_error_message_array);
    
    if p_in_draft_flag = 1 then
      draft_check;
      update appl set online_flg = '2' where appl_no =g_appl_no ;
    end if;
  end if;
  
end save_direct_page;

/
