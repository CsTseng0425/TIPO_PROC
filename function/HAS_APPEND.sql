--------------------------------------------------------
--  DDL for Function HAS_APPEND
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."HAS_APPEND" (p_receive_no in char)
  return varchar2 is

  v_count number;
begin
     /*
      Modifydate:  104/11/26
      Desc: judge whither has post receive
      para: return 1 : 有後續文,未領辦
            return 2 : 有後續文,已領辦
      104/11/19: 增加判斷線上註記
      104/11/26: 增加判斷 spt21.process_result is null
      105/02/04: change condtion to judge if the receive is paper type: spt21.online_flg = 'N'
     */
  v_count := 0;
     

     select count(1)
      into v_count
      from spt21 left join receive 
        on receive.receive_no = spt21.receive_no
     where spt21.receive_no > p_receive_no
       and spt21.appl_no = (select appl_no from receive where receive_no = p_receive_no)
       and spt21.process_result is null
       and ((receive.step_code = '0' and spt21.online_flg='Y' and merge_master is null) or (spt21.online_flg='N' ))
       and spt21.type_no not in ('22304', '22322', '24700', '24702', '22312', '22314');
    
   if v_count > 0 then 
     return '1';
   end if ;
    
    v_count := 0;
     select  count(1)
    into v_count
    from receive  join spt21 on receive.receive_no = spt21.receive_no
   where receive.receive_no != p_receive_no
   and spt21.appl_no = (select appl_no from receive where receive_no = p_receive_no)
   and receive.step_code = '2'
   and spt21.process_result is null
   and spt21.online_flg = 'Y'
   and merge_master is null
   and receive.processor_no = ( select processor_no from receive r where receive_no = p_receive_no)
   and type_no not in ('22304', '22322', '24700', '24702', '22312', '22314')
    ;
    
    if v_count > 0 then 
     return '2';
    end if ;
    
 dbms_output.put_line(v_count);
    
    return '0';

end HAS_APPEND;

/
