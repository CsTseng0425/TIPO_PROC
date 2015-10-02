create or replace PROCEDURE        BATCH_APPROVER_LIST (p_in_processor_no in char,
                                                p_out_list        out sys_refcursor) is
  /*
  --查驗儀表板未通過批次
  ModifyDate:104/07/08
  0703: using ap.spm72  for limited approver
  0706: add manager as approver condition for spm72 has no data of the processor_no
  0707: chnage condition when spm72 has no data ,then check if the login user is the department manager
  */
begin
  open p_out_list for
    SELECT B1.BATCH_NO,
           B1.STEP_CODE,
        --  BATCH_CHECK_STEP(B1.BATCH_NO) STEP_CODE,
           COUNT(DISTINCT D.APPL_NO) AS APPL_CNT,
           COUNT(D.RECEIVE_NO) AS RECEIVE_CNT,
           BATCH_STATUS(B1.BATCH_NO) BATCH_STATUS,
           B1.BATCH_SEQ
      FROM BATCH B1
      JOIN BATCH_DETAIL D
        ON B1.BATCH_SEQ = D.BATCH_SEQ
       AND B1.BATCH_NO = D.BATCH_NO
     WHERE B1.STEP_CODE <> '3'
       AND  BATCH_CHECK_STEP(B1.BATCH_NO)  <> '3'
       AND ((trim(B1.Outsourcing) in  (  select processor_no
                          from ap.spm72 where dept_no = '70012' and checker = p_in_processor_no))  -- 
          or ( p_in_processor_no in  (  select processor_no
                          from ap.spm63 where dept_no = '70012' and title in  ('科長','科員') 
                          ))  -- 
          )
       AND B1.BATCH_SEQ = (SELECT MAX(BATCH_SEQ)
                             FROM BATCH B2
                            WHERE B1.BATCH_NO = B2.BATCH_NO)
     GROUP BY B1.BATCH_NO, B1.STEP_CODE, B1.BATCH_SEQ
     ORDER BY B1.BATCH_NO DESC;

end batch_approver_list;