--------------------------------------------------------
--  DDL for Procedure SAVE_BIOMATERIAL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SAVE_BIOMATERIAL" (
  p_in_appl_no in char,
  p_in_biomaterial_array in biomaterial_tab
)
is
  v_tmp_biomaterial biomaterial_obj;
begin
  delete spt33 where appl_no = p_in_appl_no;
  if p_in_biomaterial_array is null
      or p_in_biomaterial_array.count = 0 then
    return;
  end if;
  for l_idx in p_in_biomaterial_array.first .. p_in_biomaterial_array.last
  loop
    v_tmp_biomaterial := p_in_biomaterial_array(l_idx);
    if v_tmp_biomaterial.appl_no is null or v_tmp_biomaterial.data_seq is null then
      continue;
    end if;
    insert into spt33
    (
      appl_no,
      data_seq,
      microbe_date,
      microbe_org_id,
      microbe_appl_no,
      national_id,
      microbe_org_name
    ) values (
      v_tmp_biomaterial.appl_no,
      v_tmp_biomaterial.data_seq,
      v_tmp_biomaterial.microbe_date,
      v_tmp_biomaterial.microbe_org_id,
      v_tmp_biomaterial.microbe_appl_no,
      v_tmp_biomaterial.national_id,
      v_tmp_biomaterial.microbe_org_name
    );
  end loop;
end save_biomaterial;

/
