--------------------------------------------------------
--  DDL for Procedure BATCH_OUTSOURCING_LIST
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_OUTSOURCING_LIST" (p_in_processor_no in char,
                                                   p_out_list        out sys_refcursor) is
  --外包儀表板未通過批次
begin
  open p_out_list for
    SELECT B1.BATCH_NO,
           B1.STEP_CODE,
        -- BATCH_CHECK_STEP(B1.BATCH_NO) STEP_CODE,
           COUNT(DISTINCT D.APPL_NO) AS APPL_CNT,
           COUNT(D.RECEIVE_NO) AS RECEIVE_CNT,
           BATCH_STATUS(B1.BATCH_NO) BATCH_STATUS,
           B1.BATCH_SEQ
      FROM BATCH B1
      JOIN BATCH_DETAIL D
        ON B1.BATCH_SEQ = D.BATCH_SEQ
       AND B1.BATCH_NO = D.BATCH_NO
     WHERE  B1.STEP_CODE <> '3'
       AND BATCH_CHECK_STEP(B1.BATCH_NO) <> '3'
       AND OUTSOURCING = p_in_processor_no
       AND B1.BATCH_SEQ = (SELECT MAX(BATCH_SEQ)
                             FROM BATCH B2
                            WHERE B1.BATCH_NO = B2.BATCH_NO)
     GROUP BY B1.BATCH_NO, B1.STEP_CODE, B1.BATCH_SEQ
     ORDER BY B1.BATCH_NO DESC;

end batch_outsourcing_list;

/
