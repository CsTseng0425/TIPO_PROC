--------------------------------------------------------
--  DDL for Procedure BATCH_COUNT_APPEND
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_COUNT_APPEND" (p_in_batch_no    in varchar2,
                                               p_in_batch_seq   in varchar2,
                                               p_out_has_append out varchar2) is
  -- �O�_�������
begin

  SELECT COUNT(1) AS HAS_APPEND
    into p_out_has_append
    FROM BATCH_DETAIL
   WHERE BATCH_NO = p_in_batch_no
     AND BATCH_SEQ = p_in_batch_seq
     AND BATCH_HAS_APPEND(APPL_NO) <> 0;

end batch_count_append;

/
