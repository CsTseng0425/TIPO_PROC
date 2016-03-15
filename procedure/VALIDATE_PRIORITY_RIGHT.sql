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
105/01/13: 齊備辦理結果,增加'49269','49271' 
105/01/29: 檢核: 國內外優先權資料(' || l_idx || ') 辦理齊備：該案不是優先權交換國家,已送優先權註記不可為空
           原判斷欄位錯誤elec_trac => priority_doc_flag
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
      add_error_message('國內外優先權資料(' || l_idx || ') 不受理註記未輸入');
    end if;
    if v_tmp_priority_right.priority_date is not null
      and not valid_date(v_tmp_priority_right.priority_date) then
      add_error_message('國內外優先權資料(' || l_idx || ') 優先權日期非正確西元日期格式');
    end if;
    if trim(v_tmp_priority_right.priority_nation_id) is not null then
      select count(1)
        into v_tmp_num
        from spmf5 a
       where nvl(a.data_deadline, 9991231) > to_char(sysdate, 'YYYYMMDD') - 19110000 
         and a.national_id = v_tmp_priority_right.priority_nation_id;
      if v_tmp_num = 0 then
        add_error_message('國內外優先權資料(' || l_idx || ') 非正確國籍，請重新輸入!');
      end if;
    end if;
    if v_tmp_priority_right.priority_flag = 1 then
      /*
      不受理註記為"受理", 日期 / 國籍 為空, 且辦理結果為齊備之辦理結果時, 可以儲存, 不可製稿
      if trim(v_tmp_priority_right.priority_nation_id) is null then
        if p_in_process_result in (
            '49213', '43191', '43199', '43001', '49217', '43015', '49215', '43009', '49243') then
          add_error_message('PROCESS_RESULT', '國內外優先權資料(' || l_idx || ') 國籍不得為空值，請處分不受理!');
        end if;
      end if;
      */
      if trim(v_tmp_priority_right.priority_date) is null then
        /*
        不受理註記為"受理", 日期 / 國籍 為空, 且辦理結果為齊備之辦理結果時, 可以儲存, 不可製稿
        if p_in_process_result in (
            '49213', '43191', '43199', '43001', '49217', '43015', '49215', '43009', '49243') then
          add_error_message('PROCESS_RESULT', '國內外優先權資料(' || l_idx || ') 優先權日期不得為空值，請處分不受理!');
        end if;
        */
        null;
      else
        if valid_tw_date(p_in_appl_date)
          and v_tmp_priority_right.priority_date >= p_in_appl_date + 19110000
          and p_in_process_result in (
            '49213', '43191', '43199', '43001', '49217', '43015', '49215', '43009', '49243','49269','49271') then
          add_error_message('PROCESS_RESULT', '國內外優先權資料(' || l_idx || ') 晚於或等於申請日，請確認!');
        end if;
      end if;
    end if;
    if v_tmp_priority_right.priority_revive = '1' and nvl(v_tmp_priority_right.priority_flag, 'X') != '1' then
      add_error_message('國內外優先權資料(' || l_idx || ') 優先權復權只能選擇優先權受理，請重新輸入!');
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
        add_error_message('國內外優先權資料(' || v_tmp_priority_right.data_seq || ') 非開放優先權交換國家，不可填寫存取碼及專利類型');
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
          add_error_message('PROCESS_RESULT', '國內外優先權資料(' || l_idx || ') 辦理齊備：該案為優先權國藉-日本-有主張優先權且無不受理或撤回之註記，其「已送優先權證明文件」或「專利類別及存取碼」必須二者其中有資料，才容許製稿或存檔!');
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
            add_error_message('PROCESS_RESULT', '國內外優先權資料(' || l_idx || ') 辦理齊備：該案為優先權交換國-韓國-有主張優先權且無不受理或撤回之註記，其「已送優先權證明文件」或「電子交換註記及專利類別」必須二者其中有資料，才容許製稿或存檔!');
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
              add_error_message('PROCESS_RESULT', '國內外優先權資料(' || l_idx || ') 辦理齊備：該案不是優先權交換國家,已送優先權註記不可為空!');
         end if;
       end if;
    end if;
    
     
  end loop;
end validate_priority_right;

/
