--------------------------------------------------------
--  DDL for Procedure BATCH_DETAIL_REASON
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_DETAIL_REASON" (p_in_reason     in varchar2,
                                                p_in_batch_no   in varchar2,
                                                p_in_batch_seq  in varchar2,
                                                p_in_receive_no in char) is
  -- 批次清單瑕疵原因
begin

  UPDATE BATCH_DETAIL
     SET REASON = p_in_reason
   WHERE BATCH_NO = p_in_batch_no
     AND BATCH_SEQ = p_in_batch_seq
     AND RECEIVE_NO = p_in_receive_no;

end batch_detail_reason;

/
