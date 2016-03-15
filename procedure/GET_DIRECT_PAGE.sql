--------------------------------------------------------
--  DDL for Procedure GET_DIRECT_PAGE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."GET_DIRECT_PAGE" (
  p_in_appl_no in spt31.appl_no%type,
  p_in_processor_no in char,
  p_out_direct_info_map out pair_tab,
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
  
  procedure add_direct_info_map(p_key in varchar2, p_value in varchar2, p_auto_trim in boolean default true)
  is
  begin
    p_out_direct_info_map.extend;
    if p_auto_trim then
      p_out_direct_info_map(p_out_direct_info_map.last) := pair_obj(p_key, trim(p_value));
    else
      p_out_direct_info_map(p_out_direct_info_map.last) := pair_obj(p_key, p_value);
    end if;
  end add_direct_info_map;
  
  procedure add_message(p_message in varchar2)
  is
  begin
    p_out_message_array.extend;
    p_out_message_array(p_out_message_array.last) := p_message;
  end add_message;
  
  procedure check_readonly
  is
  begin
    if check_appl_processor(p_in_appl_no, p_in_processor_no) = 0 then
      p_out_readonly_message := '非承辦之文件不能辦理';
      return;
    end if;
    declare
      v_step_code spt31a.step_code%type;
    begin
      select step_code
        into v_step_code
        from spt31a
       where appl_no = p_in_appl_no;
     -- if 15 <= v_step_code and v_step_code <= 20 then
     -- /* 瑕疵單指的案件階段別20 ,應是指早期公開階段別(spt31b),故此處只需判斷 spt31a.step_cdpe = 15 */
      if  v_step_code = 15 then
        p_out_readonly_message := '案件已進早期公開，不可辦理';
      end if;
    exception
      when others then null;
    end;
  end check_readonly;
begin
  p_out_direct_info_map := pair_tab();
  p_out_message_array := varchar2_tab();
  p_out_success := 'Y';

  declare
    v_appl_no            spt31.appl_no%type;
    v_appl_date          spt31.appl_date%type;
    v_patent_name_c      spt31.patent_name_c%type;
    v_foreign_language   spt31.foreign_language%type;
    v_twis_flag          spt31.twis_flag%type;
    v_material_appl_date spt31.material_appl_date%type;
    v_name_c             spm63.name_c%type;
  begin
    select a.appl_no, a.appl_date, a.patent_name_c, a.foreign_language, a.twis_flag, a.material_appl_date, b.name_c
      into v_appl_no, v_appl_date, v_patent_name_c, v_foreign_language, v_twis_flag, v_material_appl_date, v_name_c
      from spt31 a, spm63 b
     where a.appl_no = p_in_appl_no
       and a.sch_processor_no = b.processor_no(+);
    add_direct_info_map('APPL_NO', v_appl_no);
    add_direct_info_map('APPL_DATE', v_appl_date);
    add_direct_info_map('PATENT_NAME_C', v_patent_name_c);
    add_direct_info_map('FOREIGN_LANGUAGE', v_foreign_language);
    add_direct_info_map('TWIS_FLAG', v_twis_flag);
    add_direct_info_map('MATERIAL_APPL_DATE', v_material_appl_date);
    add_direct_info_map('NAME_C', v_name_c);
  exception
    when no_data_found then
      p_out_success := 'N';
      add_message('無原案件資料(SPT31)，請查明之');
  end;
  
  declare
    v_material_code spt31b.material_code%type;
    v_priority_code spt31b.priority_code%type;
  begin
    select a.material_code, a.priority_code 
      into v_material_code, v_priority_code
      from spt31b a
     where appl_no = p_in_appl_no;
    if v_material_code = '10' and nvl(v_priority_code, '_') <> '10'then
      add_direct_info_map('APPL_EXAM_FLAG', c_yes);
    end if;
    if v_priority_code = '10' then
	    add_direct_info_map('APPL_PRIORITY_EXAM_FLAG', c_yes);
    end if;
  exception
    when no_data_found then null;
  end;

  declare
    v_annex_code appl.pre_exam_list%type;
    v_annex_desc appl50.annex_desc%type;
  begin
    get_annex(p_in_appl_no, 'Y', v_annex_code, v_annex_desc);
    add_direct_info_map('ANNEX_CODE', v_annex_code);
    add_direct_info_map('ANNEX_DESC', v_annex_desc);
  end;
  
  declare
    v_spt21c_receive_no varchar2(15 char);
  begin
    select decode(type, '1', receive_no, '人工整檔')
      into v_spt21c_receive_no
      from spt21c
     where appl_no = p_in_appl_no;
    add_direct_info_map('SPT21C_RECEIVE_NO', v_spt21c_receive_no);
  exception
    when no_data_found then null;
  end;
  
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
   where appl_no = p_in_appl_no;

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
          := get_response_status(p_in_appl_no, p_out_priority_right_array(l_idx).access_code);
      end loop;
    end;
  end if;
  
  if substr(p_in_appl_no, 4, 1) not in ('2', '3') then
    select biomaterial_obj(
             appl_no,         data_seq,    microbe_date,     microbe_org_id,
             microbe_appl_no, national_id, microbe_org_name
           )
      bulk collect
      into p_out_biomaterial_array
      from spt33
     where appl_no = p_in_appl_no
     order by data_seq;
  end if;
  
  select grace_period_obj(
           appl_no, data_seq, novel_flag, novel_item, novel_date, sort_id
         )
    bulk collect
    into p_out_grace_period_array
    from spt31l
   where appl_no = p_in_appl_no
   order by sort_id;
   
  select appl_seq || '#' || status || '#' || process_result 
    bulk collect
    into p_out_request_item_array
    from ap.spt31w
   where appl_no = p_in_appl_no;
  
  if p_out_success = 'Y' then
    check_readonly;
  end if;
  
end get_direct_page;

/
