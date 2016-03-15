--------------------------------------------------------
--  DDL for Procedure BATCH_HISTROY_LIST
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_HISTROY_LIST" (p_in_last  in varchar2,
                                               p_out_list out sys_refcursor) is
  --¾ú¥v§å¦¸
begin
  open p_out_list for
    SELECT B1.BATCH_NO,
           B1.STEP_CODE,
           COUNT(DISTINCT D.APPL_NO) AS APPL_CNT,
           COUNT(D.RECEIVE_NO) AS RECEIVE_CNT,
           BATCH_STATUS(B1.BATCH_NO) BATCH_STATUS,
           B1.BATCH_SEQ
      FROM BATCH B1
      JOIN BATCH_DETAIL D
        ON B1.BATCH_SEQ = D.BATCH_SEQ
       AND B1.BATCH_NO = D.BATCH_NO
     WHERE B1.STEP_CODE = '3'
       AND B1.BATCH_SEQ = (SELECT MAX(BATCH_SEQ)
                             FROM BATCH B2
                            WHERE B1.BATCH_NO = B2.BATCH_NO)
       AND PROCESS_DATE >
           TO_CHAR(TO_NUMBER(TO_CHAR(SYSDATE - p_in_last, 'YYYYMMDD')) -
                   19110000)
     GROUP BY B1.BATCH_NO, B1.STEP_CODE, B1.BATCH_SEQ
     ORDER BY B1.BATCH_NO DESC;

end batch_histroy_list;

/
