--------------------------------------------------------
--  DDL for Procedure SAVE_GRACE_PERIOD
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SAVE_GRACE_PERIOD" (
  p_in_appl_no in char,
  p_in_grace_period_array in grace_period_tab
)
is
  v_tmp_grace_period grace_period_obj;
begin
  delete spt31l where appl_no = p_in_appl_no;
  if p_in_grace_period_array is null
      or p_in_grace_period_array.count = 0 then
    return;
  end if;
  for l_idx in p_in_grace_period_array.first .. p_in_grace_period_array.last
  loop
    v_tmp_grace_period := p_in_grace_period_array(l_idx);
    if v_tmp_grace_period.appl_no is null or v_tmp_grace_period.data_seq is null then
      continue;
    end if;
    insert into spt31l
    (
      appl_no, 
      data_seq, 
      sort_id,
      novel_flag,
      novel_item,
      novel_date
    ) values (
      v_tmp_grace_period.appl_no,
      v_tmp_grace_period.data_seq,
      v_tmp_grace_period.data_seq,
      v_tmp_grace_period.novel_flag,
      v_tmp_grace_period.novel_item,
      v_tmp_grace_period.novel_date
    );
  end loop;
end save_grace_period;

/
