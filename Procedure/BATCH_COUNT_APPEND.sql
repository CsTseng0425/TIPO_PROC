create or replace PROCEDURE        BATCH_COUNT_APPEND (p_in_batch_no    in varchar2,
                                               p_in_batch_seq   in varchar2,
                                               p_out_has_append out varchar2) is
  -- 是否有後續文
begin

  SELECT COUNT(1) AS HAS_APPEND
    into p_out_has_append
    FROM BATCH_DETAIL
   WHERE BATCH_NO = p_in_batch_no
     AND BATCH_SEQ = p_in_batch_seq
     AND BATCH_HAS_APPEND(APPL_NO) <> 0;

end batch_count_append;