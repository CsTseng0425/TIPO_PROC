--------------------------------------------------------
--  DDL for Function CHECK_MANAGER
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."CHECK_MANAGER" (p_dept_no in char,p_processor_no in char)
return char
is
  l_mgr number;
begin
/*
  Desc: check department manager
  ModifyDate: 104/08/19
  
*/
 
  select checker into l_mgr from ap.spm72 where processor_no = p_processor_no and dept_no = p_dept_no;
  
 -- if l_mgr is null then
--      select processor_no from ap.spm6g1 where dept_no = '70012' and primary_flag = '1';
 -- end if;

  if l_mgr is null then
     select processor_no  into l_mgr from spm63 where dept_no = '70012' and title = '¬ìªø' and rownum =1;
   end if;
   
   return l_mgr;
exception
  when others then
    return 0;
end CHECK_MANAGER;

/
