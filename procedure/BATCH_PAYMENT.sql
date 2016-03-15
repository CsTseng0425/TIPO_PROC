--------------------------------------------------------
--  DDL for Procedure BATCH_PAYMENT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_PAYMENT" (p_in_processor_no in char,
                                          p_in_start        in varchar2,
                                          p_in_end          in varchar2,
                                          p_out_list        out sys_refcursor) is
  /*
  ModifyDate : 1040526
  Desc: 批次金額統計 BATCH PAYMENT Summary
  ModifyItem: 
  (1) add condition: just list pass batch
  (2) start and end date between the first batch process date
  */
begin
  open p_out_list for
    SELECT B.BATCH_NO,
           B1.PROCESS_DATE,
           B.BATCH_SEQ,
           COUNT(D.RECEIVE_NO) AS TOTAL_CNT,
           (SELECT COUNT(RECEIVE_NO)
              FROM BATCH_DETAIL
             WHERE BATCH_NO = B.BATCH_NO
               AND BATCH_SEQ = 1
               AND IS_DEFECT = '1'
               AND IS_CHECK = '1') AS DEFECT_CNT,
           CASE
             WHEN B.BATCH_SEQ = 1 THEN
              0
             ELSE
              (SELECT COUNT(RECEIVE_NO)
                 FROM BATCH_DETAIL
                WHERE BATCH_NO = B.BATCH_NO
                  AND BATCH_SEQ <> 1
                  AND IS_DEFECT = '1'
                  AND IS_CHECK = '1')
           END AS RECHECK_DEFECT_CNT
      FROM BATCH B
      JOIN BATCH_DETAIL D
        ON B.BATCH_SEQ = D.BATCH_SEQ
       AND B.BATCH_NO = D.BATCH_NO
     JOIN BATCH B1 on B.batch_no = B1.batch_no and B1.batch_seq = '1'
     WHERE B.PROCESS_RESULT = '1'
       AND B.STEP_CODE = '3'
       AND B.OUTSOURCING = p_in_processor_no
       AND B1.PROCESS_DATE BETWEEN p_in_start AND p_in_end
       AND B.BATCH_SEQ = (SELECT MAX(BATCH_SEQ)
                            FROM BATCH B2
                           WHERE B.BATCH_NO = B2.BATCH_NO)
     GROUP BY B.BATCH_NO, B.BATCH_SEQ, B1.PROCESS_DATE;

end batch_payment;

/
