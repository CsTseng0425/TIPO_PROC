--------------------------------------------------------
--  DDL for Procedure SAVE_PRIORITY_RIGHT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SAVE_PRIORITY_RIGHT" (
  p_in_appl_no in char,
  p_in_process_result in char,
  p_in_priority_right_array in priority_right_tab,
  p_io_warn_message_array in out nocopy varchar2_tab
)
is
/*
  desc: save priority data
  date: 105/02/19
  105/02/19: 檢核優先權案號之申請人中文名稱與本案是否相同，只要人數或其中一人名不同出現警示訊息  
*/
  v_tmp_priority_right priority_right_obj;
  
  procedure add_warn_message(p_message in varchar2)
  is
  begin
    p_io_warn_message_array.extend;
    p_io_warn_message_array(p_io_warn_message_array.last) := p_message;
  end add_warn_message;
begin
  delete spt32 where appl_no = p_in_appl_no;
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
    -- 改由前端檢核,提供確定及取消按鈕
    /*
     if p_in_process_result in ('49213','49215','49217','43191','43199') and v_tmp_priority_right.priority_nation_id = 'TW' then
        declare 
          l_rec_m number;
          l_rec_c number;
          l_same number;
        begin
          l_rec_m := 0;
          l_rec_c := 0;
          l_same := 0;
            
           select count(1) into l_rec_m  FROM AP.SPM11
            WHERE SPM11.ID_TYPE = '1'
            and trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no)    
            ;
           
            select count(1) into l_rec_c FROM AP.SPM11
            WHERE SPM11.ID_TYPE = '1'
            and appl_no = v_tmp_priority_right.appl_no
            ;
          
          select count(1) into l_same
          from 
          (
            select name_c  FROM AP.SPM11
            WHERE SPM11.ID_TYPE = '1'
            and trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no)    
          ) a
           join 
          (
            select name_c FROM AP.SPM11
            WHERE SPM11.ID_TYPE = '1'
            and appl_no = v_tmp_priority_right.appl_no
          ) b on a.name_c = b.name_c
          ;
          
           if l_rec_m <> l_rec_c or l_same <> l_rec_m then
                add_warn_message('國內外優先權資料(' || l_idx || ')國內優先權基礎案申請人與本案不同，請確認');
           end if;
        
        end;
      end if;
   */
      
    if p_in_process_result in (
        '43001', '43003', '43007', '43009', '43011', '43015', '43023', '43025', '43191', '43199',
        '49207', '49209', '49211', '49243', '49247', '49265', '49267', '49213', '49215', '49217',
        '49269', '49271', '49201') and v_tmp_priority_right.priority_nation_id = 'TW' then
      declare
        l_step_code      spt31b.step_code%type;
        l_step_code1     spt31a.step_code1%type;
        l_back_code      spt31.back_code%type;
        l_count          number;
        l_re_appl_date   spt31.re_appl_date%type;
        l_f_apl_exm_rslt spt31.f_apl_exm_rslt%type;
        l_r_apl_exm_rslt spt31.r_apl_exm_rslt%type;
        l_ipc_group_no   spt31a.ipc_group_no%type;
        l_material_code  spt31b.material_code%type;
      begin
      
        select step_code 
          into l_step_code 
          from spt31b
         where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
        select back_code 
          into l_back_code 
          from spt31 
         where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
         
         
        if v_tmp_priority_right.priority_flag = '1' and nvl(trim(l_back_code), '1') = '1' then
          update spt31
             set back_code = '2'
           where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
          if l_step_code in ('10', '20', '30', '40', '50', 'AA', 'BB', 'CC', 'DD', 'EE') then
            l_step_code := '70';
            update spt31b 
               set step_code = l_step_code 
             where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
          end if;
          
          select step_code 
            into l_step_code1
            from spt31a
           where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
         --   add_warn_message('l_step_code1 =' ||l_step_code1 );
          if l_step_code1 <> '99' then
            select count(issue_type) 
              into l_count 
              from spt41 
             where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no)
               and issue_type in ('56001', '56003', '56005', '56007', '56097', '56099')
               and nvl(file_d_flag, '_') <> '9';
            if l_count = 0 then
              update spt31a 
                 set step_code = '99',
                     step_code1 = l_step_code1
               where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
            end if;
          end if;
        elsif v_tmp_priority_right.priority_flag = '2' then
          if nvl(trim(l_back_code), '2') = '2' then
          
            select count(1) 
              into l_count
              from spt32  
             where trim(priority_appl_no) = trim(v_tmp_priority_right.priority_appl_no)
               and appl_no <> p_in_appl_no
               and priority_nation_id = 'TW'
               and priority_flag = '1';
              --  add_warn_message('l_count =' ||l_count );
            if l_count = 0 then
              update spt31 
                 set back_code = ''
               where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
              if l_step_code in ('AA', 'BB', 'CC', 'DD', 'EE' ,'FF') then
                update spt31b 
                   set step_code = case l_step_code 
                                     when 'AA' then '10' 
                                     when 'BB' then '20'
                                     when 'CC' then '30'
                                     when 'DD' then '40'
                                     when 'EE' then '50'
                                     when 'FF' then '60'
                                     else step_code
                                    end
                 where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
              end if;
              select count(1) 
                into l_count
                from spt32  
               where trim(priority_appl_no) = trim(v_tmp_priority_right.priority_appl_no)
                 and priority_flag = '1';
                --  add_warn_message('l_count='|| l_count);
              if l_count <= 1 then
                select step_code1 
                  into l_step_code
                  from spt31a
                 where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
                -- add_warn_message('l_step_code='|| l_step_code);
                l_step_code := trim(l_step_code);
                if l_step_code is not null then
                  update spt31a
                     set step_code = l_step_code,
                         step_code1 = ''
                   where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
                else
                  select trim(re_appl_date), trim(f_apl_exm_rslt), trim(r_apl_exm_rslt)
                    into l_re_appl_date , l_f_apl_exm_rslt , l_r_apl_exm_rslt
                    from spt31  
                   where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
                  select ipc_group_no  
                    into l_ipc_group_no
                    from spt31a  
                   where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
                  select material_code  
                    into l_material_code  
                    from spt31b  
                   where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
                  if l_ipc_group_no = '70012' then
                    if l_re_appl_date is not null then
                      if length(trim(v_tmp_priority_right.priority_appl_no)) = 10 and l_r_apl_exm_rslt is not null then
                        l_step_code := '49';
                      else
                        if l_material_code is not null then
                          l_step_code := '36';
                        else
                          l_step_code := '30';
                        end if;
                      end if;
                    else
                      if length(trim(v_tmp_priority_right.priority_appl_no)) = 10 and l_f_apl_exm_rslt is not null then
                         l_step_code := '29';
                      else
                        if l_material_code is not null then
                          l_step_code := '16';
                        else
                          l_step_code := '10';
                        end if;
                      end if;
                    end if;
                  elsif l_ipc_group_no in ('70013', '70014', '70015', '70016', '70021', '70022', '70023', '70024', '70025', '70026', '70027') then
                    if length(trim(v_tmp_priority_right.priority_appl_no)) = 10 and l_f_apl_exm_rslt is not null then
                      l_step_code := '29';
                    else
                      l_step_code := '20';
                    end if;
                  elsif l_ipc_group_no in ('70031', '70032', '70033', '70034', '70035') then
                    if length(trim(v_tmp_priority_right.priority_appl_no)) = 10 and l_r_apl_exm_rslt is not null then
                      l_step_code := '49';
                    else
                      l_step_code := '40';
                    end if;
                  elsif l_ipc_group_no = '70019' then
                    l_step_code := '15';
                  elsif l_ipc_group_no = '60037' then
                    l_step_code := '10';
                  end if;
                  if l_step_code is not null then
                    update spt31a  
                       set step_code = l_step_code,
                           step_code1 = ''
                     where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
                  else
                    add_warn_message('更新被主張優先權申請案號' || v_tmp_priority_right.priority_appl_no || '之階段別有誤(階段別為空值)，請聯絡資訊室協助處理!');
                  end if;
                end if;
              end if;
            end if;
          else
            case l_back_code
              when '1' then add_warn_message('被主張優先權申請案號' || v_tmp_priority_right.priority_appl_no || '已申請撤回，案件階段別未回復為審查中，請確認!');
              when '3' then add_warn_message('被主張優先權申請案號' || v_tmp_priority_right.priority_appl_no || '為申請案視為撤回，案件階段別未回復為審查中，請確認!');
              when '4' then add_warn_message('被主張優先權申請案號' || v_tmp_priority_right.priority_appl_no || '為改請案視為撤回，案件階段別未回復為審查中，請確認!');
              when '5' then add_warn_message('被主張優先權申請案號' || v_tmp_priority_right.priority_appl_no || '為分割案視為撤回，案件階段別未回復為審查中，請確認!');
              when '6' then add_warn_message('被主張優先權申請案號' || v_tmp_priority_right.priority_appl_no || '為15個月後申請撤回，案件階段別未回復為審查中，請確認!');
              when '8' then add_warn_message('被主張優先權申請案號' || v_tmp_priority_right.priority_appl_no || '為申請案不受理，案件階段別未回復為審查中，請確認!');
              when '9' then add_warn_message('被主張優先權申請案號' || v_tmp_priority_right.priority_appl_no || '已逾三年未申請實體審查(視為撤回)，案件階段別未回復為審查中，請確認!');
            end case;
          end if;
        end if;
      exception
        when no_data_found then null;--不處理
      end;
    end if;
      
    insert into spt32
    (
      appl_no,
      data_seq,
      priority_date,
      priority_nation_id,
      priority_appl_no,
      priority_flag,
      priority_revive,
      priority_doc_flag,
      access_code,
      ip_type,
      elec_trans
    ) values (
      v_tmp_priority_right.appl_no,
      v_tmp_priority_right.data_seq,
      v_tmp_priority_right.priority_date,
      v_tmp_priority_right.priority_nation_id,
      v_tmp_priority_right.priority_appl_no,
      v_tmp_priority_right.priority_flag,
      v_tmp_priority_right.priority_revive,
      v_tmp_priority_right.priority_doc_flag,
      v_tmp_priority_right.access_code,
      v_tmp_priority_right.ip_type,
      v_tmp_priority_right.elec_trans
    );
  end loop;
end save_priority_right;

/
