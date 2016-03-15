--------------------------------------------------------
--  DDL for Procedure GET_PROCCESS_PAGE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."GET_PROCCESS_PAGE" (
  p_in_receive_no in spt21.receive_no%type,
  p_in_processor_no in spt21.processor_no%type,
  p_out_proccess_info out proccess_info_obj,
  p_out_priority_right_array out priority_right_tab,
  p_out_biomaterial_array out biomaterial_tab,
  p_out_grace_period_array out grace_period_tab,
  p_out_request_item_array out varchar2_tab,
  p_out_message_array out varchar2_tab,
  p_out_readonly_message out varchar2,
  p_out_success out varchar2)
is
  --�`��
  c_yes         constant char(1) := '1';
  c_no          constant char(1) := '0';
  c_tw_sysdate  constant char(7) := to_char(sysdate, 'yyyymmdd') - 19110000;
  
  --spt21 ������
  v_appl_no                 spt21.appl_no%type;            --�ӽЮ׸�
  v_receive_no              spt21.receive_no%type;         --����帹
  v_type_no                 spt21.type_no%type;            --����ץ�
  v_assign_date             spt21.assign_date%type;        --������
  v_processor_no            spt21.processor_no%type;       --�ӿ�H�N�X
  v_receive_date            spt21.receive_date%type;       --������
  v_object_id               spt21.object_id%type;          --������
  v_process_result          spt21.process_result%type;     --��z���G
  v_pre_exam_date           spt21.pre_exam_date%type;      --�ɥ�����
  v_pre_exam_qty            spt21.pre_exam_qty%type;       --�ɥ����
  v_receive_area            spt21.receive_area%type;       --����ϰ�N�X
  v_online_flg              spt21.online_flg%type;         --�u�W�аO
  v_postmark_date           spt21.postmark_date%type;      --�l�W���
  --spt31 �ץ���
  v_appl_date               spt31.appl_date%type;          --�ӽФ�
  v_re_appl_date            spt31.re_appl_date%type;       --�A�f�ӽФ�
  v_material_appl_date      spt31.material_appl_date%type; --�ӽй���f�d��
  v_sc_flag                 spt31.sc_flag%type;            --��a���K���O
  v_twis_flag               spt31.twis_flag%type;          --�@�ר�е��O
  v_foreign_language        spt31.foreign_language%type;   --�~�奻����
  --spt31b �ץ󤽶}���A�����
  v_pre_date                spt31b.pre_date%type;          --���}�ǳư_�l��
  --receive �����z��
  v_unusual                 receive.unusual%type;          --�{���Ю�

  v_name_c                  spm63.name_c%type;             --�ӿ�H�m�W
  --spt13 �W�O���ڬ���
  v_receipt_amt             number(7);                     --���ڪ��B
  v_receipt_flg             varchar2(2 char);              --���ڵ��O
  --spt82 �M�Q���i���
  v_notice_date             spt82.notice_date%type;        --���i���
  v_notice_date2            spt82.notice_date_2%type;      --���}���
  --spmf1 �M�Q�v���
  v_charge_expir_date       spmf1.charge_expir_date%type;  --�~�O���Ĥ��
  v_revoke_date             spmf1.revoke_date%type;        --�M�P���
  --spm75 �ץѸ��
  v_process_result_name     spm75.type_name%type;          --��z���G����
  -- �޿�P�_
  v_appl_exam_flag          varchar2(1);                   --�ӽй���f�d
  v_appl_priority_exam_flag varchar2(1);                   --�ӽй���f�d�P�u���f�d

  v_show_exam_fee           varchar2(1);                   --�O�_��ܼf�d�O�Ӷ����
  v_exam_fee_page_cnt       spt31.page_cnt%type;           --�ץ󭶼�
  v_exam_fee_scope_items    spt31n.scope_items%type;       --�ӽбM�Q�d�򶵼�
  v_exam_fee_exam_pay       spt31n.exam_pay%type;          --��ú�f�d�O
  v_exam_fee_exam_have_pay  number(6);                     --�wú�f�d�O
  v_exam_fee_tax_amount     spt31n.tax_amount%type;        --��ú�ΰh�ټf�d�O
  v_exam_fee_e_flag         spt31n.e_flag%type;            --�^Ķ
  v_exam_fee_f_flag         spt31n.f_flag%type;            --�q�l

  v_spmfi_coment            ap.spmfi.coment%type;             --�N���󥿳Ƨ�

  v_revise_value            appl.pre_exam_list%type;       --�ɥ��ﶵ��T
  v_annex_desc              appl50.annex_desc%type;        --���󻡩�
  v_online_fee_amt          number(6);            --�u�Wú�O���B
  v_first_receive_no        spt21c.receive_no%type;        --�������奻

  procedure add_message (p_message in varchar2)
  --============--
  --�s�W�^�ǰT��--
  --============--
  is
  begin
    p_out_message_array.extend;
    p_out_message_array(p_out_message_array.last) := p_message;
  end add_message;

  procedure check_readonly
  is
    v_count number;
  begin
    select count(1)
      into v_count
      from spt21 a, spt31 b
     where a.receive_no = v_receive_no
       and a.appl_no = b.appl_no
       and b.sc_flag = '1';
    if v_count != 0 then
      p_out_readonly_message := '�����妳�꨾���K���O�A���i�s��';
      return;
    end if;
    select count(1)
      into v_count
      from spt21
     where online_flg = 'Y'
       and receive_no = v_receive_no;
    if v_count = 0 then
      p_out_readonly_message := '�ȥ����u���˵������z';
      return;
    end if;
    --- add by Susan for exclude the receives which process_result = 57001
     select count(1)
      into v_count
      from spt21
     where process_result = '57001'
       and receive_no = v_receive_no;
    if v_count >0  then
      p_out_readonly_message := '����w�@�o!�����z';
      return;
    end if;
    ----------------------------
    --104/12/09 change the condition ,get assign date from spt23
    ----------------------------
    select count(1)
      into v_count
      from spt21
      left join spt23
        on spt21.receive_no = spt23.receive_no  and spt21.trans_seq = spt23.data_seq
        and spt21.processor_no = spt23.object_to
     where spt21.att_doc_flg = 'Y' 
       and spt23.accept_date is  null     
       and spt21.receive_no = v_receive_no;
    if v_count = 1 then
      p_out_readonly_message := '�������ñ�������z';
      return;
    end if;
    select count(1)
      into v_count
      from spt21
     where processor_no = p_in_processor_no
       and receive_no = v_receive_no;
    if v_count = 0 then
      p_out_readonly_message := '�D�ӿ줧��󤣯��z';
      return;
    end if;
    select count(1)
      into v_count
      from receive
     where processor_no = p_in_processor_no
       and step_code = '8'
       and receive_no = v_receive_no;
    if v_count > 0 then
      p_out_readonly_message := '��w�쵲,����s��';
      return;
    end if;
    select count(1)
      into v_count
      from doc
     where receive_no = v_receive_no;
    if v_count = 0 then
      p_out_readonly_message := '�v�����줣���z';
      return;
    end if;
    select count(1)
      into v_count
      from spt21 a, spt31 b
     where a.receive_no = v_receive_no
       and a.appl_no = b.appl_no
       and a.process_result = '43199'
       and b.first_day < '0920701';
    if v_count > 0 then
      p_out_readonly_message := '��z���G��43199�B��������馭��0920701';
      return;
    end if;
    declare
      v_merge_master receive.merge_master%type;
    begin
      select trim(merge_master)
        into v_merge_master
        from receive
       where receive_no = v_receive_no;
      if v_merge_master is not null then
         p_out_readonly_message := '�w�֥D��' || v_merge_master || '��z';
         return;
      end if;
    exception
      when no_data_found then null;
    end;
  end check_readonly;
begin
  p_out_message_array := varchar2_tab();
  p_out_success := 'Y';

  begin
    select a.appl_no,                      a.receive_no,
           a.type_no,                      a.assign_date,
           a.processor_no,                 a.online_flg,
           a.receive_date,                 a.object_id,
           a.process_result,               a.pre_exam_date,
           a.pre_exam_qty,                 a.receive_area,
           a.postmark_date,                b.name_c
      into v_appl_no,                      v_receive_no,
           v_type_no,                      v_assign_date,
           v_processor_no,                 v_online_flg,
           v_receive_date,                 v_object_id,
           v_process_result,               v_pre_exam_date,
           v_pre_exam_qty,                 v_receive_area,
           v_postmark_date,                v_name_c
      from spt21 a, spm63 b
     where a.receive_no = p_in_receive_no
       and a.processor_no = b.processor_no(+);
  exception
    when no_data_found then
      p_out_success := 'N';
      add_message('�L��]�p�M�Q������(SPT21)�A�Ьd����');
  end;

  begin
    select appl_date,          re_appl_date,
           sc_flag,            twis_flag,
           foreign_language,   material_appl_date
      into v_appl_date,        v_re_appl_date,
           v_sc_flag,          v_twis_flag,
           v_foreign_language, v_material_appl_date
      from spt31
     where appl_no = v_appl_no;
    if v_type_no = '24100' and trim(v_re_appl_date) is null then
      add_message('���׵L�A�f�ӽФ���A�L�k�s�Z');
    end if;
  exception
    when no_data_found then
      p_out_success := 'N';
      add_message('�L��]�p�M�Q�ץ���(SPT31)�A�Ьd�����I');
  end;

  if v_process_result in ('41505', '43007')
    and substr(v_appl_no, 10, 1) = 'N' then
    declare
      l_charge_expir_date spmf1.charge_expir_date%type;
    begin
      select charge_expir_date
        into l_charge_expir_date
        from spmf1
       where trim(appl_no) = substr(v_appl_no, 1, 9)
         and revoke_flag != '1';
      if c_tw_sysdate > l_charge_expir_date then
        add_message('�~�O���Ĵ����O��');
      end if;
     
    exception
      when no_data_found then
        add_message('�L�~�O��T');
    end;
  end if;

  select nvl(sum(fee_amt), 0), decode(nvl(min(nvl(length(trim(receipt_no)), 0)), 0), 0, '���}', '�w�}')
    into v_receipt_amt, v_receipt_flg
    from spt13
   where receive_no = v_receive_no
     and number_type = 'A';

  begin
    select unusual
      into v_unusual
      from receive
     where receive_no = v_receive_no;
  exception
    when no_data_found then
      v_unusual := '0';
  end;

  begin
    select notice_date,   notice_date_2
      into v_notice_date, v_notice_date2
      from spt82
     where appl_no = v_appl_no;
  exception
    when no_data_found then
      v_notice_date := '';
      v_notice_date2 := '';
  end;
  
   begin
   -- �������奻
    select case when type='1' then receive_no 
            when type='2' then '�H�u����'
       else ''
       end  
    into v_first_receive_no
    from spt21c
     where appl_no = v_appl_no;
      --(�u�Wú�O���B)
      SELECT spt13.fee_amt
                into v_online_fee_amt 
      FROM ap.spt13
      WHERE spt13.receive_no = (SELECT spt21.issue_no
          FROM ap.spt21,ap.spm58
          WHERE spt21.issue_no = spm58.issue_no 
            And   spt21.receive_no = v_receive_no 
            And spm58.status < '6' )
        And spt13.number_type ='B' ;
  exception
    when no_data_found then null;
  end;

  declare
    l_notice_date spmf1.notice_date%type;
  begin
    select charge_expir_date,   revoke_date,   notice_date
      into v_charge_expir_date, v_revoke_date, l_notice_date
      from spmf1
     where trim(appl_no) = substr(v_appl_no, 1, 9)
       and revoke_flag != '1';
    if substr(v_appl_no, 4, 1) = '3' and trim(l_notice_date) is not null then
      add_message('��]�p�M�Q�w���i�A���o�ӽЭl�ͳ]�p�M�Q');
    end if;
  exception
    when no_data_found then
      v_charge_expir_date := '';
      v_revoke_date := '';
  end;

  if v_process_result is not null then
    begin
      select type_name
        into v_process_result_name
        from spm75
       where type_no = v_process_result;
    exception
      when no_data_found then
        v_process_result_name := '';
    end;
  end if;

  begin
    select case
             when material_code = '10' then c_yes
             else c_no
           end,
           case
             when material_code = '10' and priority_code = '10' then c_yes
             else c_no
           end,
           case
             when trim(pre_date) is not null then
               add_twdate_months(trim(pre_date), 15)
             else
               ''
           end
      into v_appl_exam_flag,
           v_appl_priority_exam_flag,
           v_pre_date
      from spt31b
     where appl_no = v_appl_no;
  exception
      when no_data_found then
        v_appl_exam_flag := c_no;
        v_appl_priority_exam_flag := c_no;
  end;
  

  if v_type_no = '10000' and trim(v_process_result) is null then
    declare
      v_count    number(3);
    begin
      select count(1)
        into v_count
        from spt31f
       where receive_no = v_receive_no;
      if v_count > 0 then
        v_appl_exam_flag := c_yes;
      end if;
    end;
  end if;

  v_show_exam_fee := '';
  v_exam_fee_page_cnt := 0;
  v_exam_fee_scope_items := 0;
  v_exam_fee_exam_pay := 0;
  v_exam_fee_exam_have_pay := 0;
  v_exam_fee_tax_amount := 0;
  v_exam_fee_e_flag := c_no;
  v_exam_fee_f_flag := c_no;

  begin
    select nvl(a.page_cnt, 0),    nvl(b.scope_items, 0),  nvl(b.exam_pay, 0),
           nvl(b.tax_amount, 0),  nvl(b.e_flag, c_no),    nvl(b.f_flag, c_no)
      into v_exam_fee_page_cnt,   v_exam_fee_scope_items, v_exam_fee_exam_pay,
           v_exam_fee_tax_amount, v_exam_fee_e_flag,      v_exam_fee_f_flag
      from spt31 a, spt31n b
     where a.appl_no = b.appl_no
       and b.receive_no = v_receive_no
       and b.appl_no = v_appl_no;
  exception
    when no_data_found then null;--���B�z
  end;

  begin
    select coment
      into v_spmfi_coment
      from ap.spmfi
     where appl_no = v_appl_no;
  exception
    when no_data_found then null; --���B�z
  end;

  get_annex(v_appl_no, v_online_flg, v_revise_value, v_annex_desc);

  for r_spm11a in (
    select b.attorney_class, b.attorney_no, b.degister_date, b.join_date ,status
      from spm11a a, spm61 b , spt31a c
     where a.appl_no = v_appl_no
       and a.attorney_class = b.attorney_class
       and a.attorney_no = b.attorney_no
       and A.Appl_No = c.appl_no
       and c.step_code = '10'
  ) loop
  --add_message('r_spm11a.attorney_class=' || r_spm11a.attorney_class || ';r_spm11a.degister_date='|| nvl(r_spm11a.degister_date,'1'));
    if r_spm11a.attorney_class = '1' and nvl(r_spm11a.degister_date,'1') ='1' then
      add_message('���ץ󤧥N�z�H�M�Q�v ' || r_spm11a.attorney_no || ' �|���n���A�Ъ`�N');
    elsif r_spm11a.status = '3' then
      add_message('���ץ󤧥N�z�H�G' || r_spm11a.attorney_no || ' �w�ܧ󨭤��A�Ъ`�N');
    elsif r_spm11a.attorney_class = '1' and trim(r_spm11a.join_date) is null then
      add_message('���ץ󤧥N�z�H�G'  || r_spm11a.attorney_no || ' �A�|���[�J�M�Q�v���|�A�гq���M�Q�@�դ@��A�����G7240');
    end if;
  end loop;

  declare
    v_count number;
  begin
    select count(1)
      into v_count
      from spm33
     where appl_no = v_appl_no
       and new_old_type = '0'
       and type_no in ('11000', '11002', '11004', '11006', '11008', '11010', '11090', '11092');
    if v_count > 0 then
      add_message('���ץ�w�Q���');
    end if;
  end;

  /*if length(trim(v_appl_no)) = 9 and v_type_no in ('16000', '16002', '16004') then
    declare
      v_count number;
    begin
      select count(1)
        into v_count
        from spt21
       where appl_no like trim(v_appl_no) || '%'
         and type_no = '15000';
      if v_count > 0 then
        add_message('���צ��ӽ��|�o��������A�Ъ`�N�����媺�ӽЮ׸���ƬO�_�ݭק�');
      end if;
    end;
  end if;*/

  select priority_right_obj(
           appl_no,           priority_flag,
           data_seq,          priority_date,
           priority_appl_no,  priority_nation_id,
           priority_doc_flag, priority_revive,
           access_code,       ip_type,
           elec_trans,        null
         )
    bulk collect
    into p_out_priority_right_array
    from spt32
   where appl_no = v_appl_no;

  if p_out_priority_right_array.count > 0 then
    declare
      function get_response_status(p_appl_no in varchar2, p_access_code in varchar2)
      return varchar2
      is
        v_response_status spt32_rq.response_status%type;
      begin
        select response_status
          into v_response_status
          from (
            select response_status
              from spt32_rq
             where trim(ref_doc_number) = trim(p_appl_no)
               and access_code = nvl(p_access_code, access_code)
             order by ack_id desc)
         where rownum = 1;
        return v_response_status;
      exception
        when no_data_found then return null;--���B�z
      end;
    begin
      for l_idx in p_out_priority_right_array.first .. p_out_priority_right_array.last
      loop
        p_out_priority_right_array(l_idx).response_status
          := get_response_status(v_appl_no, p_out_priority_right_array(l_idx).access_code);
      end loop;
    end;
  end if;

  if substr(v_appl_no, 4, 1) not in ('2', '3') then
    select biomaterial_obj(
             appl_no,         data_seq,    microbe_date,     microbe_org_id,
             microbe_appl_no, national_id, microbe_org_name
           )
      bulk collect
      into p_out_biomaterial_array
      from spt33
     where appl_no = v_appl_no
     order by data_seq;
  end if;

  select grace_period_obj(
           appl_no, data_seq, novel_flag, novel_item, novel_date, sort_id
         )
    bulk collect
    into p_out_grace_period_array
    from spt31l
   where appl_no = v_appl_no
   order by sort_id;

  select appl_seq || '#' || status || '#' || process_result
    bulk collect
    into p_out_request_item_array
    from ap.spt31w
   where appl_no = v_appl_no;

  p_out_proccess_info := proccess_info_obj(
    appl_no                 => v_appl_no,
    receive_no              => v_receive_no,
    type_no                 => v_type_no,
    assign_date             => v_assign_date,
    processor_no            => v_processor_no,
    receive_date            => v_receive_date,
    object_id               => v_object_id,
    process_result          => v_process_result,
    pre_exam_date           => v_pre_exam_date,
    pre_exam_qty            => v_pre_exam_qty,
    receive_area            => v_receive_area,
    appl_date               => v_appl_date,
    re_appl_date            => v_re_appl_date,
    sc_flag                 => v_sc_flag,
    twis_flag               => v_twis_flag,
    foreign_language        => v_foreign_language,
    pre_date                => v_pre_date,
    unusual                 => v_unusual,
    material_appl_date      => v_material_appl_date,
    name_c                  => v_name_c,
    receipt_amt             => v_receipt_amt,
    receipt_flg             => v_receipt_flg,
    charge_expir_date       => v_charge_expir_date,
    revoke_date             => v_revoke_date,
    notice_date             => v_notice_date,
    notice_date2            => v_notice_date2,
    process_result_name     => v_process_result_name,
    appl_exam_flag          => v_appl_exam_flag,
    appl_priority_exam_flag => v_appl_priority_exam_flag,
    show_exam_fee           => v_show_exam_fee,
    exam_fee_page_cnt       => v_exam_fee_page_cnt,
    exam_fee_scope_items    => v_exam_fee_scope_items,
    exam_fee_exam_pay       => v_exam_fee_exam_pay,
    exam_fee_exam_have_pay  => v_exam_fee_exam_have_pay,
    exam_fee_tax_amount     => v_exam_fee_tax_amount,
    exam_fee_e_flag         => v_exam_fee_e_flag,
    exam_fee_f_flag         => v_exam_fee_f_flag,
    spmfi_coment            => v_spmfi_coment,
    revise_value            => v_revise_value,
    annex_desc              => v_annex_desc,
    online_flg              => v_online_flg,
    postmark_date           => v_postmark_date,
    online_fee_amt          => v_online_fee_amt,
    first_receive_no        => v_first_receive_no
  );

  if p_out_success = 'Y' then
    check_readonly;
  end if;

--exception when others then
--  dbms_output.put_line(dbms_utility.format_error_stack);
end get_proccess_page;

/
