--------------------------------------------------------
--  DDL for Function WF_CHECK
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."WF_CHECK" (p_no                      in char,
                                      p_appl_date               in varchar2,
                                      p_process_result          in varchar2,
                                      p_appl_exam_flag          in varchar2,
                                      p_appl_priority_exam_flag in varchar2,
                                      p_pre_exam_date           in varchar2,
                                      p_pre_exam_qty            in number,
                                      p_is_from_page            in varchar2)
  return pair_tab is
  c_yes constant char(1) := '1';
  g_out_message_array pair_tab := pair_tab();

  v_appl_no      spt21.appl_no%type;
  v_type_no      spt21.type_no%type;
  v_appl_date    spt31.appl_date%type;
  v_re_appl_date spt31.re_appl_date%type;
  v_step_code    spt31a.step_code%type;
  v_tmp_count    number(4);
/*
  Desc: 檢核案件審查資料 call by procedure save_process_page
  ModifyDate : 105/02/15
  105/02/15 : 後續文,當辦理結果補正, 補正期限和補正日數二擇一輸入,取消限定部分辦理結果
  105/03/14: 申請衍生設計專利，其申請日不得早於原設計之申請日 之檢核移到save_process_page
*/

  procedure add_error_message(p_key in varchar2, p_message in varchar2)
  --============--
    --新增錯誤訊息--
    --============--
   is
  begin
    g_out_message_array.extend;
    g_out_message_array(g_out_message_array.last) := pair_obj(p_key,
                                                              p_message);
  end add_error_message;
begin

  begin
    begin
      select appl_no, type_no
        into v_appl_no, v_type_no
        from spt21
       where receive_no = p_no;
    exception
      when no_data_found then
        v_appl_no := p_no;
    end;
    select appl_date, re_appl_date
      into v_appl_date, v_re_appl_date
      from spt31
     where appl_no = v_appl_no;
    select step_code
      into v_step_code
      from spt31a
     where appl_no = v_appl_no;
  exception
    when no_data_found then
      add_error_message('', '查無資料，WF_CHECK失敗');
      return g_out_message_array;
  end;

  if substr(v_appl_no, 4, 1) = '1' and
     p_process_result in ('43199', '43191', '41001', '43001') then
    add_error_message('PROCESS_RESULT',
                      '發明案不可輸入43199、43191、41001、43001');
  end if;
  if substr(v_appl_no, 4, 1) = '2' and
     p_process_result in ('49201', '49213', '43001') then
    add_error_message('PROCESS_RESULT',
                      '新型案不可輸入49201、49213、43001');
  end if;
  if substr(v_appl_no, 4, 1) = '3' and
     p_process_result in ('49201', '49213', '43191', '43199') then
    add_error_message('PROCESS_RESULT',
                      '設計、衍生設計案不可輸入49201、49213、43191、43199');
  end if;

  if substr(v_appl_no, 4, 1) = '3' and v_type_no = '10007' then
  
    declare
      v_notice_date spmf1.notice_date%type;
    begin
      select notice_date
        into v_notice_date
        from spmf1
       where appl_no = v_appl_no;
      if valid_tw_date(v_notice_date) and valid_tw_date(p_appl_date) then
        if v_notice_date < p_appl_date and
           p_process_result in ('43001', '43009', '43015') then
          add_error_message('PROCESS_RESULT', '不可輸入43001,43009,43015');
        end if;
      end if;
    exception
      when no_data_found then
        null;
    end;
  end if;

  if p_process_result = '43011' then
    select count(1)
      into v_tmp_count
      from spt21
     where appl_no = v_appl_no
       and type_no in ('16000', '16002', '24060', '24062');
    if v_tmp_count = 0 then
      add_error_message('PROCESS_RESULT',
                        '此案件未收過更正案相關收文案由(16000、16002、24060、24062)【辦理結果】不可為43011(通知更正事件進行審查)');
    end if;
  end if;

  if p_process_result = '42101' then
    select count(1)
      into v_tmp_count
      from spt21
     where appl_no = v_appl_no
       and type_no = '10010';
    if v_tmp_count = 0 then
      add_error_message('PROCESS_RESULT',
                        '該申請案需收過10010(撤回專利申請)方可填入42101(撤回申請案通知函)辦理，請通知收文人員修改案由或輸入其它辦理結果');
    end if;
  end if;

  if p_process_result in ('49247', '49249') then
    if p_appl_exam_flag = c_yes then
      add_error_message('APPL_EXAM_FLAG',
                        '此辦理結果不得有申請實體審查註記，請將「申請實體審查」選項去除!!');
    end if;
    if p_appl_priority_exam_flag = c_yes then
      add_error_message('APPL_PRIORITY_EXAM_FLAG',
                        '此辦理結果不得有申請實體審查與優先審查註記，請將「申請實體審查與優先審查」選項去除!!');
    end if;
  end if;

  if v_type_no is not null then
    --有收文資料
    if p_process_result in ('41001',
                            '41003',
                            '41011',
                            '41505',
                            '41515',
                            '40009',
                            '40001',
                            '40003',
                            '40005',
                            '40007',
                            '40011',
                            '40013',
                            '40301',
                            '41005',
                            '41007',
                            '41025',
                            '41027',
                            '49201',
                            '49203',
                            '49205',
                            '49239',
                            '49251',
                            '49241',
                            '49261',
                            '49263',
                            '41071') then
      if p_pre_exam_date is null and p_pre_exam_qty is null then
        if nvl(p_is_from_page, 'N') = 'Y' 
            and substr(p_no, 4, 1) = '3'
             then
          --skip check
          null;
        else
          add_error_message('PRE_EXAM_DATE',
                          '補正期限或補正日數，需擇一輸入');
        end if;
      end if;
      if p_pre_exam_date is not null then
        if not valid_tw_date(p_pre_exam_date) then
          add_error_message('PRE_EXAM_DATE', '補正期限格式不正確');
        elsif p_pre_exam_date < (to_char(sysdate, 'yyyymmdd') - 19110000) then
          add_error_message('PRE_EXAM_DATE', '補正期限小於系統日');
        end if;
      end if;
      if p_pre_exam_qty is not null then
        if p_pre_exam_qty > 99 then
          add_error_message('PRE_EXAM_QTY', '補正日數格式不正確');
        end if;
      end if;
    end if;
  end if;

  if p_process_result in ('49213',
                          '49215',
                          '49217',
                          '49269',
                          '43191',
                          '43199',
                          '43001',
                          '43009',
                          '43015') then
    select count(1)
      into v_tmp_count
      from spm11
     where (nvl(trim(national_id), '90') = '90' or trim(name_c) is null)
       and appl_no = v_appl_no;
    if v_tmp_count > 0 then
      add_error_message('PROCESS_RESULT',
                        '本案申請人或發明人國籍狀態為容後補呈，不可作齊備！');
    end if;
  end if;

  if p_process_result in ('43001', '49207', '49213') then
    select count(1)
      into v_tmp_count
      from spm11
     where id_type in ('1', '2')
       and id_no = 'P800138717'
       and appl_no = v_appl_no;
    if v_tmp_count > 0 then
      add_error_message('PROCESS_RESULT',
                        '本案之基本資料中有P800138717(容後補呈)之人名ID！不允許製稿。');
    end if;
  end if;

  if p_process_result in ('43001',
                          '42003',
                          '42101',
                          '49207',
                          '49213',
                          '49249',
                          '41001',
                          '49243',
                          '43191',
                          '43199') and
     not (10 <= v_step_code and v_step_code < 29) then
    add_error_message('PROCESS_RESULT',
                      '此辦理結果與案件階段別不符，請確認辦理結果是否正確');
  end if;

  if p_process_result in ('43003', '42007', '42103', '41003') then
    if not (30 <= v_step_code and v_step_code < 49) then
      add_error_message('PROCESS_RESULT',
                        '此辦理結果與案件階段別不符,請確認辦理結果是否正確');
    end if;
    if trim(v_re_appl_date) is null then
      add_error_message('', '此案無再審申請日期,無法製稿');
    end if;
  end if;

  if p_process_result in
     ('43007', '42015', '42107', '41011', '41505', '41515') and
     not (70 <= v_step_code and v_step_code < 89) then
    add_error_message('PROCESS_RESULT',
                      '此辦理結果與案件階段別不符，請確認辦理結果是否正確');
  end if;

  if p_process_result = '57001' then
    add_error_message('PROCESS_RESULT', '辦理結果不可為57001');
  end if;
  
  if p_process_result in (
      '49213', '49215', '49217', '49269', '49271', '43191', '43199', '43001', '43003') then
    select count(1)
      into v_tmp_count
      from spt31
     where appl_no = v_appl_no
       and nvl(trim(back_code), 'N') != 'N';
    if v_tmp_count > 0 then
      add_error_message('PROCESS_RESULT', '本案已註記撤回');
    end if;
  end if;
  return g_out_message_array;
end wf_check;

/
