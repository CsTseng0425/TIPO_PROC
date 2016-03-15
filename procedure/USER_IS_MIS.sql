--------------------------------------------------------
--  DDL for Procedure USER_IS_MIS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."USER_IS_MIS" (
  p_190 in char, 
  p_is out varchar2
)
is
  v_count number;
begin
  select count(1)
    into v_count 
    from parameter 
   where para_no = 'MIS_ROLE'
     and pname = p_190;
  if v_count != 0 then
    p_is := 'Y';
  else
    p_is := 'N';
  end if;
end user_is_mis;

/
