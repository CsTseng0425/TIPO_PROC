--------------------------------------------------------
--  DDL for Procedure RECEIVE_RESET_APPLNO
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."RECEIVE_RESET_APPLNO" (
  p_receive_no in char,
  p_new_appl_no in char,
  p_pre_appl_no out char
)
is
  v_now_appl_no receive.appl_no%type;
begin
  select appl_no
    into v_now_appl_no
    from receive
   where receive_no = p_receive_no;
  
  update doc
     set appl_no = p_new_appl_no,
         modify_time = systimestamp
   where appl_no = v_now_appl_no
     and receive_no = p_receive_no;
  
  update receive
     set appl_no = p_new_appl_no,
         doc_complete = '0'
   where receive_no = p_receive_no;
   
  merge into appl_receive a
  using (select p_receive_no as receive_no from dual) b
     on (trim(a.receive_no) = trim(b.receive_no))
   when matched then
        update set 
        a.new_appl_no = p_new_appl_no, 
        a.processor_no = get_loginuser,
        a.updatetime = systimestamp
   when not matched then
        insert 
        (a.receive_no, a.old_appl_no, a.new_appl_no, a.processor_no, a.updatetime)
        values 
        (p_receive_no, v_now_appl_no, p_new_appl_no, get_loginuser, systimestamp);
   
  p_pre_appl_no := v_now_appl_no;
end receive_reset_applno;

/
