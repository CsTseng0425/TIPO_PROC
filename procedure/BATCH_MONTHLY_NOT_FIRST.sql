--------------------------------------------------------
--  DDL for Procedure BATCH_MONTHLY_NOT_FIRST
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_MONTHLY_NOT_FIRST" (p_in_processor_no in char,
                                                    p_in_start        in varchar2,
                                                    p_in_end          in varchar2,
                                                  p_out_list        out sys_refcursor) is
  /*
  ModifyDate : 104/06/26
  Desc: 批次查驗統計 (再)
  Modify Item:
  (1) start and end date between the first batch process date
  (2) only list the batch which have passed 
  */
begin
  open p_out_list for
    SELECT B.BATCH_NO,
           B.CHECK_DATE,
           B.PROCESS_DATE,
           B.BATCH_SEQ,
           COUNT(D.RECEIVE_NO) AS TOTAL_CNT,
           COUNT(CASE
                   WHEN D.IS_CHECK = '1' THEN
                    1
                 END) AS CHECK_CNT,
           COUNT(CASE
                   WHEN D.IS_CHECK = '1' AND D.IS_DEFECT = '1' THEN
                    1
                 END) AS DEFECT_CNT,
           batch_memo(B.BATCH_NO, B.BATCH_SEQ) as memo
      FROM BATCH B
      JOIN BATCH_DETAIL D
        ON B.BATCH_SEQ = D.BATCH_SEQ
       AND B.BATCH_NO = D.BATCH_NO
     JOIN BATCH B1 on B.batch_no = B1.batch_no and B1.batch_seq = '1'
     JOIN BATCH B2 ON B.BATCH_NO = B2.BATCH_NO
     WHERE  B.PROCESS_RESULT = '1'
       AND B.STEP_CODE = '3'
       AND B.BATCH_SEQ > 1
       AND B.OUTSOURCING = p_in_processor_no
       AND B1.PROCESS_DATE BETWEEN p_in_start AND p_in_end
       AND B2.BATCH_SEQ = (SELECT MAX(BATCH_SEQ)
                            FROM BATCH B3
                           WHERE B2.BATCH_NO = B3.BATCH_NO)
     GROUP BY B.BATCH_NO, B.BATCH_SEQ, B.CHECK_DATE, B.PROCESS_DATE;

end batch_monthly_not_first;

/
