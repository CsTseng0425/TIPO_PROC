--------------------------------------------------------
--  DDL for Function GET_LOGINUSER
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."GET_LOGINUSER" 
return char 
is
  v_user  varchar2(10);
begin
  --- get user id
   select sys_context ('userenv', 'client_identifier') into v_user from dual;
  return nvl(v_user,USER);
end Get_LoginUser;

/
