--------------------------------------------------------
--  DDL for Procedure LIST_SECTION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."LIST_SECTION" (
  p_out_list out sys_refcursor) 
is
begin
  /*
   Modify Date : 105/01/08
   104/09/10 : exclude the receives which process_result =57001
   104/11/20: 紙本個人持有不用排除已監印
   104/12/21: 紙本持有不用再判斷912
   104/12/23: 個人線上辦結條件再加判斷階段別
   105/01/08: add condition for paper receive:  spt21.accept_date >= '1050101'
  */
  OPEN p_out_list FOR
 SELECT SPM63.PROCESSOR_NO, SPM63.NAME_C, NVL(A.TODO,0) TODO, NVL(A.DONE,0) DONE, NVL(A.REJECTED,0) REJECTED, 
         NVL(B.TODO_P,0) TODO_P, -- 紙本公文
         NVL(C.DONE_P,0) DONE_P, -- 紙本已銷號
         '' REJECTED_P -- 紙本退辦
  FROM SPM63
   LEFT JOIN (
       SELECT s21.PROCESSOR_NO,
          COUNT(CASE WHEN s21.PROCESS_RESULT is null  AND RECEIVE.RECEIVE_NO is not null THEN 1 ELSE NULL END) AS TODO,
          COUNT(CASE WHEN s21.PROCESS_RESULT is not null AND receive.step_code < '5'  AND s21.process_result != '57001'   AND return_no not in ('4','A','B','C','D') THEN 1 ELSE NULL END) AS DONE,
          COUNT(CASE WHEN receive.step_code = '5' and substr(RECEIVE.processor_no,1,1) != 'P'  AND s21.process_result != '57001'
               THEN 1 ELSE NULL END) AS REJECTED
      FROM  RECEIVE  
       JOIN SPT21 s21 ON s21.RECEIVE_NO = RECEIVE.RECEIVE_NO 
      WHERE  RECEIVE.step_code > '0'
        AND RECEIVE.step_code < '8'
      GROUP BY s21.PROCESSOR_NO
  ) A ON   SPM63.PROCESSOR_NO = A.PROCESSOR_NO
  LEFT JOIN (
      SELECT SPT21.object_id as PROCESSOR_NO, COUNT(SPT21.RECEIVE_NO) AS TODO_P
      FROM SPT21
      JOIN SPT23 ON SPT21.receive_no = SPT23.receive_no AND SPT21.OBJECT_ID = Spt23.OBJECT_TO and SPT21.trans_seq = spt23.data_seq
      WHERE  SPT21.ACCEPT_DATE >= '1050101'
      AND PROCESS_RESULT IS NULL
      AND SPT21.object_id IN (SELECT PROCESSOR_NO FROM SPM63 WHERE DEPT_NO ='70012' AND QUIT_DATE IS NULL)
  --    AND SPT21.trans_no = '912'   -- mark by susan 104/12/21
      GROUP BY SPT21.object_id
   ) B ON SPM63.PROCESSOR_NO = B.PROCESSOR_NO
   LEFT JOIN
    (
      SELECT SPT21.object_id as PROCESSOR_NO, COUNT(SPT21.RECEIVE_NO) AS DONE_P
      FROM SPT21
      JOIN SPT23 ON SPT21.receive_no = SPT23.receive_no AND SPT21.OBJECT_ID = Spt23.OBJECT_TO and SPT21.trans_seq = spt23.data_seq
      WHERE  PROCESS_RESULT IS NOT NULL
      AND PROCESS_RESULT != '57001'
  --    AND NOT EXISTS (SELECT RECEIVE_NO FROM SPT41 WHERE RECEIVE_NO = SPT21.RECEIVE_NO and processor_no = SPT21.processor_no and check_datetime is not null)
      AND SPT21.object_id IN (SELECT PROCESSOR_NO FROM SPM63 WHERE DEPT_NO ='70012' AND QUIT_DATE IS NULL)
      AND SPT21.ACCEPT_DATE >= '1050101'
   --   AND SPT21.trans_no = '912'   -- mark by susan 104/12/21
      GROUP BY SPT21.object_id
   ) C ON SPM63.PROCESSOR_NO=C.PROCESSOR_NO
  /* LEFT JOIN 
   (
      SELECT SPT21.object_id as PROCESSOR_NO, COUNT(SPT21.RECEIVE_NO) AS REJECTED_P
      FROM SPT21
      LEFT JOIN SPT41 ON SPT21.RECEIVE_NO = SPT41.RECEIVE_NO AND SPT41.APPL_NO = SPT21.APPL_NO
      LEFT JOIN SPT23 A ON A.RECEIVE_NO = SPT21.RECEIVE_NO
      LEFT JOIN SPT23 B ON B.RECEIVE_NO = SPT21.RECEIVE_NO
      WHERE  SPT21.object_id IN ( SELECT PROCESSOR_NO FROM SPM63 WHERE DEPT_NO ='70012' AND QUIT_DATE IS NULL)
      AND SPT21.PROCESS_RESULT IS NOT  NULL
      AND SPT21.PROCESS_RESULT  != '57001'
      AND A.TRANS_NO IN ('921','922','923')
      AND A.OBJECT_FROM in 
      ( select processor_no from spm63 where substr(dept_no,1,3) = '700' and title  in ('科長','專門委員','科員')  
         and processor_no = B.processor_no
        and spm63.quit_date is not null
      )
      AND B.TRANS_NO='913' AND B.PROCESSOR_NO= SPT21.OBJECT_ID
      AND A.DATA_SEQ = B.DATA_SEQ +1
      GROUP BY SPT21.object_id
   ) D ON SPM63.PROCESSOR_NO=D.PROCESSOR_NO  */
   WHERE SPM63.PROCESSOR_NO IS NOT NULL 
   AND SPM63.DEPT_NO = '70012'
   AND SPM63.QUIT_DATE is null
  ORDER BY SPM63.PROCESSOR_NO;
  
  
end LIST_SECTION;

/
