create or replace procedure batch_daily_count(p_in_batch_no  in varchar2,
                                              p_in_batch_seq in varchar2,
                                              p_out_list     out sys_refcursor) is
  --批次件數
begin
  open p_out_list for
    SELECT B.BATCH_NO,
           B.CHECK_DATE,
           B.PROCESS_DATE,
           B.OUTSOURCING,
           COUNT(D.RECEIVE_NO) AS TOTAL_CNT,
           COUNT(CASE
                   WHEN D.IS_CHECK = '1' THEN
                    1
                 END) AS CHECK_CNT,
           COUNT(CASE
                   WHEN D.IS_CHECK = '1' AND D.IS_DEFECT = '1' THEN
                    1
                 END) AS DEFECT_CNT,
           B.PROCESS_RESULT,
           B.BATCH_SEQ 
      FROM BATCH B
      JOIN BATCH_DETAIL D
        ON B.BATCH_SEQ = D.BATCH_SEQ
       AND B.BATCH_NO = D.BATCH_NO
     WHERE B.PROCESS_RESULT <> '0'
       AND B.BATCH_NO = p_in_batch_no
       AND B.BATCH_SEQ = p_in_batch_seq
     GROUP BY B.BATCH_NO,
              B.BATCH_SEQ,
              B.CHECK_DATE,
              B.PROCESS_DATE,
              B.PROCESS_RESULT,
              B.OUTSOURCING;

end batch_daily_count;