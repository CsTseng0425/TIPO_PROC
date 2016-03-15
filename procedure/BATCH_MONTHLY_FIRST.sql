--------------------------------------------------------
--  DDL for Procedure BATCH_MONTHLY_FIRST
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_MONTHLY_FIRST" (p_in_processor_no in char,
                                                p_in_start        in varchar2,
                                                p_in_end          in varchar2,
                                                p_out_list        out sys_refcursor) is
  -------------------------------
  --批次查驗統計 (首)
  -- ModifyDate : 104/06/26
  -- Modify : only list the batch which have passed 
  --------------------------------
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
                 END) AS DEFECT_CNT
      FROM BATCH B
      JOIN BATCH_DETAIL D
        ON B.BATCH_SEQ = D.BATCH_SEQ
       AND B.BATCH_NO = D.BATCH_NO
      JOIN BATCH B1 ON B.BATCH_NO = B1.BATCH_NO
     WHERE  B1.PROCESS_RESULT = '1'
       AND B1.STEP_CODE = '3'
       AND B.BATCH_SEQ = 1
       AND B.OUTSOURCING = p_in_processor_no
       AND B.PROCESS_DATE BETWEEN p_in_start AND p_in_end
       AND B1.BATCH_SEQ = (SELECT MAX(BATCH_SEQ)
                            FROM BATCH B2
                           WHERE B1.BATCH_NO = B2.BATCH_NO)
     GROUP BY B.BATCH_NO, B.BATCH_SEQ, B.CHECK_DATE, B.PROCESS_DATE;

end batch_monthly_first;

/
