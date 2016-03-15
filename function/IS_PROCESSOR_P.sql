--------------------------------------------------------
--  DDL for Function IS_PROCESSOR_P
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."IS_PROCESSOR_P" (p_no in varchar2)
  return number is
  v_flag number :=0;
begin
  select case when supervisor_no is not null then 1 else 0 end into v_flag   
  From AUTHORITY
  Where trim(processor_no)=p_no
  ;
  return v_flag;
exception
  when no_data_found 
  then
  if substr(p_no,1,1)='P' then
    return 1;--外包
  end if;
  if substr(p_no,1,1) > '1' then
    return -1;--其他
  end if;
  return 0;--審查官
end IS_PROCESSOR_P;

/
