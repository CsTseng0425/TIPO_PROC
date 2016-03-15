--------------------------------------------------------
--  DDL for Procedure BATCH_STEP_CODE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_STEP_CODE" (p_in_batch_no   in varchar2,
                                            p_in_batch_seq  in varchar2,
                                            p_out_step_code out varchar2) is
  -- 取得階段別
begin

  SELECT STEP_CODE
    into p_out_step_code
    FROM BATCH
   WHERE BATCH_NO = p_in_batch_no
     AND BATCH_SEQ = p_in_batch_seq;

end batch_step_code;

/
