--------------------------------------------------------
--  DDL for Procedure BATCH_DETAIL_DEFECT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_DETAIL_DEFECT" (p_in_defect     in varchar2,
                                                p_in_batch_no   in varchar2,
                                                p_in_batch_seq  in varchar2,
                                                p_in_receive_no in char) is
  -- §å¦¸²M³æ·å²«
begin

  UPDATE BATCH_DETAIL
     SET IS_DEFECT = p_in_defect
   WHERE BATCH_NO = p_in_batch_no
     AND BATCH_SEQ = p_in_batch_seq
     AND RECEIVE_NO = p_in_receive_no;

end batch_detail_defect;

/
