--------------------------------------------------------
--  DDL for Function GET_REVISE_OPTIONS
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."GET_REVISE_OPTIONS" (
  p_appl_no in spt31.appl_no%type, 
  p_online_flg in spt21.online_flg%type)
return varchar2_tab 
is
  v_options    varchar2_tab;
  v_online_flg spt21.online_flg%type;
begin
  if upper(p_online_flg) = 'Y' then
    select b.pname 
      bulk collect
      into v_options
      from appl_para a, parameter b 
     where a.para_no = b.para_no 
       and a.sys = 'PRE_EXAM' 
       and a.subsys = substr(p_appl_no, 4, 1)
     order by a.seq;
  else
    select b.pname 
      bulk collect
      into v_options
      from appl_para a, parameter b 
     where a.para_no = b.para_no 
       and a.sys = 'OLD_EXAM' 
       and a.subsys = '1'
     order by a.seq;
  end if;
  return v_options;
exception
  when no_data_found then
    return varchar2_tab();
end get_revise_options;

/
