--------------------------------------------------------
--  DDL for Procedure SAVE_APPL_EXAM
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SAVE_APPL_EXAM" (
  p_in_appl_no in char,
  p_in_receive_no in char,
  p_in_process_result in char,
  p_in_appl_exam_flag in char,
  p_in_appl_priority_exam_flag in char)
is
  c_yes                constant char(1) := '1';
  v_material_appl_date spt31.material_appl_date%type;
  v_step_code          spt31a.step_code%type;
/*
desc: 實體審查註記變更
date: 1050226
wait for spt31b insert privilege
*/
begin
  select material_appl_date
    into v_material_appl_date
    from spt31
   where appl_no = p_in_appl_no;
  select step_code
    into v_step_code
    from spt31a
   where appl_no = p_in_appl_no;
  if p_in_process_result in ('49259', '49245', '49255') then
    update spt31f
       set appl_flag = '2'
     where receive_no = p_in_receive_no;
  else
    if p_in_process_result = '49249' then
      update spt31f
         set appl_flag = '2'
       where spt31f.receive_no = p_in_receive_no;
    end if;
    if v_step_code < 29 then
      declare
        v_chk_flag       varchar2(2);
        v_material_code  varchar2(2);
        v_receive_date   spt21.receive_date%type;
        v_count_spt31b   number;
        v_count_spt31f   number;
        v_tmp_receive_no spt31f.receive_no%type;
        v_receive_no_31f         spt31f.receive_no%type;
        ll_count         number;
      begin
      -- org: function wf_spt31f_check
      -- some check coded in save_process_page
       SELECT distinct receive_no  into v_receive_no_31f
       FROM ap.spt31f  
       WHERE spt31f.appl_no = p_in_appl_no
       AND rownum =1;
  	
    
        if p_in_appl_exam_flag = c_yes then 
          v_chk_flag := '10';
          v_material_code := '10';
        end if;
        if p_in_appl_priority_exam_flag = c_yes then 
          v_chk_flag := '01';
          v_material_code := '10';
        end if; 
        if p_in_appl_exam_flag = c_yes 
          and p_in_appl_priority_exam_flag = c_yes then 
          v_chk_flag := '11';
          v_material_code := '10';
        end if;
        if p_in_process_result in ('49247', '49249') then 
          v_material_code := '20';
        end if;
        select nvl(trim(postmark_date), receive_date)
          into v_receive_date
          from spt21
         where receive_no = v_receive_no_31f;
        select count(1)
          into v_count_spt31b
          from spt31b
         where appl_no = p_in_appl_no;
         /* wf_check_31b_f */
        if v_count_spt31b = 0 then
      --    insert into ap.spt31b (appl_no, step_code) values (p_in_appl_no, '10');
         SYS.Dbms_Output.Put_Line('wait');
        end if;
        select count(1)
          into v_count_spt31f
          from spt31f
         where appl_no = p_in_appl_no
           and receive_no = v_receive_no_31f;
        if v_count_spt31f > 0 then
          if v_chk_flag is not null then
            update spt31f
               set appl_flag = ''
             where appl_no = p_in_appl_no
               and receive_no != v_receive_no_31f;
          end if;
          case v_chk_flag
            when '10' then
              update spt31f 
                 set appl_flag = '1'  
               where receive_no = v_receive_no_31f;
              update spt31b 
                 set data_date = v_receive_date,
                     material_code = v_material_code,
                     priority_code = ''
               where appl_no = p_in_appl_no;
            when '01' then
              update spt31f
                 set appl_flag = '1'
               where receive_no = v_receive_no_31f;
              update spt31b
                 set data_date = v_receive_date,
                     priority_code = '10',
                     material_code = v_material_code
               where appl_no = p_in_appl_no;
            when '11' then
              update spt31f
                 set appl_flag = '1' 
               where receive_no = v_receive_no_31f;
              update spt31b
                set data_date = v_receive_date,
                    priority_code = '10',
                    material_code = v_material_code
              where appl_no = p_in_appl_no;
            else
              select count(1)
                into v_count_spt31f
                from spt31f
               where appl_no = p_in_appl_no
                 and receive_no != v_receive_no_31f
                 and appl_flag = '1';
                  SYS.Dbms_Output.Put_Line('v_count_spt31f='||v_count_spt31f);
              if v_count_spt31f = 0 then
                update spt31f
                   set appl_flag = '' 
                 where receive_no = v_receive_no_31f;
                   SYS.Dbms_Output.Put_Line('v_receive_no_31f='||v_receive_no_31f);
                update spt31b 
                   set material_code = v_material_code,
                       priority_code = ''
                 where appl_no = p_in_appl_no;
                update spt31
                   set material_appl_date = ''
                 where appl_no = p_in_appl_no;
             elsif v_count_spt31f >= 1 then
                select trim(max(receive_no))
                  into v_tmp_receive_no
                  from spt31f
                 where appl_no = p_in_appl_no
                   and appl_flag = '1';
                update spt31f
                   set appl_flag = ''
                 where appl_no = p_in_appl_no
                   and receive_no != v_tmp_receive_no;
                select nvl(trim(postmark_date), receive_date)
                  into v_receive_date
                  from spt21
                 where receive_no = v_tmp_receive_no;
                               
                if nvl(v_material_appl_date, '_') <> nvl(v_receive_date, '_') then
                  update spt31
                     set material_appl_date = v_receive_date
                   where appl_no = p_in_appl_no;
                end if;
              --elsif v_count_spt31f > 1 then
                --null;--不實作
              end if;
          end case;
        end if;
      end;
    end if;
  end if;
--  commit;
exception
  when no_data_found then null;--不處理
end save_appl_exam;

/
