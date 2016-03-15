--------------------------------------------------------
--  DDL for Procedure SAVE_PROCCESS_PAGE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SAVE_PROCCESS_PAGE" (
  p_in_processor_no in char,
  p_in_draft_flag in number,
  p_in_proccess_info in proccess_info_obj,
  p_in_priority_right_array in priority_right_tab,
  p_in_biomaterial_array in biomaterial_tab,
  p_in_grace_period_array in grace_period_tab,
  p_in_merge_receive_no_array in varchar2_tab,
  p_in_set_first in number,
  p_out_warn_message_array out varchar2_tab,
  p_out_error_message_array out pair_tab,
  p_out_draft_message_array out pair_tab)
is
  --常數
  c_yes        constant char(1) := '1';
  c_no         constant char(1) := '0';

  g_tw_sysdate    char(7);
  g_appl_no       spt21.appl_no%type;
  g_receive_no    spt21.receive_no%type;
  g_origin_spt21  spt21%rowtype;
  g_origin_spt31  spt31%rowtype;
  g_step_code     spt31a.step_code%type; --案件階段別
  
  err_code        number ;
  err_msg         varchar2(200);
  err_func        varchar2(20);
/*
Desc: 案件審查
Last ModifyDate : 105/03/14
104/12/10 : add error message handle
104/11/23: spt31.TWIS_FLAG,spt31n.e_flag, spt31n.f_flag 為空值時,給'0'
104/12/10: 發明案於特定辦理結果時, 更新案件基本資料:  初審待發審日/文件齊備註記
105/01/13: 齊備辦理結果,增加'49269','49271' 
105/01/19: 整券條件改變: 發明案 and 辦理結果為('49213','49217','49215','49269','49271') 
105/01/22:項數檢核,排除辦理結果為補正選項的辦理結果49201、49205、49203
105/02/19: 申請衍生設計專利，其申請日不得早於原設計之申請日 ,母案為案號取前9碼
105/02/25: 首次中文本中 不再由案件審查介面指定,故資料來源直接由資料庫spt21c 判斷
105/03/03: 原設計專利已公告,不得申請衍生設計專利 只提示; 
           衍生案申請日檢核條件有誤請調整，不可早於母案，但可等於母案 ,當辦理結果43001 時,不可存檔,其它辦理結果只提示
105/03/14: 恢復回寫spmfi.content
*/
  procedure add_error_message(p_key in varchar2, p_message in varchar2)
  --================--
  --新增錯誤回傳訊息--
  --================--
  is
  begin
    p_out_error_message_array.extend;
    p_out_error_message_array(p_out_error_message_array.last) := pair_obj(p_key, p_message);
  end add_error_message;
    procedure add_warn_message(p_message in varchar2)
  is
  begin
    p_out_warn_message_array.extend;
    p_out_warn_message_array(p_out_warn_message_array.last) := p_message;
  end add_warn_message;

  procedure add_error_message(p_message in varchar2)
  --================--
  --新增錯誤回傳訊息--
  --================--
  is
  begin
    add_error_message('', p_message);
  end add_error_message;

  procedure init
  is

  begin
    err_func := 'init';
   
    p_out_warn_message_array := varchar2_tab();
    p_out_error_message_array := pair_tab();
    g_tw_sysdate := to_char(sysdate, 'yyyymmdd') - 19110000;
    select *
      into g_origin_spt21
      from spt21
     where receive_no = rpad(p_in_proccess_info.receive_no, 12, ' ');
    g_appl_no := g_origin_spt21.appl_no;
    g_receive_no := g_origin_spt21.receive_no;
    select *
      into g_origin_spt31
      from spt31
     where appl_no = g_appl_no;
    select step_code
      into g_step_code
      from spt31a
     where appl_no = g_appl_no;
  end init;

  function check_spt21c
  return number
  is
  begin
    err_func := 'check_spt21c';
    if g_origin_spt31.first_day >= '0991011' then
      declare
        v_status spt21c.status%type;
      begin
        select status
          into v_status
          from spt21c
         where appl_no = g_appl_no;
        if trim(v_status) != '9' then
          return 1;
        end if;
        return 0;
      exception
        when no_data_found then
          return 2;
      end;
    end if;
  end check_spt21c;

  procedure check_proccess_info
  --====================--
  --簡易案件基本資料檢核--
  --====================--
  is
  l_rec number;
  begin
    err_func := 'check_proccess_info';
    if p_in_proccess_info is null then
      add_error_message('伺服器無法取得案件基本資料');
      return;
    end if;
    if p_in_proccess_info.appl_date is null then
      add_error_message('APPL_DATE', '申請日期未輸入');
    elsif not valid_tw_date(p_in_proccess_info.appl_date) then
      add_error_message('APPL_DATE', '申請日期非正確民國日期格式');
    end if;
    if p_in_proccess_info.process_result is not null then
      declare
        v_tmp_num number(4);
      begin
        select count(1)
          into v_tmp_num
          from spm75
         where type_no = p_in_proccess_info.process_result
           and type_no > '40000';
        if v_tmp_num = 0 then
          add_error_message('PROCESS_RESULT', '辦理結果格式錯誤');
        else
          p_out_error_message_array :=
              p_out_error_message_array multiset union wf_check(g_receive_no,
                          p_in_proccess_info.appl_date,
                          p_in_proccess_info.process_result,
                          p_in_proccess_info.appl_exam_flag,
                          p_in_proccess_info.appl_priority_exam_flag,
                          p_in_proccess_info.pre_exam_date,
                          p_in_proccess_info.pre_exam_qty,
                          'N');
          if g_origin_spt21.type_no = '13000' then
            if p_in_proccess_info.re_appl_date is not null and not valid_tw_date(p_in_proccess_info.re_appl_date) then
              add_error_message('RE_APPL_DATE', '再審申請日格式不正確');
            end if;
          end if;
         
          if g_origin_spt21.type_no in ('10000', '24704', '24706', '21000', '21002', '24002', '11000', '11002', '11004', '11008', '11092', '12000')
              and p_in_proccess_info.process_result not in ('49201','49203','49205')
              and substr(g_appl_no, 1, 3) >= '099'
              and substr(g_appl_no, 4, 1) = '1'
              and (p_in_proccess_info.appl_exam_flag = c_yes
                or p_in_proccess_info.appl_priority_exam_flag = c_yes
                or trim(g_origin_spt31.material_appl_date) is not null)
              and (p_in_proccess_info.exam_fee_scope_items is null
                or p_in_proccess_info.exam_fee_scope_items = 0)then
            add_error_message('EXAM_FEE_SCOPE_ITEMS', '項數為 0,請重新輸入!!');
          end if;
          
          if p_in_proccess_info.process_result in ('49213', '49215', '49217', '43191', '43199', '43001', '43015', '43009','49269','49271')
              then
              v_tmp_num := 0;
              select count(1)  into v_tmp_num  from spt21c     where appl_no = g_appl_no;
             if v_tmp_num = 0 then
               add_error_message('PROCESS_RESULT', '未指定首次中文說明書(圖說),不可進行文件齊備通知作業!');
               
               /* Mark by Susan 
                  104/08/31 因指定中文本改以每日批次和090進行同步,spt21c 註記改以用來視別是否已和090同步
                  故不再於案件審查時檢查*/
             /*  
              else
               case check_spt21c
                  when 1 then add_error_message('PROCESS_RESULT', '首次中文說明書(圖說)尚未完成人工整檔,不可進行文件齊備通知作業!');
                 when 2 then add_error_message('PROCESS_RESULT', '首次中文說明書(圖說)尚未完成確認,不可進行文件齊備通知作業!');
                  else null;
                 end case;
               --*/
            end if;
          end if;
        
        end if;
      end;
    end if;
   if substr(g_appl_no, 4, 1) = '3' and g_origin_spt21.type_no = '10007' then
      declare
        v_notice_date spmf1.notice_date%type;
        v_appl_date   spt31.appl_date%type;
      begin
        select notice_date
          into v_notice_date
          from spmf1
         where trim(appl_no) = substr(g_appl_no, 1, 9)
         and revoke_flag != '1';
         
         select appl_date into v_appl_date
         from spt31 where trim(appl_no) = substr(g_appl_no,1,9) and appl_no != g_appl_no;
      
        if  v_appl_date > p_in_proccess_info.appl_date  then 
           if  p_in_proccess_info.process_result = '43001' then
                add_error_message('申請衍生設計專利，其申請日不得早於原設計之申請日！');
           else
                add_warn_message('申請衍生設計專利，其申請日不得早於原設計之申請日！');
           end if;
        end if;
        if trim(v_notice_date) is not null then
          add_warn_message('原設計專利已公告,不得申請衍生設計專利!');
        end if;
             
      exception
        when no_data_found then null;--不處理
      end;
    end if;
    
     l_rec := 0;
         SELECT count(distinct receive_no)  into l_rec
         FROM ap.spt31f  
        WHERE spt31f.appl_no = g_appl_no;
      
        if g_step_code <29 and l_rec=0 and (p_in_proccess_info.appl_exam_flag > 0 or  p_in_proccess_info.appl_priority_exam_flag>0) then
              add_error_message('無相關之申請實體審查收文資料，請重新收文');
        end if;
  end check_proccess_info;

  procedure save_proccess_info
  --================--
  --儲存案件基本資料--
  --================--
  is
  begin
    err_func := 'save_proccess_info';
    update spt21
       set process_result = p_in_proccess_info.process_result,
           pre_exam_date = p_in_proccess_info.pre_exam_date,
           pre_exam_qty = p_in_proccess_info.pre_exam_qty,
           complete_date = g_tw_sysdate
     where receive_no = g_receive_no;
    update spt31
       set appl_date = p_in_proccess_info.appl_date,
           twis_flag = nvl(p_in_proccess_info.twis_flag,'0'),
           patent_status = '3'
     where appl_no = g_appl_no;
     ----------------------------------
     -- add by susan  104/09/02 
     -- for meeting decision 
     /*
     -- move the code to procedure  get_receive 
     update spt31
      set sch_processor_no= p_in_processor_no, phy_processor_no = p_in_processor_no
      where appl_no in
      (
        select appl_no from spt31a 
        where appl_no = g_appl_no
        and ((step_code between '10' and '19'  and step_code != '15')
              or step_code = '30'
              or step_code = '29'
              or step_code = '49'
              or ( exists (select 1 from spt21 where appl_no = spt31.appl_no and  type_no in ('16000','16002','22210')))
            )
      and substr(appl_no,10,1) != 'N');
      */
     -- end
     ------------------------------------
    if g_origin_spt21.type_no = '13000' and valid_tw_date(p_in_proccess_info.re_appl_date) then
      update spt31
         set re_appl_date = p_in_proccess_info.re_appl_date
       where appl_no = g_appl_no;
      if g_step_code < '30' then
        update spt31a
           set step_code = '30',
               type_no = g_origin_spt21.type_no,
               data_date = g_origin_spt21.receive_date,
               ipc_group_no = '70012'
         where appl_no = g_appl_no;
      end if;
    end if;
    ---------
    --start  add by susan 2015/12/10
    ---------
    if p_in_proccess_info.process_result in ( '43001','43003','43009','43011','43007','43015','43023','42003','42007','42015','40109','40111','40113','40115','40117','40119',
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
    if p_in_proccess_info.process_result = '43199' then
      update spt31
         set f_adt_date = g_tw_sysdate,
             pre_exam_check  = '1'
       where appl_no = g_appl_no;
    end if;
    if p_in_proccess_info.process_result = '41001' and g_origin_spt21.process_result = '43199' then
      update spt31
         set f_adt_date = '',
             pre_exam_check = ''
       where appl_no = g_appl_no;
    end if;
    if p_in_proccess_info.process_result = '43191' then
      update spt31
         set f_adt_date = g_tw_sysdate,
             pre_exam_check  = '1'
       where appl_no = g_appl_no;
      update spt31a
         set step_code = '15',
             ipc_group_no = '70019'
       where appl_no = g_appl_no;
    end if;
    if p_in_proccess_info.process_result = '41001' and g_origin_spt21.process_result = '43191' then
      update spt31
         set f_adt_date = '',
             pre_exam_check = ''
       where appl_no = g_appl_no;
      update spt31a
         set step_code = '10',
             ipc_group_no = '60037'
       where appl_no = g_appl_no;
    end if;
    
    /*
     ----
    -- write to dblog 104/9/14
    ----
    DBLOG_193(p_in_processor_no,'U','RECEIVE',' where receive_no =  '|| '''' || g_receive_no ||'''');
    --------------
    -- write to dblog end
    ----------------
    */
    update receive
       set unusual = p_in_proccess_info.unusual,
           step_code = decode(p_in_proccess_info.process_result, null, '2', '3')
     where receive_no = g_receive_no;
    --[審查費計算]儲存 開始
   
    declare
      v_count_spt31n       number;
    begin
      if g_origin_spt21.type_no in (
          '10000', '24704', '24706', '21000', '21002',
          '24002', '11000', '11002', '11004', '11008',
          '11092', '12000', '13000', '24100')
        and substr(g_appl_no, 4, 1) = '1'
        and substr(g_appl_no, 1, 3) >= '099'
        and (
             p_in_proccess_info.appl_exam_flag = c_yes
             or p_in_proccess_info.appl_priority_exam_flag = c_yes
             or trim(g_origin_spt31.material_appl_date) is not null
             or p_in_proccess_info.type_no in ('13000', '24100')
            )
        and p_in_proccess_info.exam_fee_scope_items > 0 then
        select count(1)
          into v_count_spt31n
          from spt31n
         where receive_no = g_receive_no
           and appl_no = g_appl_no;
        if v_count_spt31n > 0 then
          update spt31n
             set scope_items = p_in_proccess_info.exam_fee_scope_items,
                 exam_pay = p_in_proccess_info.exam_fee_exam_pay,
                 tax_amount = p_in_proccess_info.exam_fee_tax_amount,
                 e_flag = nvl(p_in_proccess_info.exam_fee_e_flag,'0'),
                 f_flag = nvl(p_in_proccess_info.exam_fee_f_flag,'0')
           where receive_no = g_receive_no
             and appl_no = g_appl_no;
        else
          insert into spt31n
          (
            receive_no,
            appl_no,
            scope_items,
            exam_pay,
            tax_amount,
            e_flag,
            f_flag
          ) values (
            g_receive_no,
            g_appl_no,
            p_in_proccess_info.exam_fee_scope_items,
            p_in_proccess_info.exam_fee_exam_pay,
            p_in_proccess_info.exam_fee_tax_amount,
            nvl(p_in_proccess_info.exam_fee_e_flag,'0'),
            nvl(p_in_proccess_info.exam_fee_f_flag,'0')
          );
        end if;
        update spt31
           set page_cnt = p_in_proccess_info.exam_fee_page_cnt,
               scope_items = p_in_proccess_info.exam_fee_scope_items
         where appl_no = g_appl_no ;
      end if;
    end;
 
    --[審查費計算]儲存 結束
    --[申請實體審查與申請實體審查與優先審查]儲存 開始
    save_appl_exam(
      g_appl_no,
      g_receive_no,
      p_in_proccess_info.process_result,
      p_in_proccess_info.appl_exam_flag,
      p_in_proccess_info.appl_priority_exam_flag);
    --[申請實體審查與申請實體審查與優先審查]儲存 結束
    --[補正選項]儲存 開始
    save_annex(g_appl_no, p_in_proccess_info.revise_value, p_in_proccess_info.annex_desc);
    --[補正選項]儲存 結束
    --[代為更正]儲存 開始
    
    
    ---取消update 函稿更正內容 spmfi ,原更新補正選項已改寫入193 table appl50 
    -- cancel by Susan  2015/11/17
    -- still need to write back the content  2016/03/14
    declare
      v_count_spmfi number;
    begin
      select count(1)
        into v_count_spmfi
        from ap.spmfi
       where appl_no = g_appl_no;
      if trim(p_in_proccess_info.spmfi_coment) is not null then
        if v_count_spmfi > 0 then
          update ap.spmfi
             set coment = trim(p_in_proccess_info.spmfi_coment)
           where appl_no = g_appl_no;
        else
          insert into ap.spmfi
          (
            appl_no,
            coment
          ) values (
            g_appl_no,
            trim(p_in_proccess_info.spmfi_coment)
          );
        end if;
      else
        if v_count_spmfi > 0 then
          delete ap.spmfi where appl_no = g_appl_no;
        end if;
      end if;
    end;
    
    --[代為更正]儲存 結束
    --[wf_material_appl_date] 儲存 開始
    save_material_appl_date(
      g_appl_no,
      g_receive_no,
      p_in_proccess_info.appl_exam_flag,
      p_in_proccess_info.appl_priority_exam_flag);
    --[wf_material_appl_date] 儲存 結束
    --[併辦]儲存 開始
    declare
      v_after_receive_tab   after_receive_tab;
      v_count               number;
      v_after_receive       after_receive_obj;
    begin
    
      v_after_receive_tab := get_after_receives(g_receive_no);
     if v_after_receive_tab.last is not null then  -- add by Susan 104/07/03
      
        for l_idx in v_after_receive_tab.first .. v_after_receive_tab.last
        loop
          v_after_receive := v_after_receive_tab(l_idx);
      
          select count(1)
            into v_count
            from table(p_in_merge_receive_no_array)
           where trim(column_value) = trim(v_after_receive.receive_no);
          
          if v_count != 0 then
            save_merge_receive(p_in_processor_no, v_after_receive.receive_no, g_receive_no, 'Y');
          else
            if v_after_receive.merge_master is not null then
              save_merge_receive(p_in_processor_no, v_after_receive.receive_no, v_after_receive.merge_master, 'N');
            end if;
          end if;
        end loop;
      end if;
    end;
    
    --[併辦]儲存 結束
  end save_proccess_info;

  procedure draft_check
  --========--
  --製稿檢查--
  --========--
  is
  begin
    err_func := 'draft_check';
    p_out_draft_message_array := pair_tab();
    declare
      v_form_file_a spt41.form_file_a%type;
    begin
          
       select form_file_a into v_form_file_a
       from 
       (
        select form_file_a
        from spt41 a
        where a.check_datetime is null
        and a.processor_no =  p_in_processor_no
        and a.receive_no =  g_receive_no
        and a.form_file_a = (select max(b.form_file_a) from spt41 b where b.receive_no = a.receive_no)
        union all         
        select form_file_a
        from spm56  a
        where processor_no =  p_in_processor_no
         and receive_no = g_receive_no
         and form_file_a =  (select max(form_file_a) from spm56 b where b.receive_no = a.receive_no and b.processor_no =  a.processor_no)
         and issue_flag = '1'
         and online_sign = '1'
         and exists (select 1 from ap.sptd02 where form_file_a = a.form_file_a and node_status >= '400' and node_status < '900')
         )
         ;
      p_out_draft_message_array.extend;
      p_out_draft_message_array(p_out_draft_message_array.last) :=
        pair_obj('ISSUE_NO', '本案尚有待發文的函稿[稿號' || v_form_file_a ||'],請確認是否發文!');
    exception
      when no_data_found then null;
    end;
    declare
      v_count number;
    begin
    if  p_in_proccess_info.process_result = '49213' and substr(g_appl_no,4,1)= '1' then
      select count(1)
        into v_count
        from spm56 
       where form_id = 'P03-1'
         and issue_flag = '2'
         and appl_no = g_appl_no;
     
      if v_count > 0 then
        p_out_draft_message_array.extend;
        p_out_draft_message_array(p_out_draft_message_array.last) :=
          pair_obj('', '已製過P03-1稿且已發文!');
      end if;
     
    end if;
    end;
    /* Mark by Susan 
      104/08/31 因指定中文本改以每日批次和090進行同步,spt21c 註記改以用來視別是否已和090同步
      故不再於案件審查時檢查*/
    /*-------------------------------------
    if p_in_proccess_info.process_result in (
        '49213', '49215', '49217', '49269', '49271', '49207', '49209', '49211', '49221', '49223',
        '49225', '49265', '49267', '49269', '49271', '49273', '49275', '43191', '43199', '43001') then
      case check_spt21c
        when 1 then
          p_out_draft_message_array.extend;
          p_out_draft_message_array(p_out_draft_message_array.last) :=
            pair_obj('', '首次中文說明書(圖說)尚未完成人工整檔,不可進行文件齊備通知作業!');
        when 2 then
          p_out_draft_message_array.extend;
          p_out_draft_message_array(p_out_draft_message_array.last) :=
            pair_obj('', '首次中文說明書(圖說)尚未完成確認,不可進行文件齊備通知作業!');
        else
          null;
      end case;
    end if;
    */
    if g_origin_spt21.type_no = '24100' then
      if trim(g_origin_spt31.re_appl_date) is null then
        p_out_draft_message_array.extend;
        p_out_draft_message_array(p_out_draft_message_array.last) := pair_obj('', '此案無再審申請日期,無法製稿');
      end if;
    end if;
    if substr(g_appl_no, 4, 1) = '1' and p_in_proccess_info.process_result in ('49213','49217','49215','49269','49271')  then
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
               and p_in_proccess_info.process_result is not null then -- 不用限定齊備之辦理結果 modify by Susan
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

  check_proccess_info;
  validate_priority_right(
    p_in_proccess_info.process_result,
    p_in_proccess_info.appl_date,
    p_in_priority_right_array,
    p_out_error_message_array);
  if substr(g_appl_no, 4, 1) not in ('2', '3') then
    validate_biomaterial(
      p_in_proccess_info.process_result,
      p_in_biomaterial_array,
      p_out_error_message_array);
  end if;
  validate_grace_period(
    p_in_proccess_info.process_result,
    p_in_grace_period_array,
    p_out_error_message_array);

  --檢核沒錯誤才可以儲存
  if p_out_error_message_array.count = 0 then
      
    save_proccess_info;
    save_priority_right(
      g_appl_no,
      p_in_proccess_info.process_result,
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

exception
  when others then
    rollback;
    err_code := SQLCODE;
    err_msg := SUBSTR(SQLERRM, 1, 200);
   
    raise_application_error(-20001,to_char(sysdate,'yyyyMMdd hh24:mm:ss') ||':Procedure SAVE_PROCCESS_PAGE[' || err_func || '] error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
end save_proccess_page;

/
