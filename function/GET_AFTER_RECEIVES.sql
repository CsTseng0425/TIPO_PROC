--------------------------------------------------------
--  DDL for Function GET_AFTER_RECEIVES
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."GET_AFTER_RECEIVES" (
  p_receive_no in char)
return after_receive_tab
is
  v_after_receive_tab after_receive_tab;
begin
/*
Desc: get after receives list 
Last ModifyDate :104/11/26
ModifyItem:
104/07/21 : list these receive  which  not limit the after the master reiceve , list those have in the same appl
104/07/24: change type_no to type_no || type_name
104/11/19: 增加判斷線上註記
104/11/26: 增加判斷 spt21.process_result is null
 105/02/04: change condtion to judge if the receive is paper type:cancel condition :receive.step_code is null
*/
  select after_receive_obj(
           receive_no,
           processor_no,
           processor_name,
           type_no,
           type_name,
           step_code,
           merge_master
         )
    bulk collect
    into v_after_receive_tab
    from (
      select spt21.receive_no,
             spt21.processor_no,
             (select spm63.name_c from spm63 where spm63.processor_no = spt21.processor_no) as processor_name,
             spt21.type_no,
             (select type_name from spm75 where spm75.type_no = spt21.type_no) as type_name,
             case when spt21.online_flg='N' then null when  receive.step_code in ('2','3') then   '2'  else  receive.step_code end step_code,
            --receive.step_code ,
             receive.merge_master
        from spt21
        left join receive on spt21.receive_no = receive.receive_no
       where spt21.receive_no != p_receive_no
         and spt21.appl_no = (select appl_no from receive where receive_no = p_receive_no)
         and spt21.process_result is null
         and (( receive.step_code in ('0', '2','3') and spt21.online_flg = 'Y'   )
              or
             ( spt21.online_flg='N' )
               or receive.merge_master is not null
             )
         and spt21.type_no not in ('22304', '22322', '24700', '24702', '22312', '22314')
       order by receive_no
    );
  return v_after_receive_tab;
end get_after_receives;

/
