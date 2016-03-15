--------------------------------------------------------
--  DDL for Procedure BATCH_DETAIL_CHECK
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_DETAIL_CHECK" (p_in_check      in varchar2,
                                               p_in_batch_no   in varchar2,
                                               p_in_batch_seq  in varchar2,
                                               p_in_receive_no in char) is
  -- �妸�M��d��
begin
  UPDATE BATCH_DETAIL
     SET IS_CHECK = p_in_check
   WHERE BATCH_NO = p_in_batch_no
     AND BATCH_SEQ = p_in_batch_seq
     AND RECEIVE_NO = p_in_receive_no;
end batch_detail_check;

/
