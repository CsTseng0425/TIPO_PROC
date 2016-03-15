--------------------------------------------------------
--  DDL for Procedure SAVE_MATERIAL_APPL_DATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SAVE_MATERIAL_APPL_DATE" (
  p_in_appl_no in char,
  p_in_receive_no in char,
  p_in_appl_exam_flag in char,
  p_in_appl_priority_exam_flag in char
)
is
  c_yes                       constant char(1) := '1';
  v_count_spt31f              number;
  v_tmp_receive_no            spt31f.receive_no%type;
  v_tmp_receive_date          spt21.receive_date%type;
  v_origin_material_appl_date spt31.material_appl_date%type;
/*
desc: wf_material_appl_date
*/
begin
  if p_in_appl_exam_flag = c_yes or p_in_appl_priority_exam_flag = c_yes then
    select count('')
      into v_count_spt31f
      from spt31f
     where receive_no = p_in_receive_no
       and appl_no = p_in_appl_no
       and appl_flag  = '1';
    if v_count_spt31f > 0 then
      v_tmp_receive_no := p_in_receive_no;
    else
      begin
        select distinct receive_no
          into v_tmp_receive_no
          from spt31f
         where appl_no = p_in_appl_no
           and appl_flag = '1';
      exception
        when no_data_found then null;--不處理
      end;
    end if;
    select material_appl_date
      into v_origin_material_appl_date
      from spt31
     where appl_no = p_in_appl_no;
      SYS.Dbms_Output.Put_Line('v_origin_material_appl_date='||v_origin_material_appl_date);
    if nvl(v_tmp_receive_no, '_') != nvl(v_origin_material_appl_date, '_') then
      if v_tmp_receive_no is not null then
        begin
          select nvl(trim(postmark_date), receive_date)
            into v_tmp_receive_date
            from spt21
           where receive_no = v_tmp_receive_no;
           SYS.Dbms_Output.Put_Line('v_tmp_receive_date='||v_tmp_receive_date);
        exception
          when no_data_found then null;--不處理
        end;
      end if;
      update spt31
         set material_appl_date = v_tmp_receive_date
       where appl_no = p_in_appl_no;
    end if;
  end if;
end save_material_appl_date;

/
