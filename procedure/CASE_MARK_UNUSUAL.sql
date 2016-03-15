--------------------------------------------------------
--  DDL for Procedure CASE_MARK_UNUSUAL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CASE_MARK_UNUSUAL" (p_in_unusual    in varchar2,
                                              p_in_receive_no in char) is
  -- ¼Ð¥Üµ{§ÇÂÐ®Ö

begin

  UPDATE RECEIVE
     SET UNUSUAL = p_in_unusual
   WHERE RECEIVE_NO = p_in_receive_no;

end case_mark_unusual;

/
