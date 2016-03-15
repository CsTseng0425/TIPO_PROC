--------------------------------------------------------
--  DDL for Function SPOT_CHECK_QTY
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."SPOT_CHECK_QTY" (p_all in number) return number is

begin

  case
    when p_all between 2 and 8 then
      return 2;
    when p_all between 9 and 15 then
      return 3;
    when p_all between 16 and 25 then
      return 5;
    when p_all between 26 and 50 then
      return 8;
    when p_all between 51 and 90 then
      return 13;
    when p_all between 91 and 150 then
      return 20;
    when p_all between 151 and 280 then
      return 32;
    else
      return 50;
  end case;

end SPOT_CHECK_QTY;

/
