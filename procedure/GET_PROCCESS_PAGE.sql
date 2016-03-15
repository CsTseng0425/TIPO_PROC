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
  --常數
  c_yes         constant char(1) := '1';
  c_no          constant char(1) := '0';
  c_tw_sysdate  constant char(7) := to_char(sysdate, 'yyyymmdd') - 19110000;
  
  --spt21 收文資料
  v_appl_no                 spt21.appl_no%type;            --申請案號
  v_receive_no              spt21.receive_no%type;         --收文文號
  v_type_no                 spt21.type_no%type;            --收文案由
  v_assign_date             spt21.assign_date%type;        --分辦日期
  v_processor_no            spt21.processor_no%type;       --承辦人代碼
  v_receive_date            spt21.receive_date%type;       --收文日期
  v_object_id               spt21.object_id%type;          --持有者
  v_process_result          spt21.process_result%type;     --辦理結果
  v_pre_exam_date           spt21.pre_exam_date%type;      --補正期限
  v_pre_exam_qty            spt21.pre_exam_qty%type;       --補正日數
  v_receive_area            spt21.receive_area%type;       --收文區域代碼
  v_online_flg              spt21.online_flg%type;         --線上標記
  v_postmark_date           spt21.postmark_date%type;      --郵戳日期
  --spt31 案件資料
  v_appl_date               spt31.appl_date%type;          --申請日
  v_re_appl_date            spt31.re_appl_date%type;       --再審申請日
  v_material_appl_date      spt31.material_appl_date%type; --申請實體審查日
  v_sc_flag                 spt31.sc_flag%type;            --國家機密註記
  v_twis_flag               spt31.twis_flag%type;          --一案兩請註記
  v_foreign_language        spt31.foreign_language%type;   --外文本種類
  --spt31b 案件公開狀態資料檔
  v_pre_date                spt31b.pre_date%type;          --公開準備起始日
  --receive 收文辦理檔
  v_unusual                 receive.unusual%type;          --程序覆核

  v_name_c                  spm63.name_c%type;             --承辦人姓名
  --spt13 規費收據紀錄
  v_receipt_amt             number(7);                     --收據金額
  v_receipt_flg             varchar2(2 char);              --收據註記
  --spt82 專利公告資料
  v_notice_date             spt82.notice_date%type;        --公告日期
  v_notice_date2            spt82.notice_date_2%type;      --公開日期
  --spmf1 專利權資料
  v_charge_expir_date       spmf1.charge_expir_date%type;  --年費有效日期
  v_revoke_date             spmf1.revoke_date%type;        --撤銷日期
  --spm75 案由資料
  v_process_result_name     spm75.type_name%type;          --辦理結果中文
  -- 邏輯判斷
  v_appl_exam_flag          varchar2(1);                   --申請實體審查
  v_appl_priority_exam_flag varchar2(1);                   --申請實體審查與優先審查

  v_show_exam_fee           varchar2(1);                   --是否顯示審查費細項資料
  v_exam_fee_page_cnt       spt31.page_cnt%type;           --案件頁數
  v_exam_fee_scope_items    spt31n.scope_items%type;       --申請專利範圍項數
  v_exam_fee_exam_pay       spt31n.exam_pay%type;          --應繳審查費
  v_exam_fee_exam_have_pay  number(6);                     --已繳審查費
  v_exam_fee_tax_amount     spt31n.tax_amount%type;        --補繳或退還審查費
  v_exam_fee_e_flag         spt31n.e_flag%type;            --英譯
  v_exam_fee_f_flag         spt31n.f_flag%type;            --電子

  v_spmfi_coment            ap.spmfi.coment%type;             --代為更正備忘

  v_revise_value            appl.pre_exam_list%type;       --補正選項資訊
  v_annex_desc              appl50.annex_desc%type;        --附件說明
  v_online_fee_amt          number(6);            --線上繳費金額
  v_first_receive_no        spt21c.receive_no%type;        --首次中文本

  procedure add_message (p_message in varchar2)
  --============--
  --新增回傳訊息--
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
      p_out_readonly_message := '此公文有國防機密註記，不可編輯';
      return;
    end if;
    select count(1)
      into v_count
      from spt21
     where online_flg = 'Y'
       and receive_no = v_receive_no;
    if v_count = 0 then
      p_out_readonly_message := '紙本文件只能檢視不能辦理';
      return;
    end if;
    --- add by Susan for exclude the receives which process_result = 57001
     select count(1)
      into v_count
      from spt21
     where process_result = '57001'
       and receive_no = v_receive_no;
    if v_count >0  then
      p_out_readonly_message := '此文已作廢!不能辦理';
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
      p_out_readonly_message := '實體附件未簽收不能辦理';
      return;
    end if;
    select count(1)
      into v_count
      from spt21
     where processor_no = p_in_processor_no
       and receive_no = v_receive_no;
    if v_count = 0 then
      p_out_readonly_message := '非承辦之文件不能辦理';
      return;
    end if;
    select count(1)
      into v_count
      from receive
     where processor_no = p_in_processor_no
       and step_code = '8'
       and receive_no = v_receive_no;
    if v_count > 0 then
      p_out_readonly_message := '文已辦結,不能編輯';
      return;
    end if;
    select count(1)
      into v_count
      from doc
     where receive_no = v_receive_no;
    if v_count = 0 then
      p_out_readonly_message := '影像未到不能辦理';
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
      p_out_readonly_message := '辦理結果為43199且首次收文日早於0920701';
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
         p_out_readonly_message := '已併主文' || v_merge_master || '辦理';
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
      add_message('無原設計專利收文資料(SPT21)，請查明之');
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
      add_message('此案無再審申請日期，無法製稿');
    end if;
  exception
    when no_data_found then
      p_out_success := 'N';
      add_message('無原設計專利案件資料(SPT31)，請查明之！');
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
        add_message('年費有效期限逾期');
      end if;
     
    exception
      when no_data_found then
        add_message('無年費資訊');
    end;
  end if;

  select nvl(sum(fee_amt), 0), decode(nvl(min(nvl(length(trim(receipt_no)), 0)), 0), 0, '未開', '已開')
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
   -- 首次中文本
    select case when type='1' then receive_no 
            when type='2' then '人工整檔'
       else ''
       end  
    into v_first_receive_no
    from spt21c
     where appl_no = v_appl_no;
      --(線上繳費金額)
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
      add_message('原設計專利已公告，不得申請衍生設計專利');
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
    when no_data_found then null;--不處理
  end;

  begin
    select coment
      into v_spmfi_coment
      from ap.spmfi
     where appl_no = v_appl_no;
  exception
    when no_data_found then null; --不處理
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
      add_message('本案件之代理人專利師 ' || r_spm11a.attorney_no || ' 尚未登錄，請注意');
    elsif r_spm11a.status = '3' then
      add_message('本案件之代理人：' || r_spm11a.attorney_no || ' 已變更身分，請注意');
    elsif r_spm11a.attorney_class = '1' and trim(r_spm11a.join_date) is null then
      add_message('本案件之代理人：'  || r_spm11a.attorney_no || ' ，尚未加入專利師公會，請通知專利一組一科，分機：7240');
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
      add_message('此案件已被改請');
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
        add_message('此案有申請舉發相關收文，請注意此收文的申請案號資料是否需修改');
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
        when no_data_found then return null;--不處理
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
