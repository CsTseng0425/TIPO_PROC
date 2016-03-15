--------------------------------------------------------
--  DDL for Function BATCH_HAS_APPEND
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."BATCH_HAS_APPEND" (p_appl_no in char)
  return varchar2 is

  v_count number;
begin
     /*
      Modifydate:  104/11/26
      Desc: judge whither has post receive
      104/11/26: ¼W¥[§PÂ_ spt21.process_result is null
      105/02/04: change condtion to judge if the receive is paper type: spt21.online_flg = 'N'
     */
     
  select  count(1)
    into v_count
    from batch_detail bd
  where (bd.appl_no) = p_appl_no
  and  Bd.Is_Rejected = '0'
  and bd.batch_seq = (select max(batch_seq) from batch_detail where batch_detail.batch_no = bd.batch_no)
  and exists
    (select 1 from spt21 left join receive on receive.receive_no = spt21.receive_no
                                    where spt21.appl_no =  bd.appl_no and spt21.receive_no != bd.receive_no
                                    and spt21.process_result is null
                                    and ( (receive.step_code in ('0','2') and merge_master is null and spt21.online_flg = 'Y' ) or ( spt21.online_flg = 'N' ))
                                    and spt21.type_no not in ('22304', '22322', '24700', '24702', '22312', '22314')
                                    )
    ;
 dbms_output.put_line(v_count);
  if v_count > 0 then
    return '1';
  else
    return '0';
  end if;

end batch_has_append;

/
