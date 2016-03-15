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
  --常數
  c_yes                     constant char(1) := '1';
  c_no                      constant char(1) := '0';
  --原始資料
  g_origin_spt31            spt31%rowtype;
  --變數
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
  Desc: 逕予審查
  Last ModifyDate : 105/01/13
  辦理結果  '49213','49215','49217' 由 193 製稿的才列為線上審查案件
  105/01/13: 齊備辦理結果,增加'49269','49271' 
  105/01/19: 整券條件改變: 發明案 and 辦理結果為('49213','49217','49215','49269','49271') 
  105/02/25: 首次中文本中 不再由案件審查介面指定,故資料來源直接由資料庫spt21c 判斷

  */
  procedure add_warn_message(p_message in varchar2)
  --================--
  --新增警告回傳訊息--
  --================--
  is
  begin
    p_out_warn_message_array.extend;
    p_out_warn_message_array(p_out_warn_message_array.last) := p_message;
  end add_warn_message;
  
  procedure add_error_message(p_key in varchar2, p_message in varchar2)
  --================--
  --新增錯誤回傳訊息--
  --================--
  is
  begin
    p_out_error_message_array.extend;
    p_out_error_message_array(p_out_error_message_array.last) := pair_obj(p_key, p_message);
  end add_error_message;
  
  procedure add_error_message(p_message in varchar2)
  --================--
  --新增錯誤回傳訊息--
  --================--
  is
  begin
    add_error_message('', p_message);
  end add_error_message;
  
  procedure init
  --==============--
  --初始化相關處理--
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
  --簡易案件基本資料檢核--
  --====================--
  is
  begin
    if g_appl_date is null then
      add_error_message('APPL_DATE', '申請日期未輸入');
    elsif not valid_tw_date(g_appl_date) then
      add_error_message('APPL_DATE', '申請日期非正確民國日期格式');
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
          add_error_message('PROCESS_RESULT', '辦理結果格式錯誤');
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
                 add_error_message('PROCESS_RESULT', '未指定首次中文說明書(圖說),不可進行文件齊備通知作業!');
               end if;
                  /* Mark by Susan 
                  104/12/10 因指定中文本改以每日批次和090進行同步,spt21c 註記改以用來視別是否已和090同步
                  故不再於案件審查時檢查*/
                      -------------------------------------*/
                      /*
                if trim(v_status) != '9' then
                  add_error_message('PROCESS_RESULT', '首次中文說明書(圖說)尚未完成人工整檔,不可進行文件齊備通知作業!');
                end if;
                */
              exception
                when no_data_found then
                  add_error_message('PROCESS_RESULT', '首次中文說明書(圖說)尚未完成確認,不可進行文件齊備通知作業!');
              end;
            end if;
          end if;
        end if;
      end;
    end if;
    if g_process_result in ('49259', '49245', '49255', '49249') or g_step_code < 29 then
      if g_spt31f_receive_no is null then
        add_error_message('欲註記之文號未選擇');
      end if;
    end if;
  end check_direct_info;
  
  procedure save_direct_info
  --================--
  --儲存案件基本資料--
  --================--
  is
  begin
    update spt31  
       set appl_date = g_appl_date,
		       patent_status = '3',
			--     sch_processor_no = p_in_processor_no, --> 取消回寫  mark by susan 
			--     phy_processor_no = p_in_processor_no, --  > 原本就不用回寫 mark by susan 
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
  --製稿檢查--
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
          pair_obj('', '已製過P03-1稿且已發文!');
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
          p_out_draft_message_array(p_out_draft_message_array.last) := pair_obj('DOC_COMPLETE', '尚未整卷，不可辦理齊備');
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
               and g_process_result is not null then -- 不用限定齊備之辦理結果 modify by Susan
            if trim(v_tmp_priority_right.priority_nation_id) is null then
              p_out_draft_message_array.extend;
              p_out_draft_message_array(p_out_draft_message_array.last) := pair_obj('PRIORITY_RIGHT_PRIORITY_NATION_ID_' || l_idx, '國內外優先權資料(' || l_idx || ') 國籍不得為空值，請處分不受理!');
            end if;
            if trim(v_tmp_priority_right.priority_date) is null then
              p_out_draft_message_array.extend;
              p_out_draft_message_array(p_out_draft_message_array.last) := pair_obj('PRIORITY_RIGHT_PRIORITY_DATE_' || l_idx, '國內外優先權資料(' || l_idx || ') 優先權日期不得為空值，請處分不受理!');
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
  
  --檢核沒錯誤才可以儲存
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
