--------------------------------------------------------
--  DDL for Procedure SAVE_ANNEX
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SAVE_ANNEX" (
  p_in_appl_no in char,
  p_in_annex_code in char, 
  p_in_annex_desc in char
)
is
  v_options varchar2_tab;
begin
  v_options := get_revise_options(p_in_appl_no, 'Y');
  update appl set pre_exam_list = p_in_annex_code where appl_no = p_in_appl_no;
  delete appl50 where appl_no = p_in_appl_no;
  for l_idx in 1 .. v_options.count
  loop
    if substr(p_in_annex_code, l_idx, 1) = '1' and l_idx != 38 then
      insert into appl50 (appl_no, annex_desc, series_no) values (p_in_appl_no, v_options(l_idx), l_idx);
    end if;
  end loop;
  if p_in_annex_desc is not null then
    insert into appl50 (appl_no, annex_desc, series_no) values (p_in_appl_no, p_in_annex_desc, 38);
  end if;
end save_annex;

/
