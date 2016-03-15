--------------------------------------------------------
--  DDL for Function CHECK_APPL_PROCESSOR
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."CHECK_APPL_PROCESSOR" (p_appl_no in char,p_processor_no in char)
return number
is
  v_count number;
begin
/*
  Desc: check if having right to operate the project 
  ModifyDate: 104/07/23
  
*/
 
  select count(1) into v_count
  from 
   (
      select processor_no from spt21 where appl_no = p_appl_no and processor_no = p_processor_no
      union all
      select processor_no from appl where appl_no = p_appl_no and processor_no = p_processor_no
    )
    ;
    if v_count > 0 then 
        return 1;
    else
        return 0;
    end if;
exception
  when others then
    return 0;
end CHECK_APPL_PROCESSOR;

/
