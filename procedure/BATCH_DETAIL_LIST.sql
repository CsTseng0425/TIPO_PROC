--------------------------------------------------------
--  DDL for Procedure BATCH_DETAIL_LIST
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_DETAIL_LIST" (p_in_batch_no  in varchar2,
                                              p_in_batch_seq in varchar2,
                                              p_out_list     out sys_refcursor) is
begin
/*
 §å¤º²M³æ
 ModifyDate: 104/07/20
 ModifyItem (1) Add form_file_a
 104/07/14: update the condition for getting form_file_a
 104/07/20: issue_flag = '1' 
*/
  open p_out_list for
    SELECT BD.RECEIVE_NO,
           BD.APPL_NO AS APPL_NO,
           BD.IS_CHECK,
           (SELECT SPM75.TYPE_NAME
              FROM SPM75
             WHERE SPM75.TYPE_NO = S31A.TYPE_NO) AS TYPE_NAME,
           S11.NAME_C AS NAME_C,
           SPMF5.NATIONAL_NAME_C AS NATIONAL_NAME_C,
           S21A.ATTORNEY_NO AS ATTORNEY,
           BD.REASON AS REASON,
           BD.IS_DEFECT AS IS_DEFECT,
           RECEIVE.UNUSUAL AS UNUSUAL,
           BD.IS_REJECTED AS IS_REJECTED,
           batch_has_append(TRIM(BD.APPL_NO)) AS HAS_APPEND,
           SPT21.ACCEPT_DATE AS ACCEPT_DATE,
           SPT21.CONTROL_DATE AS CONTROL_DATE ,
           (select max(b.FORM_FILE_A) from spm56 b where b.RECEIVE_NO = s56.RECEIVE_NO and b.processor_no = s56.processor_no  ) FORM_FILE_A
      FROM BATCH_DETAIL BD
      LEFT JOIN SPT31A S31A
        ON TRIM(S31A.APPL_NO) = TRIM(BD.APPL_NO)
      LEFT JOIN (SELECT SPM11.APPL_NO,
                        SPM11.ID_NO,
                        SPM11.NAME_C,
                        NATIONAL_ID
                   FROM AP.SPM11
                  WHERE SPM11.ID_TYPE = '1'
                    AND SPM11.SORT_ID = '1') S11
        ON BD.APPL_NO = S11.APPL_NO
      LEFT JOIN SPMF5
        ON S11.NATIONAL_ID = SPMF5.NATIONAL_ID
      LEFT JOIN SPT21A S21A
        ON BD.RECEIVE_NO = S21A.RECEIVE_NO
      LEFT JOIN RECEIVE
        ON BD.RECEIVE_NO = RECEIVE.RECEIVE_NO
      LEFT JOIN SPT21
        ON BD.RECEIVE_NO = SPT21.RECEIVE_NO
     LEFT JOIN SPM56 s56 ON s56.receive_no = BD.receive_no and RECEIVE.processor_no = RECEIVE.processor_no and s56.issue_flag = '1'
     WHERE BD.BATCH_NO = p_in_batch_no
       AND BD.BATCH_SEQ = p_in_batch_seq
           ;

end BATCH_DETAIL_LIST;

/
