--------------------------------------------------------
--  DDL for Function GET_PRE_DATE
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."GET_PRE_DATE" (p_appl_no in varchar2)
return varchar2
is
  v_pre_data varchar2(7):=null;
  v_tmp_date date:=null;
begin
  
  select pre_date into v_pre_data from spt31b where trim(appl_no)= trim(p_appl_no) and pre_date is not null;
  if(v_pre_data is not null) then 
    DBMS_OUTPUT.PUT_LINE('appl_no='||p_appl_no||' v_pre_data='||v_pre_data);
    return v_pre_data; 
  end if;
  
  select greatest(least(nvl(appl_date,priority_date),nvl(priority_date,appl_date))+1,MIN_DATE) into v_tmp_date
  from(
  select VCHAR_TO_DATE(spt31.appl_date) appl_date,VCHAR_TO_DATE(spt32.priority_date) priority_date,to_date('20010726','yyyymmdd') MIN_DATE
  from spt31
  left join spt32 on spt31.appl_no=spt32.appl_no and (priority_flag='1' or trim(priority_flag) is null)
  where trim(spt31.appl_no)=trim(p_appl_no)
  )
  ;
  
  if(v_tmp_date is null) then
    return null;
  end if;
  
  v_pre_data:=TO_CHAR(TO_NUMBER(TO_CHAR(v_tmp_date,'YYYYMMDD')) - 19110000,'0000000');
  DBMS_OUTPUT.PUT_LINE('appl_no='||p_appl_no||' v_tmp_date='||v_pre_data);
  return v_pre_data; 

exception
  when others then
    return null;
end GET_PRE_DATE;

/
