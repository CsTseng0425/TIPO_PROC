--------------------------------------------------------
--  DDL for Function ADD_WORKDAYS
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."ADD_WORKDAYS" (p_date_bc in timestamp, p_days in number) 
return timestamp
is
v_date_bc    SPMFF.date_bc%type;
v_date       char(8);
v_date_2     char(8);
begin
  v_date:=to_char(p_date_bc,'YYYYMMDD');
  if (p_days>0) then
    v_date_2:=to_char(p_date_bc+ceil(1.5*p_days+10),'YYYYMMDD');
    select DATE_BC into v_date_bc
    from (
      select DATE_BC,row_number() over (order by DATE_BC ) as rn  
      from SPMFF
      where DATE_BC<v_date_2 
      and DATE_BC>v_date and DATE_FLAG='1')
    where rn=p_days;
  else
    if (p_days<0) then
      v_date_2:=to_char(p_date_bc-ceil(-1.5*p_days+10),'YYYYMMDD');
      select DATE_BC into v_date_bc
      from (
        select DATE_BC,row_number() over (order by DATE_BC desc ) as rn  
        from SPMFF 
        where DATE_BC>v_date_2
        and DATE_BC<v_date and DATE_FLAG='1')
      where -rn=p_days;
    end if;       
  end if;
  
  if(v_date_bc is not null) then
    return to_date(v_date_bc,'YYYYMMDD');
  else
    return null;
  end if;
end add_workdays;

/
