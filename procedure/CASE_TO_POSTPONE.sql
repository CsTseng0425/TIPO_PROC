--------------------------------------------------------
--  DDL for Procedure CASE_TO_POSTPONE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CASE_TO_POSTPONE" (p_in_receive_no in char,
                                             p_postpone      in char,
                                             p_reason        in varchar2,
                                             p_out_msg       out varchar2) is
  v_count      number;
  v_validation varchar2(100);
  v_appl_no    spt21.appl_no%type;

begin
  /*
  MOdify : 104/10/08
  Update receive.is_postpone =1:单ㄓゅ2:单砏禣3:单瓜郎4:ㄤウ  
  Modify Item:
  (1) check if data exist in para ,use update  or  insert
  */

  
  if p_postpone = '3' then
    update receive set is_postpone = p_postpone , post_reason =  p_reason ,  doc_complete = '0'  
    where receive_no = p_in_receive_no;
 else
    update receive set is_postpone = p_postpone , post_reason =  p_reason 
    where receive_no = p_in_receive_no;
 end if;

  select count(1) into v_count
  from appl_para
  where sys = 'POSTPONE' and trim(subsys) = trim(p_in_receive_no);
  
  if v_count = 0 then 
      insert into appl_para   (sys, subsys, para_no)
        values  ('POSTPONE', p_in_receive_no, to_char(sysdate, 'yyyyMMdd'));
   else
      update appl_para set para_no = to_char(sysdate, 'yyyyMMdd') where sys = 'POSTPONE' and subsys = p_in_receive_no; 
   end if;

  p_out_msg := p_in_receive_no || ' 絯快Θ';

end CASE_TO_POSTPONE;

/
