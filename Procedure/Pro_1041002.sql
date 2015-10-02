--------------------------------------------------------
--  已建立檔案 - 星期五-十月-02-2015   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Procedure ALL_PROCESSORS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."ALL_PROCESSORS" (p_out_list out sys_refcursor) is
  -- 二科承辦人員資料
begin
  open p_out_list for
    SELECT PROCESSOR_NO, NAME_C
      FROM SPM63
     WHERE DEPT_NO = '70012'
       AND QUIT_DATE IS NULL
     ORDER BY PROCESSOR_NO;

end all_processors;

/
--------------------------------------------------------
--  DDL for Procedure BATCH_APPROVER_LIST
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_APPROVER_LIST" (p_in_processor_no in char,
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

/
--------------------------------------------------------
--  DDL for Procedure BATCH_COUNT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_COUNT" (p_in_batch_no  in varchar2,
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

end batch_count;

/
--------------------------------------------------------
--  DDL for Procedure BATCH_COUNT_APPEND
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_COUNT_APPEND" (p_in_batch_no    in varchar2,
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

/
--------------------------------------------------------
--  DDL for Procedure BATCH_DAILY_COUNT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_DAILY_COUNT" (p_in_batch_no  in varchar2,
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

/
--------------------------------------------------------
--  DDL for Procedure BATCH_DETAIL_CHECK
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_DETAIL_CHECK" (p_in_check      in varchar2,
                                               p_in_batch_no   in varchar2,
                                               p_in_batch_seq  in varchar2,
                                               p_in_receive_no in char) is
  -- 批次清單查驗
begin
  UPDATE BATCH_DETAIL
     SET IS_CHECK = p_in_check
   WHERE BATCH_NO = p_in_batch_no
     AND BATCH_SEQ = p_in_batch_seq
     AND RECEIVE_NO = p_in_receive_no;
end batch_detail_check;

/
--------------------------------------------------------
--  DDL for Procedure BATCH_DETAIL_DEFECT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_DETAIL_DEFECT" (p_in_defect     in varchar2,
                                                p_in_batch_no   in varchar2,
                                                p_in_batch_seq  in varchar2,
                                                p_in_receive_no in char) is
  -- 批次清單瑕疵
begin

  UPDATE BATCH_DETAIL
     SET IS_DEFECT = p_in_defect
   WHERE BATCH_NO = p_in_batch_no
     AND BATCH_SEQ = p_in_batch_seq
     AND RECEIVE_NO = p_in_receive_no;

end batch_detail_defect;

/
--------------------------------------------------------
--  DDL for Procedure BATCH_DETAIL_LIST
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_DETAIL_LIST" (p_in_batch_no  in varchar2,
                                              p_in_batch_seq in varchar2,
                                              p_out_list     out sys_refcursor) is
begin
/*
 批內清單
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
--------------------------------------------------------
--  DDL for Procedure BATCH_DETAIL_REASON
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_DETAIL_REASON" (p_in_reason     in varchar2,
                                                p_in_batch_no   in varchar2,
                                                p_in_batch_seq  in varchar2,
                                                p_in_receive_no in char) is
  -- 批次清單瑕疵原因
begin

  UPDATE BATCH_DETAIL
     SET REASON = p_in_reason
   WHERE BATCH_NO = p_in_batch_no
     AND BATCH_SEQ = p_in_batch_seq
     AND RECEIVE_NO = p_in_receive_no;

end batch_detail_reason;

/
--------------------------------------------------------
--  DDL for Procedure BATCH_HISTROY_LIST
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_HISTROY_LIST" (p_in_last  in varchar2,
                                               p_out_list out sys_refcursor) is
  --歷史批次
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
--------------------------------------------------------
--  DDL for Procedure BATCH_INFO
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_INFO" (p_in_batch_no  in varchar2,
                                       p_in_batch_seq in varchar2,
                                       BATCH_NO       out varchar2,
                                       BATCH_SEQ      out varchar2,
                                       STEP_CODE      out varchar2,
                                       COUNT_ALL      out varchar2,
                                       SPOT_CHECK     out varchar2,
                                       COUNT_CHECKED  out varchar2,
                                       COUNT_DEFECT   out varchar2,
                                       CHECK_DATE     out varchar2,
                                       PROCESS_DATE   out varchar2,
                                       PROCESS_RESULT out varchar2) IS
  v_step_code     varchar(2);
  v_count_all     number;
  v_count_defect  number;
  v_count_spot    number;
  v_count_checked number;
  v_result        char(1);
  v_has_checked   number;
/*
  批次清單:
  104/08/21
*/
BEGIN

  select step_code
    into v_step_code
    from batch
   where batch_no = p_in_batch_no
     and batch_seq = p_in_batch_seq;

  if v_step_code = 1 then
  
    select count(receive_no),
           count(case
                   when IS_CHECK = '1' and IS_DEFECT = '1' then
                    1
                 end),
           SPOT_CHECK_QTY(count(receive_no)),
           count(case
                   when IS_CHECK = '1' then
                    1
                 end),
          count(case
                   when IS_CHECK = '2' then
                    1
                 end)
      into v_count_all, v_count_defect, v_count_spot, v_count_checked ,v_has_checked
      from BATCH_DETAIL
     where batch_no = p_in_batch_no
       and batch_seq = p_in_batch_seq;
     
    if v_count_all - v_has_checked < v_count_spot   then 
        v_count_spot := v_count_all - v_has_checked;
    end if;  
    
  
    if v_count_checked >= v_count_spot or v_count_defect > 0 then
    
      if v_count_defect = 0 then
        v_result := '1';
      elsif v_count_all > 150 and v_count_defect = 1 then
        v_result := '2';
      else
        v_result := '3';
      end if;
    
    else
      v_result := 0;
    
    end if;
    SYS.Dbms_Output.Put_Line(v_count_all || ',' || v_count_defect|| ',' || v_count_spot|| ',' || v_count_checked || ',' ||v_has_checked);
    UPDATE BATCH
       SET Process_result = v_result,
           check_date     = TO_CHAR(TO_NUMBER(TO_CHAR(SYSDATE, 'YYYYMMDD')) -
                                    19110000)
     WHERE batch.batch_seq = p_in_batch_seq
       AND batch.batch_no = p_in_batch_no;
  end if;
 SYS.Dbms_Output.Put_Line('v_result=' || v_result);
  SELECT B1.BATCH_NO,
         B1.BATCH_SEQ,
         B1.STEP_CODE,
         COUNT(D.RECEIVE_NO),
      --   SPOT_CHECK_QTY(COUNT(D.RECEIVE_NO)),
         v_count_spot ,
         COUNT(CASE
                 WHEN IS_CHECK = '1' THEN
                  1
               END),
         COUNT(CASE
                 WHEN IS_CHECK = '1' AND IS_DEFECT = '1' THEN
                  1
               END),
         B1.CHECK_DATE,
         B1.PROCESS_DATE,
         B1.PROCESS_RESULT
    INTO BATCH_NO,
         BATCH_SEQ,
         STEP_CODE,
         COUNT_ALL,
         SPOT_CHECK,
         COUNT_CHECKED,
         COUNT_DEFECT,
         CHECK_DATE,
         PROCESS_DATE,
         PROCESS_RESULT
    FROM BATCH B1
    JOIN BATCH_DETAIL D
      ON B1.BATCH_SEQ = D.BATCH_SEQ
     AND B1.BATCH_NO = D.BATCH_NO
   WHERE B1.BATCH_NO = p_in_batch_no
     AND B1.BATCH_SEQ = p_in_batch_seq
   GROUP BY B1.BATCH_NO,
            B1.STEP_CODE,
            B1.CHECK_DATE,
            B1.PROCESS_DATE,
            B1.PROCESS_RESULT,
            B1.BATCH_SEQ;

  
END BATCH_INFO;

/
--------------------------------------------------------
--  DDL for Procedure BATCH_JUDGE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_JUDGE" (p_in_processor_no in char,
                                        p_in_batch_no     in varchar2,
                                        p_in_batch_seq    in varchar2) is
  -- 判發
begin
/*
  Desc : 判發, Approver approve batch form 
--  Q: if the status will be changed on the moment?

  UPDATE BATCH
     SET STEP_CODE  = CASE PROCESS_RESULT
                        WHEN '1' THEN
                         '3'
                        ELSE
                         '2'
                      END,
         CHECK_DATE = TO_CHAR(TO_NUMBER(TO_CHAR(SYSDATE, 'YYYYMMDD')) -
                              19110000),
         APPROVER   = p_in_processor_no
   WHERE BATCH_NO = p_in_batch_no
     AND BATCH_SEQ = p_in_batch_seq;
*/
  SYS.Dbms_Output.Put_Line('BATCH_JUDGE');
end batch_judge;

/
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
--------------------------------------------------------
--  DDL for Procedure BATCH_PAYMENT_CHECK
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_PAYMENT_CHECK" (p_in_processor_no in char,
                                                p_in_ym           in varchar2,
                                                p_in_count        out int) is

begin

  select count(1)
    into p_in_count
    from batch
   where substr(process_date, 1, 5) = p_in_ym
     and step_code < '3'
     and outsourcing = p_in_processor_no
     and batch_seq = (select max(batch_seq)
                        from batch b
                       where batch.batch_no = b.batch_no);

end BATCH_PAYMENT_CHECK;

/
--------------------------------------------------------
--  DDL for Procedure BATCH_REPORT_COUNT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_REPORT_COUNT" (p_in_batch_no  in varchar2,
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
           B.BATCH_SEQ ,
                    batch_memo(B.BATCH_NO, B.BATCH_SEQ) as memo
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

end batch_report_count;

/
--------------------------------------------------------
--  DDL for Procedure BATCH_REPORT_DETAIL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_REPORT_DETAIL" (p_in_batch_no  in varchar2,
                                                p_in_batch_seq in varchar2,
                                                p_out_list     out sys_refcursor) is
  --批次明細
begin
  open p_out_list for
    SELECT BATCH_SEQ, BATCH_NO, APPL_NO, IS_CHECK, IS_DEFECT, REASON
      FROM BATCH_DETAIL
     WHERE BATCH_NO = p_in_batch_no
       AND BATCH_SEQ = p_in_batch_seq
       AND IS_CHECK = '1';

end batch_report_detail;

/
--------------------------------------------------------
--  DDL for Procedure BATCH_REPORT_PREDEFECTS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_REPORT_PREDEFECTS" (p_in_batch_no  in varchar2,
                                                    p_in_batch_seq in varchar2,
                                                    p_out_list     out sys_refcursor) is
  -- 上次瑕疵文號
begin

  open p_out_list for
    SELECT RECEIVE_NO
      FROM BATCH_DETAIL
     WHERE BATCH_NO = p_in_batch_no
       AND BATCH_SEQ = p_in_batch_seq - 1
       AND IS_DEFECT = '1';

end batch_report_predefects;

/
--------------------------------------------------------
--  DDL for Procedure BATCH_SAMPLE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_SAMPLE" (p_in_batch_no  in varchar2,
                                         p_in_batch_seq in number
                                        ) IS

BEGIN
/*
 Desc: random check
 ModifyDate : 104/07/14
 104/07/14 : cancel to get the receive which has been rejected
*/
  update batch_detail a
     set is_check = '1'
   where exists (select 1
            from (select *
                    from (select *
                            from batch_detail
                           where batch_no = p_in_batch_no
                             and batch_seq = p_in_batch_seq
                             and is_check = '0'
                           order by dbms_random.random)
                   where rownum <= (select spot_check_qty(count(1)) --應抽數量
                                      from batch_detail
                                     where  batch_no = p_in_batch_no
                                       and batch_seq = p_in_batch_seq) -
                         (select count(1) --已抽數量 
                                      from batch_detail
                                     where batch_no = p_in_batch_no
                                       and batch_seq = p_in_batch_seq
                                       and is_check = '1')) b
           where a.batch_no = b.batch_no
             and a.batch_seq = b.batch_seq
             and a.receive_no = b.receive_no
             and A.Is_Rejected = '0'
             );
             
     

END BATCH_SAMPLE;

/
--------------------------------------------------------
--  DDL for Procedure BATCH_SEND
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_SEND" (p_in_batch_no  in varchar2,
                                       p_in_batch_seq in number,
                                       p_out_msg      out varchar2) IS
 l_message varchar2(2000);                                       

BEGIN
/*
Desc: send for approved by outsoursing 整批送批
ModifyDate : 104/07/14
ModifyItem:
104/05/26:IS_DEFECT is written to next sequence 
104/07/14: check if exists receives haven't create form ,then show message 
*/

--    select batch_FormList(p_in_batch_no,p_in_batch_seq) into l_message
--  from dual;
  
  if length(l_message)>0 then
     p_out_msg := l_message;
     SYS.Dbms_Output.Put_Line('l_message=' || l_message);
  else
  
  update BATCH
     set STEP_CODE    = '1'
   where BATCH_NO = p_in_batch_no
     and BATCH_SEQ = p_in_batch_seq;

  insert into batch
    (BATCH_SEQ,
     BATCH_NO,
     OUTSOURCING,
     APPROVER,
     STEP_CODE,
     PROCESS_DATE,
     CHECK_DATE,
     PROCESS_RESULT)
    select BATCH_SEQ + 1,
           BATCH_NO,
           OUTSOURCING,
           APPROVER,
           '1',
           TO_CHAR(TO_NUMBER(TO_CHAR(SYSDATE, 'YYYYMMDD')) - 19110000),
           null,
           0
      from batch
     where batch_no = p_in_batch_no
       and batch_seq = p_in_batch_seq;

  insert into batch_detail
    (BATCH_SEQ, BATCH_NO, RECEIVE_NO, APPL_NO, IS_CHECK, IS_DEFECT, REASON,IS_REJECTED)
    select BATCH_SEQ + 1,
           BATCH_NO,
           RECEIVE_NO,
           APPL_NO,
           case
             when IS_CHECK >= '1' then
              '2'
             else
              '0'
           end as IS_CHECK,
           '0',
           REASON ,
           IS_REJECTED
      from batch_detail
     where batch_no = p_in_batch_no
       and batch_seq = p_in_batch_seq;
         p_out_msg := '送核成功';
        SYS.Dbms_Output.Put_Line('p_out_msg=' || p_out_msg);
  end if;
  


END BATCH_SEND;

/
--------------------------------------------------------
--  DDL for Procedure BATCH_STEP_CODE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_STEP_CODE" (p_in_batch_no   in varchar2,
                                            p_in_batch_seq  in varchar2,
                                            p_out_step_code out varchar2) is
  -- 取得階段別
begin

  SELECT STEP_CODE
    into p_out_step_code
    FROM BATCH
   WHERE BATCH_NO = p_in_batch_no
     AND BATCH_SEQ = p_in_batch_seq;

end batch_step_code;

/
--------------------------------------------------------
--  DDL for Procedure BATCH_TO_DISPATCH
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_TO_DISPATCH" (p_in_batch_no   in varchar2,
                                              p_in_batch_seq  in number,
                                              p_in_receive_no in char) is
      l_has_append char(1);
      l_appl_no char(15);                                              
begin
/*
Modify: 104/09/07
 退人工分辦; 退文註記改為: 4:退人工分辦; 收文狀態改為:待領;清空辦理結果
 原則:同案全退
 (1) update return_no = 4 step_code = 0 processor_no=70012 process_result = null
 (2) return all receive with the same project
 (3) update batch_detail set is_rejected=1
 (4) clear merge relation 
 1040706: update return_no = 'B' where return_no = '4'
 1040907: 清除併辦狀態
*/
 select appl_no into l_appl_no
                      from batch_detail
                     where batch_seq = p_in_batch_seq
                       and batch_no = p_in_batch_no
                       and receive_no = p_in_receive_no
                       ;
   l_has_append := batch_has_append(l_appl_no);
   ---------------------
    -- record receive transfer history
    ---------------------
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no , '70012','0',
              sysdate,'查驗人工分辦'
      from receive
      Where appl_no = (select appl_no
                      from batch_detail
                     where batch_seq = p_in_batch_seq
                       and batch_no = p_in_batch_no
                       and receive_no = p_in_receive_no);


   
    Update receive
    Set return_no = 'B', step_code = '0' , processor_no = '70012', merge_master = null 
    Where appl_no = l_appl_no;
                       
    update batch_detail 
    set IS_REJECTED = '1'
     , reason = case when l_has_append = '1'
                     then '另有後續文' 
                     else ''
                      end 
    where batch_seq = p_in_batch_seq
                       and batch_no = p_in_batch_no
                       and receive_no = p_in_receive_no
   ;
                     
    update spt21
    set processor_no = '70012', process_result = null ,  pre_exam_date = null , pre_exam_qty = null
    where  appl_no = l_appl_no; 

end BATCH_TO_DISPATCH;

/
--------------------------------------------------------
--  DDL for Procedure BATCH_TO_POOL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_TO_POOL" (p_in_batch_no   in varchar2,
                                          p_in_batch_seq  in number,
                                          p_in_receive_no in char) is
      l_has_append char(1);
      l_appl_no char(15);
      l_out_msg varchar2(100);
      l_rec_cnt number;
begin
/*
Modify: 104/09/07
退領辦區,辦理結果清空;不由批號中移除,只改變狀態為1 (退辦)
(1) update receive set step_code=0 return_no =2 processor_no = 70012 process_result=null
(2) return all receive with the same project
(3) update batch_detail set is_rejected=1
(4) call check_receive
(5) exists merge receive, then clear the merge relation
1040907: 清除併辦狀態
*/
l_rec_cnt:=0;
  select appl_no into l_appl_no
                      from batch_detail
                     where batch_seq = p_in_batch_seq
                       and batch_no = p_in_batch_no
                       and receive_no = p_in_receive_no
                       ;
   l_has_append := batch_has_append(l_appl_no);
   
      delete tmp_get_receive  
      where receive_no in 
      (select receive_no from receive where appl_no = (select appl_no from receive
        where receive_no = p_in_receive_no)
      );
 ---------------------
    -- record receive transfer history
    ---------------------
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no , '70012','0',
              sysdate,'查驗退領辦區'
      from receive
      Where appl_no = l_appl_no;
            
   
      l_rec_cnt := l_rec_cnt +  SQL%RowCount;
   update receive
     set step_code = '0' ,RETURN_NO = '2' , processor_no = '70012' , merge_master = null
   where appl_no =l_appl_no;
   l_rec_cnt := l_rec_cnt +  SQL%RowCount;
         
                       
   update spt21
     set processor_no = '70012', process_result = null ,  pre_exam_date = null , pre_exam_qty = null
   where receive_no in (select receive_no
                      from receive
                     where appl_no = l_appl_no); 
                       
  update batch_detail 
  set IS_REJECTED = '1'
     , reason = case when  l_has_append = '1'
                     then '另有後續文' 
                     else ''
                      end 
  where batch_seq = p_in_batch_seq
                       and batch_no = p_in_batch_no
                       and receive_no = p_in_receive_no
  ;
  commit;
   CHECK_RECEIVE('0',l_rec_cnt,l_out_msg);
   dbms_output.put_line('finish');
 
end BATCH_TO_POOL;

/
--------------------------------------------------------
--  DDL for Procedure CASE_DISPATCH
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CASE_DISPATCH" (p_in_receive_no   in char,
                                          p_in_processor_no in char,
                                          p_in_force        in char,
                                          p_out_msg         out varchar2) is
  v_count number;
begin
/*
ModifyDate : 2015/06/02
Desc : assign by department manager
modify: 6/2 RECEIVE_TRANS_LOG schema change
*/

  SELECT COUNT(1)
    INTO v_count
    FROM RECEIVE
   WHERE STEP_CODE = '2'
     AND RECEIVE_NO = p_in_receive_no;

  if v_count > 0 and p_in_force != 'Y' then
    p_out_msg := '此文已被領辦,未被銷號,是否要強制分辦?';
    return;
  end if;

  SELECT COUNT(1)
    INTO v_count
    FROM RECEIVE
   WHERE STEP_CODE > '2'
     AND RECEIVE_NO = p_in_receive_no;

  if v_count > 0 then
    p_out_msg := '此文已銷號,不可分辦!';
    return;
  end if;
  
  ---------------------
    -- record receive transfer history
    ---------------------
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = RECEIVE.receive_no ),'1') seq , 
              RECEIVE.receive_no, RECEIVE.appl_no , p_in_processor_no,'2',sysdate,'科長分辦'
      from RECEIVE
       Where receive_no = p_in_receive_no;

  UPDATE RECEIVE
     SET PROCESSOR_NO = p_in_processor_no,
         STEP_CODE    = '2',
         process_date = to_char(to_number(to_char(sysdate, 'yyyyMMdd')) -
                                19110000)
   WHERE RECEIVE_NO = p_in_receive_no;

  update spt21
     set processor_no = p_in_processor_no
   where receive_no = p_in_receive_no;

  p_out_msg := '文號 ' || p_in_receive_no || '分辦成功';
  return;

end case_dispatch;

/
--------------------------------------------------------
--  DDL for Procedure CASE_DIVIDE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CASE_DIVIDE" (p_in_appl_no      in char,
                                        p_in_processor_no in char,
                                        p_in_force        in char,
                                        p_out_msg         out varchar2) is
  v_count number;
  processor_name varchar2(20);
begin
  /*
  ModifyDate : 104/09/16
  Desc: Department Major Assign Project:
        科長分案
  6/30: 它科退辦時,主管分案,代碼仍為"他科退辦'
  104/09/16 : show the project processor_no form 193 table ,not 190 spt31
  */

  SELECT COUNT(1) INTO v_count FROM APPL WHERE APPL_NO = p_in_appl_no;

  if v_count = 0 then
    p_out_msg := '案號 ' || p_in_appl_no || ' 不存在';
    return;
  end if;

  /*
   SELECT COUNT(1)
    INTO v_count
    FROM SPT21
   WHERE SPT21.APPL_NO = p_in_appl_no
     AND ( OBJECT_ID IN (SELECT PROCESSOR_NO
                            FROM SPM63
                           WHERE DEPT_NO = '70012'
                             AND QUIT_DATE IS NULL)
           OR OBJECT_ID = '70012'  OR OBJECT_ID = '60037'     );
           
    if v_count = 0 then
      p_out_msg := '案件 ' || p_in_appl_no || ' 不是科內持有';
    return;
  end if;
  */

  SELECT COUNT(1)
    INTO v_count
    FROM SPT21
   WHERE SPT21.APPL_NO = p_in_appl_no
     AND PROCESS_RESULT IS NULL;

  if v_count > 0 then
    p_out_msg := '案件 ' || p_in_appl_no || ' 待辦中,不可分案';
    return;
  end if;

  SELECT COUNT(1)
    INTO v_count
    FROM SPT31
   WHERE APPL_NO = p_in_appl_no
     AND SCH_PROCESSOR_NO IN (SELECT PROCESSOR_NO
                                FROM SPM63
                               WHERE QUIT_DATE IS NULL);

  if v_count > 0 and p_in_force != 'Y' then
  
    select name_c into processor_name
    from spm63 where processor_no = (select processor_no from appl where appl_no = p_in_appl_no);
  
    p_out_msg := '此案件已有承辦人'|| processor_name || '，是否要強制分案?';
    return;
  end if;

  UPDATE APPL
     SET DIVIDE_CODE  = case when DIVIDE_CODE = '3' then '3' else '4' end,
         ASSIGN_DATE  = TO_CHAR(TO_NUMBER(TO_CHAR(SYSDATE, 'YYYYMMDD')) -
                                19110000),
         PROCESSOR_NO = p_in_processor_no
   WHERE APPL_NO = p_in_appl_no;

/* 
-- 104/09/21 cancel update spt31.sch_processor_no
  UPDATE SPT31
     SET SCH_PROCESSOR_NO = p_in_processor_no
   WHERE APPL_NO = p_in_appl_no;
*/
  p_out_msg := '案號 ' || p_in_appl_no || '分辦成功';
  return;

end case_divide;

/
--------------------------------------------------------
--  DDL for Procedure CASE_FINISH_OTHER_SESSION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CASE_FINISH_OTHER_SESSION" (p_in_appl_no      in char,
                                                      p_in_processor_no in char,
                                                      p_out_msg         out varchar2) is

  v_OUT_MSG number;
begin
  /*
  MOdify : 2015/05/11
  change appl status to finish which is assigned by other session
  */

  update appl
     set DIVIDE_CODE = '0', FINISH_FLAG = '1'
   where appl_no = p_in_appl_no;

  SEND_APPL_TO_EARLY_PUBLICATION(p_in_processor_no,
                                 p_in_appl_no,
                                 '1',
                                 null,
                                 v_OUT_MSG);

  p_out_msg := p_in_appl_no || ' 設定完成成功';

end CASE_FINISH_OTHER_SESSION;

/
--------------------------------------------------------
--  DDL for Procedure CASE_LIST
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CASE_LIST" (p_in_divide_code in varchar2,
                                      p_in_proccess_no in varchar2,
                                      p_out_list       out sys_refcursor) is
begin
/**
  ModifyDate : 104/07/23
  Desc : Project List 
  Parameter : p_in_divide_code : project kind 
              p_in_processor_no : prject processor ,the same as spt31.sch_processor_no
              p_out_list : project list of the processor or the whole department
  ModifyItems
  (1) change the condition for get file_lim_date
  (2) get name for processor instand of number
  104/07/23 : change conditoin for project  processor_no ,change from spt31.sch_processor_no to appl.appl_no
*/

  open p_out_list for
    select p.APPL_NO, -- 案號
           S11.NAME_C as APPLIER_ID, -- 申請人
           appl.assign_date as ASSIGN_DATE, -- 分辦日期
           s41.FILE_LIM_DATE as FILE_LIM_DATE, -- 檔管日期
          ( select name_c from spm63 where processor_no = appl.processor_no ) as processor_no,
          case when  appl.divide_code in ('1','2')  then   appl.DIVIDE_REASON
              when   appl.divide_code = '3' then N'他科退辦'
              when  appl.divide_code = '4' then N'主管分辦'
              else N'其它'
          end  divide_reason
      from appl
      join spt31 p
        on appl.appl_no = p.appl_no
      left join spt31A pa
        on p.appl_no = pa.appl_no
      left join SPM75 t
        on t.type_no = pa.type_no
      LEFT JOIN (SELECT SPM11.APPL_NO,
                        SPM11.ID_NO,
                        SPM11.NAME_C,
                        NATIONAL_ID
                   FROM AP.SPM11
                  WHERE SPM11.ID_TYPE = '1'
                    AND SPM11.SORT_ID = '1') S11
        ON appl.APPL_NO = S11.APPL_NO
     LEFT JOIN SPT41 s41 
      on p.appl_no = s41.appl_no
     where  s41.issue_no = (select max(issue_no) from spt41 where appl_no = p.appl_no)
      and nvl(appl.divide_code,'0') =  case when   p_in_divide_code = '9' then '1' else  p_in_divide_code end
       and case
             when p_in_divide_code in ('1','9') then
              nvl(is_overtime,'0')
             else
              '1'
           end = case when   p_in_divide_code = '9' then '2' else  '1' end
        and ( appl.processor_no = p_in_proccess_no
             or p_in_proccess_no is null)
        ;

end CASE_LIST;

/
--------------------------------------------------------
--  DDL for Procedure CASE_MARK_UNUSUAL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CASE_MARK_UNUSUAL" (p_in_unusual    in varchar2,
                                              p_in_receive_no in char) is
  -- 標示程序覆核

begin

  UPDATE RECEIVE
     SET UNUSUAL = p_in_unusual
   WHERE RECEIVE_NO = p_in_receive_no;

end case_mark_unusual;

/
--------------------------------------------------------
--  DDL for Procedure CASE_REMOVE_OVERTIME
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CASE_REMOVE_OVERTIME" (p_in_appl_no in char,
                                                 p_status in char,
                                                 p_out_msg    out varchar2) is
  l_status char(1);
  l_in_appl_no char(15);
begin
  /*
  ModifyDate : 2015/05/21
  Desc:remove appl overtime status
  5/21 : add parameter p_status for judge is delete overtime status or remove overtime
  */

  
  l_status := trim(p_status);
  l_in_appl_no := trim(p_in_appl_no);
  
  IF l_status = '1' then 
     update appl set is_overtime = '2' where appl_no = l_in_appl_no;
     p_out_msg := l_in_appl_no || ' 移除逾期成功';
  END IF;

  IF l_status = '2' then 
     update appl set is_overtime = '0', divide_code = '0', assign_date = null where appl_no = l_in_appl_no;
     p_out_msg := l_in_appl_no || ' 刪除逾期狀態成功';
  END IF;
  

end CASE_REMOVE_OVERTIME;

/
--------------------------------------------------------
--  DDL for Procedure CASE_REMOVE_POSTPONE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CASE_REMOVE_POSTPONE" (p_in_receive_no in char,
                                                 p_out_msg       out varchar2) is

begin
  /*
  MOdifyDate: 2015/05/26
  remove receive postpone status
  remove postpone reason  
   */

  update receive set is_postpone = '0' , post_reason = null where receive_no = p_in_receive_no;

  delete appl_para
   where sys = 'POSTPONE'
     and subsys = p_in_receive_no;

  p_out_msg := p_in_receive_no || ' 移除緩辦成功';

end CASE_REMOVE_POSTPONE;

/
--------------------------------------------------------
--  DDL for Procedure CASE_TO_ONLINE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CASE_TO_ONLINE" (p_in_receive_no   in char,
                                           p_in_processor_no in char,
                                           p_in_step_code    in char,
                                           p_out_msg         out varchar2) is
  v_count      number;
  v_validation varchar2(100);
  v_appl_no    spt21.appl_no%type;
begin
/*
  ModifyDate : 104/09/09
  Desc: transfer receive from paper to online mode
   change receive_trans_log schema
  ModifyItem:
  104/07/09: step code is wrong in log 
  104/08/26: update spt21.dept_no ='70012'
  104/08/27: when doc exists the receive_no then doc_complete = 1
  104/09/09: exclude the receives which process_result= 57001
*/
  SELECT COUNT(1)
    INTO v_count
    FROM SPT21
   WHERE ONLINE_FLG = 'Y'
     AND RECEIVE_NO = p_in_receive_no
     ;
  if v_count > 0 then
    p_out_msg := '已為線上文件';
    return;
  end if;


  v_validation := case_valid_convert(p_in_receive_no, p_in_processor_no);

  if v_validation is not null then
    p_out_msg := v_validation;
    return;
  end if;

  ---------------------
    -- record receive transfer history
    ---------------------
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = SPT21.receive_no ),'1') seq , 
              SPT21.receive_no, SPT21.appl_no , SPT21.processor_no,trim(p_in_step_code),sysdate,'紙本轉線上'
      from SPT21
       Where receive_no = p_in_receive_no
      ;

  UPDATE SPT21
     SET ONLINE_COUT = 'Y', ONLINE_FLG = 'Y' ,DEPT_NO='70012' , processor_no = p_in_processor_no
   WHERE RECEIVE_NO = p_in_receive_no
   ;

  INSERT INTO RECEIVE
    SELECT RECEIVE_NO,
           APPL_NO,
           trim(p_in_step_code),
           '0',
           '1',
           '1',
           NULL,
           NULL,
           0,
           case when exists (select 1 from doc where trim(receive_no) = trim(p_in_receive_no)) then 1 else  0 end as doc_complete,
           case when trim(p_in_processor_no) = '70012' then 'D' else '0' end as return_no,
           trim(p_in_processor_no),
           object_id,
           to_char(to_number(to_char(sysdate, 'yyyyMMdd')) - 19110000),
           NULL,
           null
      FROM SPT21
     WHERE RECEIVE_NO = p_in_receive_no
     ;
 
   CHECK_RECEIVE('0',v_count,p_out_msg);
 
  p_out_msg := '轉換 ' || trim(p_in_receive_no) || ' 成功';
 SYS.Dbms_Output.Put_Line(p_out_msg);

end case_to_online;

/
--------------------------------------------------------
--  DDL for Procedure CASE_TO_PAPER
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CASE_TO_PAPER" (p_in_receive_no   in char,
                                          p_in_processor_no in char,
                                          p_out_msg         out varchar2) is
  v_count      number;
  v_validation varchar2(100);
  v_appl_no    spt21.appl_no%type;
begin
/*
  ModifyDate : 104/09/18
  Desc: transfer receive from online to paper mode
  change receive_trans_log schema
  104/09/18 : update appl.online_flg
*/

  SELECT COUNT(1)
    INTO v_count
    FROM SPT21
   WHERE ONLINE_FLG = 'N'
     AND RECEIVE_NO = p_in_receive_no;

  if v_count > 0 then
    p_out_msg := '已為紙本文件';
    return;
  end if;

  v_validation := case_valid_convert(p_in_receive_no, p_in_processor_no);

  if v_validation is not null then
    p_out_msg := v_validation;
    return;
  end if;
  
   ---------------------
    -- record receive transfer history
    ---------------------
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),1) seq , 
              receive.receive_no, receive.appl_no , receive.processor_no,null,sysdate,'線上轉紙本'
      from receive
       Where receive_no = p_in_receive_no;

  UPDATE SPT21
     SET ONLINE_COUT = 'N', ONLINE_FLG = 'N'
   WHERE RECEIVE_NO = p_in_receive_no;

  DELETE RECEIVE WHERE RECEIVE_NO = p_in_receive_no;
  DELETE tmp_get_receive  WHERE RECEIVE_NO = p_in_receive_no; 
  commit;
   -----------------------------
    -- 線上審查註記
    -- add by susan tseng 104.09.18
    -----------------------------
    update appl set appl.online_flg = '0' 
    where not exists (select 1 from receive where receive.appl_no = appl.appl_no)
    and appl.online_flg = '1' 
    ;
    commit;
      p_out_msg := '轉換 ' || trim(p_in_receive_no) || ' 成功';
 SYS.Dbms_Output.Put_Line(p_out_msg);
   
--  p_out_msg := '轉換 ' || p_in_receive_no || ' 成功';

end case_to_paper;

/
--------------------------------------------------------
--  DDL for Procedure CASE_TO_POSTPONE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CASE_TO_POSTPONE" (p_in_receive_no in char,
                                             p_postpone      in char,
                                             p_reason        in varchar2,
                                             p_out_msg       out varchar2) is
  v_count      number;
  v_validation varchar2(100);
  v_appl_no    spt21.appl_no%type;

begin
  /*
  MOdify : 2015/05/26
  Update receive.is_postpone =1:等來文、2:等規費、3:等圖檔、4:其它原因  
  Modify Item:
  (1) check if data exist in para ,use update  or  insert
  */
  if p_postpone = '3' then
    update receive set is_postpone = p_postpone , post_reason =  p_reason ,  doc_complete = '0'  
    where receive_no = p_in_receive_no;
 else
    update receive set is_postpone = p_postpone , post_reason =  p_reason 
    where receive_no = p_in_receive_no;
 end if;

  select count(1) into v_count
  from appl_para
  where sys = 'POSTPONE' and trim(subsys) = trim(p_in_receive_no);
  
  if v_count = 0 then 
      insert into appl_para   (sys, subsys, para_no)
        values  ('POSTPONE', p_in_receive_no, to_char(sysdate, 'yyyyMMdd'));
   else
      update appl_para set para_no = to_char(sysdate, 'yyyyMMdd') where sys = 'POSTPONE' and subsys = p_in_receive_no; 
   end if;

  p_out_msg := p_in_receive_no || ' 緩辦成功';

end CASE_TO_POSTPONE;

/
--------------------------------------------------------
--  DDL for Procedure CHECK_OVERTIME
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CHECK_OVERTIME" ( p_rec out int)
is
    ecode            number;
    ap_code          varchar2(100);
    p_msg            varchar2(3000);
    rec1 number;
    rec2 number;
    rec_cnt number;
    type APPL_NO_TAB is table of spt41.appl_no%type;
    type FORM_FILE_A_TAB is table of spt41.FORM_FILE_A%type;
    type STEP_CODE_TAB is table of spt31a.step_code%type;  
    type PROCESSOR_NO_TAB is table of spt41.processor_no%type;
    type REASON_TAB is table of varchar2(50);
  
  /*-------------------------------------
  -- ModifyDate : 104/09/17
  -- record project status on 193 system
  --1:個人逾期、2:自動輪辦、
  -- Modify: overtime reason
  -- taketurn processor_no start from the next  of last time recorded in appl_para where sys='OVERTIME' and subsys = 'TAKETURN'
     104/07/22 : not to write back spt31.sch_processor_no
     104/09/17 :(1) modify the return record count 
                (2) if overtime record is exists , do nothing 
  -------------------------------------*/
  PROCEDURE Update_DivideCode(g_app in APPL_NO_TAB,g_form_file_a in FORM_FILE_A_TAB, g_step_code in STEP_CODE_TAB ,g_process_no in PROCESSOR_NO_TAB,g_reason in varchar2)
  is
  begin
    for l_idx in 1 .. g_app.count
      loop
         select count(1) into rec1 from appl where appl_no = g_app(l_idx)  ;
         --- 已逾期或移除逾期 不用再列入
         select count(1) into rec2 from appl where appl_no = g_app(l_idx) and is_overtime ='0' and divide_code = '0';
         
         insert into tmp_appl_overtime values( g_app(l_idx),g_form_file_a(l_idx),g_step_code(l_idx),g_process_no(l_idx),g_reason);
         
         if rec1 = 0  then
            insert into appl
                select g_app(l_idx) ,  g_step_code(l_idx) ,'1',g_reason,null,0,1,'1',null,to_char(to_number(to_char(sysdate,'yyyyMMdd'))-19110000), g_process_no(l_idx),null,'0'
                from dual; 
              
         --   dbms_output.put_line('新增:逾期 ' || g_app(l_idx) || ':' || g_step_code(l_idx) || ':' || g_process_no(l_idx)); 
          end if;
          if rec1 !=0 and rec2>0 then
             update appl
              set step_code =  g_step_code(l_idx), divide_code = '1' , processor_no = g_process_no(l_idx), IS_OVERTIME = '1',divide_reason = g_reason
              where appl_no =  g_app(l_idx)
              and divide_code != '1'; 
            
         --    dbms_output.put_line('修改:逾期 ' ||  g_app(l_idx) || ':' || g_step_code(l_idx) || ':' || g_process_no(l_idx)); 
          end if;
           rec_cnt := rec_cnt + 1;
      end loop;
     commit;
  end Update_DivideCode;
    --1:個人逾期、2:自動輪辦、
  PROCEDURE Update_TakeTurn(g_app in APPL_NO_TAB,g_form_file_a in FORM_FILE_A_TAB, g_step_code in STEP_CODE_TAB ,g_process_no in PROCESSOR_NO_TAB,g_reason in REASON_TAB)
  is
  begin
    for l_idx in 1 .. g_app.count
      loop
         select count(1) into rec1 from appl where appl_no = g_app(l_idx) ;
         -------
         -- for check
         --------
         insert into tmp_appl_overtime values( g_app(l_idx),g_form_file_a(l_idx),g_step_code(l_idx),g_process_no(l_idx),g_reason(l_idx));
        
         if rec1 = 0  then
            insert into appl
                select g_app(l_idx) ,  g_step_code(l_idx) ,'2',g_reason(l_idx),null,0,1,'0',null,to_char(to_number(to_char(sysdate,'yyyyMMdd'))-19110000), g_process_no(l_idx),null,'0'
                from dual; 
               
        --    dbms_output.put_line('新增:自動輪辦 ' || g_app(l_idx) || ':' || g_step_code(l_idx) || ':' || g_process_no(l_idx)); 
          else
            update appl
              set step_code =  g_step_code(l_idx), divide_code = '2' , processor_no =null, ASSIGN_DATE = null, IS_OVERTIME = '1' ,divide_reason = g_reason(l_idx)
              where appl_no =  g_app(l_idx)
              and divide_code != '2'; 
           
          --   dbms_output.put_line('修改:自動輪 ' ||  g_app(l_idx) || ':' || g_step_code(l_idx) || ':' || g_process_no(l_idx)); 
          end if;
           rec_cnt := rec_cnt + 1;
      end loop;
     commit;
  end Update_TakeTurn;
 ---------------------------
 --  新案-初審程序審查, 自動輪辦
 --  先判斷是否要進入自動輪辦,再判斷是否個人逾期
 ---------------------------
PROCEDURE Check_Case1_1
  -- 
  is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
     v_reason REASON_TAB;
BEGIN
     ap_code := 'case1_1';
         
-- 自動輪辦
 
     select s41.appl_no,s41.form_file_a ,s56.step_code, s41.processor_no, case when substr(s41.processor_no,1,1) ='P' then '新申請案外包輪辦' else '新申請案離職輪辦' end 
            bulk collect
            into v_app, v_form_file_a, v_step_code ,v_process_no,v_reason
     from spt41 s41
    join 
    (
    select max(spm56.form_file_a) form_file_a, spm56.appl_no , s31a.type_no ,s31a.step_code
    from spm56 join spt31a s31a on spm56.appl_no = s31a.appl_no
    where  spm56.form_id = 'A02'
    and s31a.step_code = '10'
    group by spm56.appl_no  , s31a.type_no  ,s31a.step_code
    ) s56 on s41.form_file_a = s56.form_file_a and s41.appl_no = s56.appl_no
    left join 
    (
      select appl_no , 
          (case   
               when  (substr(appl_no,4,1) = '1' OR substr(appl_no,4,1) = '2') and  sysdate> add_months(to_date(min(PRIORITY_DATE),'yyyyMMdd'),16 )
                    then 1
               when  (substr(appl_no,4,1) = '3' OR (substr(appl_no,4,1) = '3' and substr(appl_no,10,1) = 'D' )) and  sysdate> add_months(to_date(min(PRIORITY_DATE),'yyyyMMdd'),10 )
                    then 1
              else 0
          end) isOverTime   
      from spt32 
      where    PRIORITY_DOC_FLAG is  null  
               and ACCESS_CODE   is  null  
               and PRIORITY_DATE is not null
               and priority_flag = '1'
      group by appl_no     
    ) s32 on s32.appl_no = s41.appl_no
     left join 
    (
     select appl_no ,sum( case when PRIORITY_DATE is  null then 0
                      else 1 end) cnt
      from spt32 
      where  priority_flag = '1'
       group by appl_no
    ) s32_2  on s32_2.appl_no = s41.appl_no
     left join 
    (
     select appl_no ,sum( case when (PRIORITY_DATE is not null  
               and  (ACCESS_CODE  is not  null  or PRIORITY_DOC_FLAG is not  null)) then 0
            else 1 end) cnt
      from spt32 
       where  priority_flag = '1'
      group by appl_no
    ) s32_3  on s32_3.appl_no = s41.appl_no
    where   trunc(sysdate) > case  when  valid_tw_date2(FILE_LIM_DATE)=0  then  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20 )
                           else  trunc(to_date('21991231','yyyyMMdd') )
                      end   
     and  (s32.isOverTime = '1'  or s32_2.cnt =0  or s32_3.cnt =0)
     and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
     and  exists (select 1 from spm63 where   (processor_no = s41.processor_no or substr(s41.processor_no,1,1)='P' ) and quit_date is not null)
     -- and s41.appl_no = '103112248' -- for test
    ;
   --   dbms_output.put_line('新案,自動輪辦:' || v_app.count);
    Update_TakeTurn(v_app ,v_form_file_a, v_step_code ,v_process_no,v_reason);
  --   dbms_output.put_line('新案,自動輪辦:');
      
END Check_Case1_1;
 ---------------------------
 --  新案-初審程序審查,逾期
 --  先判斷是否要進入自動輪辦,再判斷是否個人逾期
 ---------------------------------
PROCEDURE Check_Case1_2
  -- 
  is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
BEGIN
     ap_code := 'case1_2';
     
    ----------------
    -- '新案,逾期:'
    ---------------
   select s41.appl_no, s41.form_file_a , s56.step_code, s41.processor_no
    bulk collect
    into v_app ,v_form_file_a, v_step_code ,v_process_no
    from spt41 s41
    join 
    (
    select max(spm56.form_file_a) form_file_a, spm56.appl_no , s31a.type_no ,s31a.step_code
    from spm56 join spt31a s31a on spm56.appl_no = s31a.appl_no
    where  spm56.form_id = 'A02'
    and s31a.step_code = '10'
    group by spm56.appl_no  , s31a.type_no  ,s31a.step_code
    ) s56 on s41.form_file_a = s56.form_file_a and s41.appl_no = s56.appl_no
    left join 
    (
      select appl_no , 
          (case 
               when  (substr(appl_no,4,1) = '1' OR substr(appl_no,4,1) = '2') and  sysdate> add_months(to_date(min(PRIORITY_DATE),'yyyyMMdd'),16 )
                    then 1
               when  (substr(appl_no,4,1) = '3' OR (substr(appl_no,4,1) = '3' and substr(appl_no,10,1) = 'D' )) and  sysdate> add_months(to_date(min(PRIORITY_DATE),'yyyyMMdd'),10 )
                    then 1
              else 0
          end) isOverTime   
      from spt32 
      where    PRIORITY_DOC_FLAG is  null  
               and ACCESS_CODE   is  null  
               and PRIORITY_DATE is not null
               and priority_flag = '1'
      group by appl_no     
    ) s32 on s32.appl_no = s41.appl_no
    left join 
    (
     select appl_no ,sum( case when PRIORITY_DATE is  null then 0
                      else 1 end) cnt
      from spt32 
      where  priority_flag = '1'
       group by appl_no
    ) s32_2  on s32_2.appl_no = s41.appl_no
     left join 
    (
     select appl_no ,sum( case when (PRIORITY_DATE is not null  
               and  (ACCESS_CODE  is not  null  or PRIORITY_DOC_FLAG is not  null)) then 0
            else 1 end) cnt
      from spt32 
       where  priority_flag = '1'
      group by appl_no
    ) s32_3  on s32_3.appl_no = s41.appl_no
    where   trunc(sysdate) > case  when  valid_tw_date2(FILE_LIM_DATE)=0  then  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20 )
                           else  trunc(to_date('21991231','yyyyMMdd') )
                      end   
     and  (s32.isOverTime = '1'  or s32_2.cnt =0  or s32_3.cnt =0)
     and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
      and  exists (select 1 from spm63 where  processor_no = s41.processor_no  and quit_date is  null)
      and  substr(s41.processor_no,1,1)!='P'
  --    and s41.appl_no in ('103302035','103210096','103121597','103117249','103301997') -- for test
      ;

     Update_DivideCode(v_app,v_form_file_a , v_step_code ,v_process_no,'新案逾期');
 --   dbms_output.put_line('新案,逾期:');
 
END Check_Case1_2;
  
  ----------------------------
  --再審程序審查
  -----------------------------
  PROCEDURE Check_Case2_1
  --
  is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
     v_reason REASON_TAB;
  BEGIN
   ap_code := 'case2_1';
         
   
      -- 自動輪辦
  
      select s41.appl_no, s41.form_file_a,s56.step_code, s41.processor_no ,'離職人員再審輪辦'
            bulk collect
            into v_app,v_form_file_a, v_step_code ,v_process_no,v_reason
      from spt41 s41
     join 
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no , s31a.type_no ,s31a.step_code
      from spm56 join spt31a s31a on spm56.appl_no = s31a.appl_no
      where  spm56.form_id = 'A04'
      and s31a.step_code = '30'
      group by spm56.appl_no  , s31a.type_no  ,s31a.step_code
      ) s56 on s41.form_file_a = s56.form_file_a and s41.appl_no = s56.appl_no
      left join spt32 on spt32.appl_no = s41.appl_no
      where (spt32.data_seq = (select max(s32.data_seq) from spt32 s32 where spt32.appl_no= s32.appl_no) or spt32.data_seq is null)
      and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
      --and sysdate > to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20
      and trunc(sysdate) > case when valid_tw_date2(FILE_LIM_DATE)=1  then trunc(to_date('21991231','yyyyMMdd'))  else  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20) end
      and exists (select 1 from spm63 where processor_no = s41.processor_no and quit_date is not  null)
      ;
 
      Update_TakeTurn(v_app ,v_form_file_a, v_step_code ,v_process_no,v_reason);
  --   dbms_output.put_line('審查自動輪辦');
      
  END Check_Case2_1;
  
  PROCEDURE Check_Case2_2
  --
  is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
  BEGIN
   ap_code := 'case2_2';
        
     ---再審,逾期
       select s41.appl_no , s41.form_file_a,s56.step_code, s41.processor_no
         bulk collect
         into v_app ,v_form_file_a , v_step_code ,v_process_no
     from spt41 s41
     join 
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no , s31a.type_no ,s31a.step_code
      from spm56 join spt31a s31a on spm56.appl_no = s31a.appl_no
      where  spm56.form_id = 'A04'
      and s31a.step_code = '30'
      group by spm56.appl_no  , s31a.type_no  ,s31a.step_code
      ) s56 on s41.form_file_a = s56.form_file_a and s41.appl_no = s56.appl_no
      left join spt32 on spt32.appl_no = s41.appl_no
      where (spt32.data_seq = (select max(s32.data_seq) from spt32 s32 where spt32.appl_no= s32.appl_no) or spt32.data_seq is null)
      and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
      --and sysdate > to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20
      and trunc(sysdate) > case when valid_tw_date2(FILE_LIM_DATE)=1  then trunc(to_date('21991231','yyyyMMdd'))  else  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20) end
      and exists (select 1 from spm63 where  processor_no = s41.processor_no and quit_date is  null)
  --    and s41.appl_no in ('101305523','101150129','102115604')  -- for test
      ;
     Update_DivideCode(v_app ,v_form_file_a, v_step_code ,v_process_no,'再審逾期');
    --    dbms_output.put_line('再審逾期:');
 
  END Check_Case2_2;
  
  ----------------------------
  -- 待實體審查
  -----------------------------
  PROCEDURE Check_Case3_1
  --  
  is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
     v_reason REASON_TAB;
  BEGIN
  ap_code := 'case3_1';
         
      
     select s41.appl_no, s41.form_file_a,s56.step_code, s41.processor_no ,'離職人員實體審查輪辦'
            bulk collect
            into v_app,v_form_file_a, v_step_code ,v_process_no,v_reason
      from spt41 s41
      join 
      (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no , s31a.type_no ,s31a.step_code
      from spm56 join spt31a s31a on spm56.appl_no = s31a.appl_no
      where ( spm56.form_id = 'P18' or spm56.form_id = 'P19' )
      and s31a.step_code = '16'
      group by spm56.appl_no  , s31a.type_no  ,s31a.step_code
      ) s56 on s41.form_file_a = s56.form_file_a and s41.appl_no = s56.appl_no
      where (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
      and trunc(sysdate) > case when valid_tw_date2(FILE_LIM_DATE)=1  then trunc(to_date('21991231','yyyyMMdd'))  else  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20) end
      and not exists ( select 1 from spm56 where spm56.appl_no = s56.appl_no and spm56.form_id = 'P32')
      and s41.appl_no >= '091132001'
      and exists (select 1 from spm63 where  processor_no = s41.processor_no and quit_date is not null)
   --   and s41.appl_no >= '091132001'
      ;     
   
        
     Update_TakeTurn(v_app,v_form_file_a , v_step_code ,v_process_no,v_reason);
  --   dbms_output.put_line('離職人員實體審查輪辦');
 
  END check_case3_1;
  
  PROCEDURE Check_Case3_2
  --  
  is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
  BEGIN
  ap_code := 'case3_2';
         

      select s41.appl_no , s41.form_file_a,s56.step_code, s41.processor_no
         bulk collect
         into v_app, v_form_file_a , v_step_code ,v_process_no
      from spt41 s41
      join 
      (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no , s31a.type_no ,s31a.step_code
      from spm56 join spt31a s31a on spm56.appl_no = s31a.appl_no
      where ( spm56.form_id = 'P18' or spm56.form_id = 'P19' )
      and s31a.step_code = '16'
      group by spm56.appl_no  , s31a.type_no  ,s31a.step_code
      ) s56 on s41.form_file_a = s56.form_file_a and s41.appl_no = s56.appl_no
      where (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
      and trunc(sysdate) > case when valid_tw_date2(FILE_LIM_DATE)=1  then trunc(to_date('21991231','yyyyMMdd'))  else  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20) end
      and not exists ( select 1 from spm56 where spm56.appl_no = s56.appl_no and spm56.form_id = 'P32')
      and exists (select 1 from spm63 where  processor_no = s41.processor_no and quit_date is  null)
      and s41.appl_no >= '091132001'
      and exists ( select 1 from spt31 where spt31.appl_no = s41.appl_no and spt31.material_appl_date is  null)
      ;
     Update_DivideCode(v_app ,v_form_file_a, v_step_code ,v_process_no,'實體審查逾期');
  --    dbms_output.put_line('實體審查,逾期');
 
  END check_case3_2;
  ----------------------------
  -- 讓與
  -----------------------------
  PROCEDURE Check_Case4_1
  --  
  is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
     v_reason REASON_TAB;
  BEGIN
  ap_code := 'case4_1';
        
   -- 自動輪辦

     
      select s41.appl_no , s41.form_file_a,s56.step_code, s41.processor_no,'離職人員讓與輪辦'
            bulk collect
            into v_app,v_form_file_a, v_step_code ,v_process_no,v_reason
           from  spt41 s41
     join
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no  ,s31a.step_code
      from spm56 
      join spt31a s31a on spm56.appl_no = s31a.appl_no
   --   join spt41 s41 on S41.Form_File_A = spm56.form_file_a 
      where  substr(spm56.appl_no,4,1) = '1' -- 只清查發明案
       and s31a.step_code in ('16','20')
       and s31a.appl_no not in ( select s.appl_no from spt41 s  join spm56 s56 on s.form_file_a = s56.form_file_a
                             where  s.appl_no = s31a.appl_no 
                             and s.issue_no > (select max(issue_no) from spt41 where s.appl_no = spt41.appl_no   and issue_type = '40007')
                             and ( (s.issue_type = '40101' and s56.form_id = 'B38')
                               or ( s.issue_type = '40103' and s56.form_id = 'B38')   
                               or ( s56.form_id  in ('P03-1','A06','P31') )
                               )
                        )
       and exists (select 1 from spt41 s2 where  s2.appl_no =  s31a.appl_no and s2.issue_type = '40007')
      group by spm56.appl_no  , s31a.step_code
       )  s56 on  s41.form_file_a = s56.form_file_a 
      where     ( s41.file_d_flag is null or s41.file_d_flag = ' ')
        and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
   --    and not exists (select 1 from spm56 where spm56.appl_no = s41.appl_no and spm56.form_file_a >s41.form_file_a and spm56.form_id  in ('P03-1','A06','P31'))
      and trunc(sysdate) > case when valid_tw_date2(FILE_LIM_DATE)=1  then trunc(to_date('21991231','yyyyMMdd'))  else  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20) end
       and exists (select 1 from spm63 where  processor_no = s41.processor_no  and quit_date is not null )
    ;
   Update_TakeTurn(v_app ,v_form_file_a, v_step_code ,v_process_no,v_reason);
 --   dbms_output.put_line('讓與,自動輪辦:');
 
  END Check_Case4_1;
  
  
   PROCEDURE Check_Case4_2
  --  
  is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
  BEGIN
  ap_code := 'case4_2';
        
     select s41.appl_no , s41.form_file_a,s56.step_code, s41.processor_no
         bulk collect
         into v_app,v_form_file_a , v_step_code ,v_process_no
      from  spt41 s41
     join
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no  ,s31a.step_code
      from spm56 
      join spt31a s31a on spm56.appl_no = s31a.appl_no
   --   join spt41 s41 on S41.Form_File_A = spm56.form_file_a 
      where  substr(spm56.appl_no,4,1) = '1' -- 只清查發明案
       and s31a.step_code in ('16','20')
       and s31a.appl_no not in ( select s.appl_no from spt41 s  join spm56 s56 on s.form_file_a = s56.form_file_a
                             where  s.appl_no = s31a.appl_no 
                             and s.issue_no > (select max(issue_no) from spt41 where s.appl_no = spt41.appl_no   and issue_type = '40007')
                             and ( (s.issue_type = '40101' and s56.form_id = 'B38')
                               or ( s.issue_type = '40103' and s56.form_id = 'B38')   
                               or ( s56.form_id  in ('P03-1','A06','P31') )
                               )
                        )
       and exists (select 1 from spt41 s2 where  s2.appl_no =  s31a.appl_no and s2.issue_type = '40007')
      group by spm56.appl_no  , s31a.step_code
       )  s56 on  s41.form_file_a = s56.form_file_a 
      where     ( s41.file_d_flag is null or s41.file_d_flag = ' ')
        and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
   --    and not exists (select 1 from spm56 where spm56.appl_no = s41.appl_no and spm56.form_file_a >s41.form_file_a and spm56.form_id  in ('P03-1','A06','P31'))
      and trunc(sysdate) > case when valid_tw_date2(FILE_LIM_DATE)=1  then trunc(to_date('21991231','yyyyMMdd'))  else  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20) end
       and exists (select 1 from spm63 where  processor_no = s41.processor_no  and quit_date is  null )
   ;
    Update_DivideCode(v_app,v_form_file_a , v_step_code ,v_process_no,'讓與逾期');
   --    dbms_output.put_line('讓與,逾期:');


  END check_case4_2;
  ----------------------------
  -- 變更
  -----------------------------
PROCEDURE Check_Case5_1
  --  
  is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
     v_reason REASON_TAB;
  BEGIN
  ap_code := 'case5_1';
        
    
     select s41.appl_no , s41.form_file_a,s56.step_code, s41.processor_no,'離職人員變更輪辦'
            bulk collect
            into v_app,v_form_file_a, v_step_code ,v_process_no,v_reason
       from  spt41 s41
     join
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no , s31a.type_no ,s31a.step_code
      from spm56 
      join spt31a s31a on spm56.appl_no = s31a.appl_no
      where  substr(s31a.appl_no,4,1) = '1' -- 只清查發明案
       and s31a.step_code in ('16','20')
        group by spm56.appl_no  , s31a.type_no  ,s31a.step_code
       )  s56 on s41.form_file_a = s56.form_file_a and s41.appl_no = s56.appl_no
      where    s41.appl_no in 
      ( select appl_no
      from  spt41 s41
      where      ( s41.file_d_flag is null or s41.file_d_flag = ' ')
       and s41.issue_type = '40009'
       and  substr(s41.appl_no,4,1) = '1' -- 只清查發明案
       and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
       and not exists ( select 1 from spm56 where spm56.appl_no = s41.appl_no and spm56.form_id in ('C09','C09-1','C09-2','C09-3','C10','P03-1','A06','P32') )
       and (select count(1) from spt41  where spt41.appl_no = s41.appl_no and spt41.process_result is null) =0
       )
      and trunc(sysdate) > case when valid_tw_date2(FILE_LIM_DATE)=1  then trunc(to_date('21991231','yyyyMMdd'))  else  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20) end
      and exists (select 1 from spm63 where processor_no = s41.processor_no  and quit_date is not  null )
      ;
     Update_TakeTurn(v_app,v_form_file_a , v_step_code ,v_process_no,v_reason);
   --    dbms_output.put_line('變更,輪辦:');

 
  END Check_Case5_1;
  
  PROCEDURE Check_Case5_2
  --  
  is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
  BEGIN
  ap_code := 'case5_2';
        
    
      select s41.appl_no,s41.form_file_a,s56.step_code, s41.processor_no
         bulk collect
         into v_app ,v_form_file_a, v_step_code ,v_process_no
       from  spt41 s41
     join
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no , s31a.type_no ,s31a.step_code
      from spm56 
      join spt31a s31a on spm56.appl_no = s31a.appl_no
      where  substr(s31a.appl_no,4,1) = '1' -- 只清查發明案
       and s31a.step_code in ('16','20')
        group by spm56.appl_no  , s31a.type_no  ,s31a.step_code
       )  s56 on s41.form_file_a = s56.form_file_a and s41.appl_no = s56.appl_no
      where    s41.appl_no in 
      ( select appl_no
      from  spt41 s41
      where     ( s41.file_d_flag is null or s41.file_d_flag = ' ')
       and s41.issue_type = '40009'
       and  substr(s41.appl_no,4,1) = '1' -- 只清查發明案
       and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
       and not exists ( select 1 from spm56 where spm56.appl_no = s41.appl_no and spm56.form_id in ('C09','C09-1','C09-2','C09-3','C10','P03-1','A06','P32') )
       and (select count(1) from spt41  where spt41.appl_no = s41.appl_no and spt41.process_result is null) =0
       )
      and trunc(sysdate) > case when valid_tw_date2(FILE_LIM_DATE)=1  then trunc(to_date('21991231','yyyyMMdd'))  else  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20) end
    --   and s41.appl_no in ('100102735','101116862','101116442')    -- for test
       and exists (select 1 from spm63 where processor_no = s41.processor_no  and quit_date is  null )
      ;
     Update_DivideCode(v_app ,v_form_file_a , v_step_code ,v_process_no,'變更逾期');
    --   dbms_output.put_line('變更,逾期:');

 
  END Check_Case5_2;
----------------------------
-- 延長
-----------------------------
PROCEDURE Check_Case6_1
  --  
is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
     v_reason REASON_TAB;
BEGIN
   ap_code := 'case6_1';
         
     -- 自動輪辦
    
      select s21.appl_no,null,spt31a.step_code, s21.processor_no,'離職人員延長專利權輪辦'
       bulk collect
      into v_app,v_form_file_a , v_step_code ,v_process_no,v_reason
       from spt41 s41
     join spt21 s21 on s21.receive_no  = s41.receive_no
      join spt31a on s21.appl_no = spt31a.appl_no
      where  s41.issue_type = '22210'
      and trunc(sysdate) > trunc(add_months(to_date(to_char(to_number(substr(lpad(trim(s21.RECEIVE_DATE),7,'0'),1,3))+1911) || substr( lpad(trim(s21.RECEIVE_DATE),7,'0'),4,4),'yyyyMMdd'),7))
      and exists (select 1 from spm63 where  processor_no = s41.processor_no and quit_date is null) 
      and not exists ( select 1 from spm56 where spm56.form_file_a = s41.form_file_a and spm56.form_id = 'A06-2')
      and exists
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no 
      from spm56 join spt41 on spm56.form_file_a = spt41.Form_File_A
      where  spm56.form_id = 'E01'
      and exists ( select 1 from spm63 where  processor_no = spt41.processor_no and quit_date is not null)
      and  s41.appl_no = spm56.appl_no 
      group by spm56.appl_no 
      )  
      ;
     Update_TakeTurn(v_app ,v_form_file_a, v_step_code ,v_process_no,v_reason);
   --  dbms_output.put_line('延長,自動輪辦');
 
  END Check_Case6_1;
  
  PROCEDURE Check_Case6_2
  --  
is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
BEGIN
   ap_code := 'case6_2';
         
      select s21.appl_no,null,spt31a.step_code, s21.processor_no
       bulk collect
      into v_app ,v_form_file_a, v_step_code ,v_process_no
       from spt41 s41
     join spt21 s21 on s21.receive_no  = s41.receive_no
      join spt31a on s21.appl_no = spt31a.appl_no
      where  s41.issue_type = '22210'
      and trunc(sysdate) > trunc(add_months(to_date(to_char(to_number(substr(lpad(trim(s21.RECEIVE_DATE),7,'0'),1,3))+1911) || substr( lpad(trim(s21.RECEIVE_DATE),7,'0'),4,4),'yyyyMMdd'),7))
      and exists (select 1 from spm63 where  processor_no = s41.processor_no and quit_date is null) 
      and not exists ( select 1 from spm56 where spm56.form_file_a = s41.form_file_a and spm56.form_id = 'A06-2')
      and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
      and exists
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no 
      from spm56 join spt41 on spm56.form_file_a = spt41.Form_File_A
      where  spm56.form_id = 'E01'
      and exists ( select 1 from spm63 where  processor_no = spt41.processor_no and quit_date is null)
      and  s41.appl_no = spm56.appl_no 
      group by spm56.appl_no 
      ) 
      ;
       Update_DivideCode(v_app ,v_form_file_a, v_step_code ,v_process_no,'延長逾期');
   --   dbms_output.put_line('延長,逾期');
 
  END Check_Case6_2;
  
  PROCEDURE Assign_AutoTurn
  IS
    CURSOR d_curosr IS
      select appl_no from appl where divide_code = '2' and assign_date is null;
      
    type PROCESSOR_NO_TAB is table of appl.processor_no%type;
    v_process_no PROCESSOR_NO_TAB;
    l_appl_no     spt31.appl_no%type;
    l_idx number;
    l_processor_no skill.processor_no%type;
  BEGIN
  
    select trim(processor_no) 
    bulk collect
    into v_process_no
    from skill where auto_shift = '1'
    order by processor_no
    ;
   
      -- record the last assign processor 
     select trim(para_no) into l_processor_no from appl_para where sys = 'OVERTIME' and subsys = 'TAKETURN';
     if l_processor_no is null then
          l_idx := 0;
     else
          select  seq into l_idx
          from
            (
             select skill.processor_no,rownum seq
             from skill 
             where auto_shift = '1'
             order by processor_no
           ) where processor_no = l_processor_no
           ;
            IF l_idx = v_process_no.count THEN
                l_idx := 0;
             END IF;
     end if;
     
   
     OPEN d_curosr;
     LOOP
     FETCH d_curosr
      INTO l_appl_no;
     EXIT WHEN d_curosr%NOTFOUND;
        l_idx := l_idx +1;
      --  SYS.Dbms_Output.Put_Line(v_process_no(l_idx) || ':' || l_appl_no);
         update appl set processor_no = v_process_no(l_idx),
                         assign_date = to_char(to_number(to_char(sysdate,'yyyyMMdd')-19110000))
         where appl_no = l_appl_no;
      --   Dbms_Output.Put_Line(SQL%RowCount|| ': update appl');
      --- 104/07/21 Test Meeting ,decide not to write back to 190 table SPT31
      --    UPDATE SPT31   SET SCH_PROCESSOR_NO =  v_process_no(l_idx)    WHERE APPL_NO = l_appl_no;
       --   Dbms_Output.Put_Line(SQL%RowCount|| ': update SPT31 processor_no : ' ||  v_process_no(l_idx) || '; l_appl_no:' ||l_appl_no);
     
       IF l_idx = v_process_no.count THEN
           l_idx := 0;
       END IF;
     END LOOP;
    
     CLOSE d_curosr;
     
     update  appl_para set para_no =   v_process_no(l_idx) where sys = 'OVERTIME' and subsys = 'TAKETURN' ;
     
  END;

  
BEGIN

  rec_cnt :=0;
   delete  tmp_appl_overtime;
   commit;
 
   check_case1_1;
   -- dbms_output.put_line(' check_case1_1 Finish!!');
   check_case1_2;
   -- dbms_output.put_line(' check_case1_2 Finish!!');   
   check_case2_1;
   --dbms_output.put_line(' check_case2_1 Finish!!');
   check_case2_2;    
   --dbms_output.put_line(' check_case2_2 Finish!!');
   check_case3_1;
   --dbms_output.put_line(' check_case3_1 Finish!!');
   check_case3_2;
   --dbms_output.put_line(' check_case3_2 Finish!!');
   check_case4_1;
   --dbms_output.put_line(' check_case4_1 Finish!!');
   check_case4_2;
   --dbms_output.put_line(' check_case4_2 Finish!!');
   check_case5_1;
   --dbms_output.put_line(' check_case5_1 Finish!!');
   check_case5_2;
   --dbms_output.put_line(' check_case5_2 Finish!!');
   check_case6_1;
   --dbms_output.put_line(' check_case6_1 Finish!!');
   check_case6_2;
   --dbms_output.put_line(' check_case6_2 Finish!!');
   
   Assign_AutoTurn;
   
   commit;
    p_rec := rec_cnt;
   dbms_output.put_line('Finish!!' || p_rec);
EXCEPTION
  WHEN OTHERS THEN
   ecode := SQLCODE;
   p_msg := ap_code || ':' || SQLCODE || ':' || SQLERRM; 
   -- dbms_output.put_line('Error Code:' || ecode || '; Error Message:' || p_msg);
END CHECK_OVERTIME;

/
--------------------------------------------------------
--  DDL for Procedure CHECK_RECEIVE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CHECK_RECEIVE" (is_refresh in char,p_rec  out int,p_out_msg   out varchar2) is
  type receive_no_tab is table of spt21.receive_no%type;
  l_rec        number;
  l_rec2       number;
  g_difference number;
  g_total      number;
  ecode        number;
  g_reason     nvarchar2(100);
  v_rec_no   char(15);
  v_pre_no   char(15);
  l_pre_no   char(15);
  l_pre_no2   char(15);
  v_receive_date char(7);
  l_rec_cnt   number;
 ----------------------------------------
 -- Modify Date: 104/08/07
 -- desc : prepare for receive-getting
 -- Get type_no from spt21
 -- add condition: return_no status
 -- add parameter is_refresh, only when is_refresh is 1 then delete the temp talbe 
 -- 7/7: update error, return_no = '0' , not  0
 -- 104/07/24 -- modify the procedure common_case : delete conditoin to judge national priority 
 -- 104/08/07 -- change conditon of "the same project getting all " 
--               add conditon  doc_complete = '1'       
 -----------------------------------------

  procedure related_case1
  --  主張國內優先權的新申請案之公文列入複雜案件
  --  需判斷件數
   is
  --  v_collect receive_no_tab;
  begin
    insert into tmp_get_receive
    select receive_no , receive_no ,'related_case1_1','MISC_AMEND','主張國內優先權的新申請案之公文','0'
      from receive
     where exists (select appl_no
              from spt32
             where spt32.PRIORITY_NATION_ID = 'TW'
               and spt32.appl_no = receive.appl_no)
       and substr(receive.receive_no, 4, 1) = '2'
       and step_code = '0'
       and doc_complete = '1'
       and return_no not in ('4','A','B','C','D')
       and not exists (select 1 from tmp_get_receive where receive_no = receive.receive_no and is_get = '0')
       ;
       l_rec_cnt := l_rec_cnt +  SQL%RowCount;
      -- 新案續領後續文
      insert into tmp_get_receive
      select receive.receive_no , n.receive_no ,'related_case1_2','MISC_AMEND','主張國內優先權的新申請案之後續文','0'
      from receive
      join  (select appl_no , receive_no
              from receive
              where exists (select 1
                            from spt32
                            where spt32.PRIORITY_NATION_ID = 'TW'
                            and spt32.appl_no = receive.appl_no)
                            and substr(receive.receive_no, 4, 1) = '2'
                            and step_code = '0'
                            and doc_complete = '1'
                            and return_no not in ('4','A','B','C','D')
      ) n
         on receive.receive_no = n.receive_no
     where substr(receive.receive_no, 4, 1) = '3'
        and step_code = '0'
        and doc_complete = '1'
        and return_no not in ('4','A','B','C','D')
        and not exists (select 1 from tmp_get_receive where receive_no = receive.receive_no and is_get = '0')
      ;
   
       dbms_output.put_line(' 主張國內優先權的新申請案之公文列入複雜案件領取 ' || l_rec_cnt);
      commit;
    g_reason := '主張國內優先權的新申請案之公文列入複雜案件領取';
  
  end related_case1;

  procedure related_case2
  --  外包自動退文,和後續文一起領
  --  需整包全領,判斷條件
   is
   -- v_collect receive_no_tab;
  begin
   --dbms_output.put_line('update 外包自動退文');
    update receive
       set return_no = '1', step_code = '0', processor_no = '70012'
     where receive_no in
           (Select distinct a.receive_no
              from receive a
              join receive b
                on a.appl_no = b.appl_no
             where substr(a.processor_no, 1, 1) = 'P'
               And a.step_code = '2'
               and substr(a.receive_no, 4, 1) = '2'
               and a.return_no = '0'
               and exists (select 1
                      from receive b join spt21 s21 on b.receive_no = s21.receive_no
                     where b.appl_no = a.appl_no
                       and substr(b.receive_no, 4, 1) = '3'
                       and b.step_code = '0'
                       and b.doc_complete = '1'
                       and s21.type_no in ('10010','13002','15002','16004','16006',
                                         '24708','17000','24022','24308','21002',
                                         '24004','24010','24018','24028','24060',
                                         '20000','20002','20004','20006','20008',
                                         '20010','24500','24502',
                                         '24714','24716','24712','24720','21400','24706','24710'
                                         ))
                        )
          and not  exists (select 1
                            from spt32
                            where spt32.PRIORITY_NATION_ID = 'TW'
                            and spt32.appl_no = receive.appl_no);
   update spt21
       set  processor_no = '70012'
     where receive_no in
           (Select distinct a.receive_no
              from receive a
              join receive b
                on a.appl_no = b.appl_no
             where substr(a.processor_no, 1, 1) = 'P'
               And a.step_code = '2'
               and substr(a.receive_no, 4, 1) = '2'
               and a.return_no = '0'
               and exists (select 1
                      from receive b join spt21 s21 on b.receive_no = s21.receive_no
                     where b.appl_no = a.appl_no
                       and substr(b.receive_no, 4, 1) = '3'
                       and b.step_code = '0'
                       and b.doc_complete = '1'
                       and s21.type_no in ('10010','13002','15002','16004','16006',
                                         '24708','17000','24022','24308','21002',
                                         '24004','24010','24018','24028','24060',
                                         '20000','20002','20004','20006','20008',
                                         '20010','24500','24502'))
                      );                                         
    commit;                                         
    insert into tmp_get_receive
    select receive_no , pre_no ,'related_case2','MISC_AMEND','外包自動退文,和後續文一起領','0'
      from (Select a.receive_no, a.receive_no pre_no
              from receive a
             where a.return_no = '1'
               And a.step_code = '0'
               and a.doc_complete = '1'
            union all
            Select b.receive_no , c.receive_no pre_no
              from receive b 
              join (select appl_no ,receive_no
                                   from receive a
                                  where a.return_no = '1'
                                    And a.step_code = '0'
                                    and a.doc_complete = '1'
                                    ) c
                  on b.appl_no = c.appl_no
             where substr(b.receive_no, 4, 1) = '3'
               and b.step_code = '0'
               and b.doc_complete = '1'
               )
     ;
     
    
      dbms_output.put_line(' 外包自動退文,和後續文一起領 ' || l_rec_cnt);
    commit;
    g_reason := '外包自動退文,和後續文一起領';

  end related_case2;

  procedure related_case3
  --  退文重新領辦 
    -- 2:查驗人員退辦 3:主管退辦
    -- 判斷條數
    -- 9/4 測試會議,取消 3:主管退辦
   is
  --  v_collect receive_no_tab;
  begin
     insert into tmp_get_receive
    select receive_no , pre_no ,'related_case3_1','MISC_AMEND','退文-全案重新領辦','0'
         from (Select min(a.receive_no) receive_no, min(a.receive_no) pre_no
              from receive a
             where a.return_no in ('2')
               And a.step_code = '0'
               and a.doc_complete = '1'
                and  not exists (select 1 from tmp_get_receive where receive_no = a.receive_no and is_get = '0')
               group by appl_no
            union all
            Select b.receive_no , c.receive_no pre_no
              from receive b 
              join ( Select appl_no , min(receive_no) receive_no
                    from receive a
                     where a.return_no in ('2')
                       And a.step_code = '0'
                       and a.doc_complete = '1'
                        and  not exists (select 1 from tmp_get_receive where receive_no = a.receive_no and is_get = '0')
                       group by appl_no
                                    ) c
                  on b.appl_no = c.appl_no and b.receive_no != c.receive_no
             where substr(b.receive_no, 4, 1) = '3'
               and b.step_code = '0'
               and b.doc_complete = '1'
               )
         
     ;
        l_rec_cnt := l_rec_cnt +  SQL%RowCount;

     
         dbms_output.put_line(' 退文領辦 ' || l_rec_cnt);
       commit;
    g_reason := '退文領辦';

  end related_case3;

  procedure related_case4
  --    改請後續文
  -- 新案+改請,整包領取, 不判斷件數
  -- 後續改請, 後續改請,一般: 不判斷件數
   is
  --  v_collect receive_no_tab;
  begin
    --- 有改請新申請的文,統由具改請新申請權限的人領取新申請和後續文
    insert into tmp_get_receive
    select receive_no  , pre_no ,'related_case4_1','CONVERTING','改請新申請案+改請後續文','0'
      from (select a.receive_no ,a.receive_no  pre_no
              from receive a join spt21 s21 on a.receive_no = s21.receive_no
             where a.step_code = '0'
               and a.doc_complete = '1'
               and substr(a.receive_no, 4, 1) = '2'
               and return_no not in ('4','A','B','C','D')
               and s21.type_no in
                   ('11000', '11002', '11003', '11007', '11010')
              and not exists (select 1
                            from spt32
                            where spt32.PRIORITY_NATION_ID = 'TW'
                            and spt32.appl_no = a.appl_no)
                            and substr(a.receive_no, 4, 1) = '2'
                            and step_code = '0'
                            and doc_complete = '1'
                            and return_no not in ('4','A','B','C','D')
            union all  -- 續領後續文
            select a.receive_no , c.receive_no pre_no
              from receive a join
               (select b.appl_no, b.receive_no
                      from receive b join spt21 s21 on b.receive_no = s21.receive_no
                     where b.step_code = '0'
                       and b.doc_complete = '1'
                       and return_no not in ('4','A','B','C','D')
                       and substr(b.receive_no, 4, 1) = '2'
                       and b.appl_no = b.appl_no
                       and s21.type_no in
                           ('11000', '11002', '11003', '11007', '11010')
                      and not exists (select 1
                            from spt32
                            where spt32.PRIORITY_NATION_ID = 'TW'
                            and spt32.appl_no = b.appl_no)
                            and substr(b.receive_no, 4, 1) = '2'
                            and step_code = '0'
                            and doc_complete = '1'
                            and return_no not in ('4','A','B','C','D')
              ) c   on a.appl_no = c.appl_no
             where a.step_code = '0'
               and a.doc_complete = '1'
               and return_no not in ('4','A','B','C','D')
               and substr(a.receive_no, 4, 1) = '3'
             );
          
             dbms_output.put_line(' 改請新申請案+改請後續文 ' || l_rec_cnt);
        commit;
    g_reason := '改請新申請案+改請後續文';
   
   --------------------
   -- '改請後續文'
   -------------------
       
    insert into tmp_get_receive
     select receive_no  ,( select min(receive_no) from receive where appl_no = a.appl_no and step_code='0' and doc_complete = '1' group by Receive.Appl_No )
          ,'related_case4_2',
    ( select   case when type_no  in ('13003', '21100', '24100') then 'MISC_AMEND'
          else 'CONVERTING_AMEND'         end 
        from spt21 
        where receive_no = ( select min(receive_no) from receive where appl_no = a.appl_no and step_code='0' and doc_complete = '1' group by Receive.Appl_No )
        and appl_no = a.appl_no
      )
      ,  ( select   case when spt21.type_no  in ('13003', '21100', '24100') then '改請後續文-一般'
          else '改請後續文'         end 
        from receive join spt21 on receive.receive_no = spt21.receive_no
        where receive.receive_no = ( select min(receive_no) from receive where appl_no = a.appl_no and step_code='0' and doc_complete = '1' group by Receive.Appl_No )
        and receive.appl_no = a.appl_no
      )
      ,'0'
      from receive a 
      where a.step_code = '0'
       and a.doc_complete = '1'
       and return_no not in ('4','A','B','C','D')
       and substr(a.receive_no, 4, 1) = '3'
       and exists (select 1
              from  spt21 s21 left join receive b on b.receive_no = s21.receive_no
             where s21.appl_no = a.appl_no
               and s21.type_no in
                   ('11000', '11002', '11003', '11007', '11010')
               and ( step_code = '8' or  step_code is null  ))
             ;
 
      g_reason := '改請後續文';
   dbms_output.put_line(' 改請後續文 ' || l_rec_cnt);
          
     commit;
      g_reason := '改請新申請案一般後續文';
    
  end related_case4;

  procedure related_case5
  --    分割後續文
  -- 不判斷件數
   is
    v_collect receive_no_tab;
  begin
  
    --- 有分割新申請的文,統由具分割新申請權限的人領取新申請和後續文
    insert into tmp_get_receive
    select receive_no  , pre_no ,'related_case5_1','DIVIDING','分割新申請 + 分割後續文','0'
      from (select a.receive_no ,a.receive_no pre_no
              from receive a join spt21 s21 on a.receive_no = s21.receive_no
             where a.step_code = '0'
              and a.doc_complete = '1'
              and return_no not in ('4','A','B','C','D')
               and substr(a.receive_no, 4, 1) = '2'
               and s21.type_no in ('12000', '11092')
               and not exists (select 1
                            from spt32
                            where spt32.PRIORITY_NATION_ID = 'TW'
                            and spt32.appl_no = a.appl_no)
            union all
            select a.receive_no, c.receive_no
              from receive a join
              (select b.appl_no, b.receive_no
                      from receive b join spt21 s21 on b.receive_no = s21.receive_no
                     where b.step_code = '0'
                       and b.doc_complete = '1'
                       and return_no not in ('4','A','B','C','D')
                       and substr(b.receive_no, 4, 1) = '2'
                       and s21.type_no in ('12000', '11092')
                       and not exists (select 1
                            from spt32
                            where spt32.PRIORITY_NATION_ID = 'TW'
                            and spt32.appl_no = b.appl_no)
                        ) c
                  on a.appl_no = c.appl_no
             where a.step_code = '0'
               and a.doc_complete = '1'
               and return_no not in ('4','A','B','C','D')
               and substr(a.receive_no, 4, 1) = '3'
          );
    g_reason := '分割新申請 + 分割後續文';
   
      dbms_output.put_line(' 分割新申請 + 分割後續文 ' || l_rec_cnt);
    commit;
  
    ---分割後續文
    insert into tmp_get_receive
    select a.receive_no   , ( select min(receive_no) from receive where appl_no = a.appl_no and step_code='0' and doc_complete = '1' group by Receive.Appl_No ) 
            ,'related_case5_2',
          ( select   case when s.type_no  in ('13003', '21100', '24100') then 'MISC_AMEND'
          else 'DIVIDING_AMEND'         end 
        from receive join spt21 s on receive.receive_no = s.receive_no
        where receive.receive_no = ( select min(receive_no) from receive where appl_no = a.appl_no and step_code='0' and doc_complete = '1' group by Receive.Appl_No )
        and receive.appl_no = a.appl_no
      )
      ,  ( select   case when s.type_no  in ('13003', '21100', '24100') then '分割後續文-一般'
          else '分割後續文'         end 
        from receive join spt21 s on receive.receive_no = s.receive_no
        where receive.receive_no = ( select min(receive_no) from receive where appl_no = a.appl_no and step_code='0' and doc_complete = '1' group by Receive.Appl_No )
        and receive.appl_no = a.appl_no
      )
      ,'0'
     from receive a 
     join spt21 s21 on a.receive_no = s21.receive_no
     where a.step_code = '0'
       and a.doc_complete = '1'
       and return_no not in ('4','A','B','C','D')
       and substr(a.receive_no, 4, 1) = '3'
       and exists (select 1
              from spt21 s21 left join receive b on b.receive_no = s21.receive_no
             where s21.appl_no = a.appl_no
               and ( b.step_code = '8' or b.step_code is null)
               and s21.type_no in ('12000', '11092'))
       ;
     
    g_reason := '分割後續文';
   
     dbms_output.put_line(' 分割後續文 ' || l_rec_cnt);
    commit;

  end related_case5;

  procedure related_case6
  --  續領後續文 
  -- 不判斷件數
   is
    v_collect receive_no_tab;
  begin
   
              
     insert into tmp_get_receive
      select a.receive_no , a.receive_no ,'related_case6',c.processor_no,'續領後續文','0'
      from receive a 
      join ( select appl_no, processor_no from receive b
       where  b.step_code > '0' and b.step_code < '8'
       and substr(b.receive_no, 4, 1) = '3'
       ) c on a.appl_no = c.appl_no
      where a.step_code = '0'
       and a.doc_complete = '1'
       and return_no not in ('4','A','B','C','D')
       and substr(a.receive_no, 4, 1) = '3'
     ;
   
      dbms_output.put_line(' 續領後續文 ' || l_rec_cnt);
    commit;
    g_reason := '續領後續文';
   
  end related_case6;

  procedure same_case1
  --  新案承辦人優先全領 
  -- 不判斷件數
   is
    v_collect receive_no_tab;
  begin
 
     insert into tmp_get_receive
      select a.receive_no , a.receive_no ,'same_case1',b.processor_no,'新案承辦人優先全領','0'
      from receive a
      join receive b
        on a.appl_no = b.appl_no
     where substr(b.receive_no, 4, 1) = '2'
       and b.step_code = '2'
       and a.step_code = '0'
       and a.doc_complete = '1'
       and a.return_no not in ('4','A','B','C','D')
       and a.receive_no > b.receive_no
       and not exists (select 1 from tmp_get_receive where receive_no = a.receive_no and is_get='0')
    ;
   
      dbms_output.put_line(' 新案承辦人優先全領 ' || l_rec_cnt);
    commit;
    g_reason := '新案承辦人優先全領';
   
  end same_case1;

  procedure same_case2 is
   begin
   -- 整包領
    ---同案全領
  
    insert into tmp_get_receive
     select v.receive_no, v.receive_no,'same_case2',v.skill,'同案全領 ','0'
                      from VW_PULLING v
                     where substr(v.receive_no, 4, 1) = '2'
                       and v.return_no  not in ('4','A','B','C','D')
                       and not exists (select 1 from tmp_get_receive where receive_no = v.receive_no)     
                       and exists (select 1 from receive where receive.appl_no = v.appl_no and receive_no > v.receive_no)
           union all 
                       select v.receive_no, n.receive_no, 'same_case2',n.skill,'同案全領 ','0'
                      from VW_PULLING v 
                      join (
                      select v.appl_no, v.receive_no, v.skill
                      from VW_PULLING v
                     where substr(v.receive_no, 4, 1) = '2'
                       and v.return_no  not in ('4','A','B','C','D')
                       and not exists (select 1 from tmp_get_receive where receive_no = v.receive_no)
                      ) n on v.appl_no = n.appl_no
                     where substr(v.receive_no, 4, 1) = '3'
                       and v.return_no  not in ('4','A','B','C','D')
                      and not exists (select 1 from tmp_get_receive where receive_no = v.receive_no and is_get = '0')
            ;
    
          dbms_output.put_line(' 同案全領 ' || l_rec_cnt);
       commit;
   
    g_reason := '同案全領';

  end same_case2;
  
  procedure common_case
  --領取一般分配文號
  -- 判斷件數
   is
  begin
    insert into tmp_get_receive
    select receive_no , receive_no ,'common_case',v.skill,'領取一般分配文號 ','0'
      from VW_PULLING v
     where return_no <= '3'
      and not exists (select 1 from tmp_get_receive where receive_no = v.receive_no and is_get = '0')
        ;
       
        dbms_output.put_line(' 領取一般分配文號 ' || l_rec_cnt);
          commit;
   
    g_reason := '領取一般分配文號';

  end common_case;

begin
   g_total      := 0;
   l_rec_cnt    := 0;

  SELECT count(1) into l_rec from receive where step_code = '0' and doc_complete = '1';
--------------------------------
 --  is_refresh  default = 1
--------------------------------
 if trim(nvl(is_refresh,'1')) = '1' then
   delete  tmp_get_receive;
end if ;
   
    -- 續領後續文,不用被領取件數限制
     related_case6;
   --新案承辦人優先全領 ,不用被領取件數限制
    same_case1;
    --   g_reason := '主張國內優先權的新申請案';
    related_case1;
 
    related_case2;
    -- 退文重領辦
   related_case3;
 

    related_case4;
 
    related_case5;

 



 --  同案全領 
  same_case2;

  common_case;
  commit;
  select count(1) into p_rec from tmp_get_receive;

  dbms_output.put_line(p_rec);
EXCEPTION
  WHEN OTHERS THEN
    ecode     := SQLCODE;
    p_out_msg := SQLCODE || ' : ' || SQLERRM;
    dbms_output.put_line('Error Code:' || ecode || '; Error Message:' ||
                         p_out_msg);
END CHECK_RECEIVE;

/
--------------------------------------------------------
--  DDL for Procedure CHECK_RECEIVE_DAY
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CHECK_RECEIVE_DAY" (p_rec  out int
                                         ) IS
  /*
  準備領辦公文
  104/08/28: 當已存在doc ,可直接update doc_complte = 1
  */
  p_out_msg    varchar2(1000);
BEGIN
  update receive set doc_complete = '1'
  where receive_no in  ( select receive_no from doc where doc.receive_no = receive.receive_no)
  ;
  CHECK_RECEIVE('1',p_rec,p_out_msg);

EXCEPTION
  WHEN OTHERS THEN
  
    dbms_output.put_line('Error Code:' || SQLCODE || ' : ' || SQLERRM);
END CHECK_RECEIVE_DAY;

/
--------------------------------------------------------
--  DDL for Procedure CHECK_STATUS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CHECK_STATUS" ( p_rec  out int) is
 l_out_msg varchar2(100);
 p_msg     varchar2(100);
 ap_code varchar2(20);
  rec_cnt integer;
begin
 
  /*
  Modify: 104/08/05
  Desc : check 191 status ,stepcode 4: 送核 5: 主管退辦  8: 結案
   change receive_trans_log schema
  104/07/06: add update column  return_no = '6' when form return from manager
  104/07/07: change the step_code from 6 to 5 for form rejected issue
  104/07/09: update sign_date for close date 
  104/07/16: update the condition of waiting sign
  104/07/24: update error reporting status
  104/08/05: update spt21.online_cout = 'E' --mean finish
  104/09/03: update the status of recieve has merged 
  */
  ap_code := 'CHECK_STATUS';
  rec_cnt := 0;
  p_rec := 0;
  ---------------------
    -- record receive transfer history
    ---------------------
   
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no ,receive.processor_no,'4',sysdate,'送核'
      from receive
    where  receive_no in (
    select receive_no from  spm56 
    where  nvl(spm56.issue_flag ,'0') = '1'
    and spm56.processor_no = receive.processor_no
    )
    and step_code != '4'
    and step_code >'0';
     
    

    update receive set step_code = '4' 
    where  receive_no in (
    select receive_no from  spm56 
    join ap.SPTD02 sd02  on sd02.form_file_a = spm56.form_file_a
    where  nvl(spm56.issue_flag ,'0') = '1'
    and sd02.NODE_STATUS = '210'
    and spm56.processor_no = receive.processor_no
    )
    and step_code != '4'
    and step_code >'0';
    
    commit;
    rec_cnt := rec_cnt +  SQL%RowCount;
    dbms_output.put_line('receive waiting for signed record:' || SQL%RowCount);
    /*************************************
      online finish:      SPTD02.flow_step=09
      paper finish: SPT41. check_datetime<>Null
      set step_code = '8'
    */
  --------------------------------
  -- write to log for paper issue
  --------------------------------
   INSERT INTO RECEIVE_TRANS_LOG
     select   nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no ,receive.processor_no,'8',sysdate,'結案'
    from receive
    where receive.step_code >= '2'  and receive.step_code < '8'
    and (  receive_no in ( -- online 
        select sm56.receive_no
         from ap.SPTD02 sd02 join ap.spm56 sm56 on sd02.form_file_a = sm56.form_file_a
         where  sd02.flow_step = '09'
         and sd02.NODE_STATUS = '900'
         and sm56.processor_no = receive.processor_no
         and sm56.record_date >= receive.process_date
         and sm56.form_file_a = (select max(form_file_a) from spm56 where spm56.receive_no = sm56.receive_no and spm56.processor_no = sm56.processor_no)
     ) or
      receive_no in ( -- paper 
         select s41.receive_no
         from  ap.spt41 s41
         where s41.check_datetime is not null
         and s41.processor_no = receive.processor_no
         and substr(s41.check_datetime,1,7) >= receive.process_date
         and s41.issue_no = (select max(issue_no) from spt41 where spt41.receive_no = s41.receive_no and spt41.processor_no = s41.processor_no)
     )
     );
     
      INSERT INTO RECEIVE_TRANS_LOG
     select   nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no ,receive.processor_no,'8',sysdate,'併辦主文結案'
    from receive
    where receive.step_code >= '2'  and receive.step_code < '8'
    and (  merge_master in ( -- online 
        select sm56.receive_no
         from ap.SPTD02 sd02 join ap.spm56 sm56 on sd02.form_file_a = sm56.form_file_a
         where  sd02.flow_step = '09'
         and sd02.NODE_STATUS = '900'
         and sm56.processor_no = receive.processor_no
         and sm56.record_date >= receive.process_date
         and sm56.form_file_a = (select max(form_file_a) from spm56 where spm56.receive_no = sm56.receive_no and spm56.processor_no = sm56.processor_no)
     ) or
      merge_master in ( -- paper 
          select s41.receive_no
         from  ap.spt41 s41
         where s41.check_datetime is not null
         and s41.processor_no = receive.processor_no
         and substr(s41.check_datetime,1,7) >= receive.process_date
         and s41.issue_no = (select max(issue_no) from spt41 where spt41.receive_no = s41.receive_no and spt41.processor_no = s41.processor_no)
     )
     );
  
    ------------------------------------
    -- update step_code for paper issue
    ------------------------------------
    update receive set step_code = '8' ,
                       sign_date = ( select substr(check_datetime,1,7) from spt41 where check_datetime is not null
    and  spt41.receive_no = receive.receive_no and spt41.processor_no = receive.processor_no 
      and issue_no = (select max(issue_no) from spt41 s41 where s41.receive_no = spt41.receive_no and s41.processor_no = spt41.processor_no )
    )
     where receive.step_code >= '2'  and receive.step_code < '8'
    and (  receive_no in ( -- online 
        select sm56.receive_no
         from ap.SPTD02 sd02 join ap.spm56 sm56 on sd02.form_file_a = sm56.form_file_a
         where  sd02.flow_step = '09'
         and sd02.NODE_STATUS = '900'
         and sm56.processor_no = receive.processor_no
         and sm56.record_date >= receive.process_date
         and sm56.form_file_a = (select max(form_file_a) from spm56 where spm56.receive_no = sm56.receive_no and spm56.processor_no = sm56.processor_no)
     ) or
      receive_no in ( -- paper 
           select s41.receive_no
         from  ap.spt41 s41
         where s41.check_datetime is not null
         and s41.processor_no = receive.processor_no
         and substr(s41.check_datetime,1,7) >= receive.process_date
         and s41.issue_no = (select max(issue_no) from spt41 where spt41.receive_no = s41.receive_no and spt41.processor_no = s41.processor_no)
     ) 
     );
     rec_cnt := rec_cnt +  SQL%RowCount;
     
     update receive set step_code = '8' ,
                       sign_date = ( select substr(check_datetime,1,7) from spt41 where check_datetime is not null
    and  spt41.receive_no = receive.merge_master and spt41.processor_no = receive.processor_no 
      and issue_no = (select max(issue_no) from spt41 s41 where s41.receive_no = spt41.receive_no and s41.processor_no = spt41.processor_no )
    )
     where receive.step_code >= '2'  and receive.step_code < '8'
    and (  
     receive.merge_master in ( -- online 
        select sm56.receive_no
         from ap.SPTD02 sd02 join ap.spm56 sm56 on sd02.form_file_a = sm56.form_file_a
         where  sd02.flow_step = '09'
         and sd02.NODE_STATUS = '900'
         and sm56.processor_no = receive.processor_no
         and sm56.record_date >= receive.process_date
         and sm56.form_file_a = (select max(form_file_a) from spm56 where spm56.receive_no = sm56.receive_no and spm56.processor_no = sm56.processor_no)
     ) or
      receive.merge_master in ( -- paper 
        select s41.receive_no
         from  ap.spt41 s41
         where s41.check_datetime is not null
         and s41.processor_no = receive.processor_no
         and substr(s41.check_datetime,1,7) >= receive.process_date
         and s41.issue_no = (select max(issue_no) from spt41 where spt41.receive_no = s41.receive_no and spt41.processor_no = s41.processor_no)
     )
     );
     
    rec_cnt := rec_cnt +  SQL%RowCount;
     commit;
   
    
   dbms_output.put_line('receive finish record:' || SQL%RowCount);
    /*-------------------
    --  5: 主管退辦  
    -- online issue : SPTD02.resend=Ynullsign_user=承辦人
    -- form rejected from manager
    ----------------------*/

    ---------------------------------
    -- write to log for online issue 
    ---------------------------------
     INSERT INTO RECEIVE_TRANS_LOG
     select   nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no ,receive.processor_no,'5',sysdate,'函稿退辦'
    from receive
    where receive.step_code > '3'
    and receive_no in (
     select sm56.receive_no
    from ap.SPTD02 sd02 join ap.spm56 sm56 on sd02.form_file_a = sm56.form_file_a
     where (sd02.SIGN_RESULT = '2' or NODE_STATUS = '130' ) -- 退辦
     and sm56.processor_no = receive.processor_no
     and sm56.record_date >= receive.process_date
     and sm56.form_file_a = (select max(form_file_a) from spm56 where spm56.receive_no = sm56.receive_no and spm56.processor_no = sm56.processor_no)
    )
    and step_code > '0'
    and step_code != '5'
    ;
  
   -------------------------------------
   -- update step_code for online issue
   -------------------------------------
     update receive set step_code = '5' , return_no = '6' ,sign_date = null
     where receive.step_code > '3'
     and receive_no in (
     select sm56.receive_no
    from ap.SPTD02 sd02 join ap.spm56 sm56 on sd02.form_file_a = sm56.form_file_a
     where (sd02.SIGN_RESULT = '2' or NODE_STATUS = '130' ) -- 退辦
     and sm56.processor_no = receive.processor_no
     and sm56.record_date >= receive.process_date
     and sm56.form_file_a = (select max(form_file_a) from spm56 where spm56.receive_no = sm56.receive_no and spm56.processor_no = sm56.processor_no)
    )
    and step_code > '0'
    and step_code != '5'
    ;
    
    
    rec_cnt := rec_cnt +  SQL%RowCount;
      dbms_output.put_line('receive return record:' || SQL%RowCount);
    commit;
   
    
    
   /*-------------------
    --  5: 作廢  
    -- 外包文稿移到人工分辦,一般承辦人移到退辦
    -- form rejected from manager
    ----------------------*/
     ---------------------------------
    -- write to log for online issue 
    ---------------------------------
     INSERT INTO RECEIVE_TRANS_LOG
     select   nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no ,receive.processor_no,'0',sysdate,'外包函稿作廢'
    from receive
    where receive.step_code > '0'
    and receive_no in (
     select sm56.receive_no
    from ap.SPTD02 sd02 join ap.spm56 sm56 on sd02.form_file_a = sm56.form_file_a
     where  NODE_STATUS > '900'  -- 作廢
     and sm56.processor_no = receive.processor_no
     and sm56.form_file_a = (select max(form_file_a) from spm56 where spm56.receive_no = sm56.receive_no and spm56.processor_no = sm56.processor_no)
     and substr(sm56.processor_no,1,1)='P'
    )
    and step_code != '0'
    ;
       INSERT INTO RECEIVE_TRANS_LOG
     select   nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no ,receive.processor_no,'5',sysdate,'函稿作廢'
    from receive
     where receive.step_code > '0'
    and receive_no in (
     select sm56.receive_no
    from ap.SPTD02 sd02 join ap.spm56 sm56 on sd02.form_file_a = sm56.form_file_a
     where  NODE_STATUS > '900'  -- 作廢
     and sm56.processor_no = receive.processor_no
     and sm56.form_file_a = (select max(form_file_a) from spm56 where spm56.receive_no = sm56.receive_no and spm56.processor_no = sm56.processor_no)
     and substr(sm56.processor_no,1,1) !='P'
    )
    and step_code != '5'
    ;
     update receive set step_code = '0' , return_no = '4' ,sign_date = null
    where receive.step_code > '0'
    and receive_no in (
     select sm56.receive_no
    from ap.SPTD02 sd02 join ap.spm56 sm56 on sd02.form_file_a = sm56.form_file_a
     where  NODE_STATUS > '900'  -- 作廢
     and sm56.processor_no = receive.processor_no
     and sm56.form_file_a = (select max(form_file_a) from spm56 where spm56.receive_no = sm56.receive_no and spm56.processor_no = sm56.processor_no)
     and substr(sm56.processor_no,1,1)='P'
    )
    and step_code != '0'
    ;
     rec_cnt := rec_cnt +  SQL%RowCount;
     dbms_output.put_line('Outsourcing form failed record:' || SQL%RowCount);
     
     update receive set step_code = '5' , return_no = '6' ,sign_date = null
     where receive.step_code > '0'
    and receive_no in (
     select sm56.receive_no
    from ap.SPTD02 sd02 join ap.spm56 sm56 on sd02.form_file_a = sm56.form_file_a
     where  NODE_STATUS > '900'  -- 作廢
     and sm56.processor_no = receive.processor_no
     and sm56.form_file_a = (select max(form_file_a) from spm56 where spm56.receive_no = sm56.receive_no and spm56.processor_no = sm56.processor_no)
     and substr(sm56.processor_no,1,1) !='P'
    )
    and step_code != '5'
    ;
    rec_cnt := rec_cnt +  SQL%RowCount;
    commit;
    dbms_output.put_line('form return record:' || SQL%RowCount);
    ---------------------------------
    -- update error reporting when document file has new one 
    ---------------------------------
    update error_reporting er
    set status = '1'
    where receive_no in 
    (
    select receive_no -- to_char(report_date,'yyyyMMddhh:mi:ss') 
    from  doc imp 
    where trim(er.receive_no) = trim(imp.receive_no) 
    and  to_char(report_date,'yyyyMMddhh:mi:ss')  <  to_char(to_number(to_char(modify_time,'yyyyMMdd'))) || to_char(modify_time,'hh:mi:ss')
    )
    and status in ('0','3')
    ;
    rec_cnt := rec_cnt +  SQL%RowCount;
    commit;
    dbms_output.put_line('error_reporting pass record:' || SQL%RowCount);
   
  
        p_rec := rec_cnt;
        
EXCEPTION
  WHEN OTHERS THEN
  
   p_msg := ap_code || ':' || SQLCODE || ':' || SQLERRM; 
    dbms_output.put_line('Error Code:' || SQLCODE || '; Error Message:' || p_msg);     
end CHECK_STATUS;

/
--------------------------------------------------------
--  DDL for Procedure CHECK_UNOVERTIME
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CHECK_UNOVERTIME" ( p_rec out int)
is
    p_msg            varchar2(100);
    ap_code          varchar2(10);
    l_appl_no        appl.appl_no%type;
    ecode            number;
    l_exist          number;
    cnt              number;
    update_cnt       number;
    CURSOR appl_cursor IS
    select appl_no
      from appl
     where divide_code in ('1','2')
     and IS_OVERTIME = '1'
    order by appl_no;
  
 ---------------------------
 -- remove overtime or taketurn status
 -- divide_code = 1 is overtime project / divide_code = 2 is taketurn project
 -- ModifyDate : 104/09/17
 -- 
 --  先判斷是否要進入自動輪辦,再判斷是否個人逾期
 -- Modify : update the condition 
 -- 104/08/11 : remove takturn status
 -- 104/09/17 : new project doesn't set the outsourcing condistion 
 ---------------------------------
PROCEDURE Check_Case1(p_appl_no in char, p_is_exist out number)
  -- 
  is

BEGIN
     ap_code := 'case1';
     
    ----------------
    -- '新案,逾期:'
    ---------------
   select case when  count(1) >0 then '1' else '0' end into p_is_exist
    from spt41 s41
    join 
    (
    select max(spm56.form_file_a) form_file_a, spm56.appl_no , s31a.type_no ,s31a.step_code
    from spm56 join spt31a s31a on spm56.appl_no = s31a.appl_no
    where  spm56.form_id = 'A02'
    and s31a.step_code = '10'
    group by spm56.appl_no  , s31a.type_no  ,s31a.step_code
    ) s56 on s41.form_file_a = s56.form_file_a and s41.appl_no = s56.appl_no
    left join 
    (
      select appl_no , 
          (case 
               when  (substr(appl_no,4,1) = '1' OR substr(appl_no,4,1) = '2') and  sysdate> add_months(to_date(min(PRIORITY_DATE),'yyyyMMdd'),16 )
                    then 1
               when  (substr(appl_no,4,1) = '3' OR (substr(appl_no,4,1) = '3' and substr(appl_no,10,1) = 'D' )) and  sysdate> add_months(to_date(min(PRIORITY_DATE),'yyyyMMdd'),10 )
                    then 1
              else 0
          end) isOverTime   
      from spt32 
      where    PRIORITY_DOC_FLAG is  null  
               and ACCESS_CODE   is  null  
               and PRIORITY_DATE is not null
               and priority_flag = '1'
               and appl_no = p_appl_no
      group by appl_no     
    ) s32 on s32.appl_no = s41.appl_no
    left join 
    (
     select appl_no ,sum( case when PRIORITY_DATE is  null then 0
                      else 1 end) cnt
      from spt32 
      where  priority_flag = '1'
      and appl_no = p_appl_no
       group by appl_no
    ) s32_2  on s32_2.appl_no = s41.appl_no
     left join 
    (
     select appl_no ,sum( case when (PRIORITY_DATE is not null  
               and  (ACCESS_CODE  is not  null  or PRIORITY_DOC_FLAG is not  null)) then 0
            else 1 end) cnt
      from spt32 
       where  priority_flag = '1'
       and appl_no = p_appl_no
      group by appl_no
    ) s32_3  on s32_3.appl_no = s41.appl_no
    where   trunc(sysdate) > case  when  valid_tw_date2(FILE_LIM_DATE)=0  then  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20 )
                           else  trunc(to_date('21991231','yyyyMMdd') )
                      end   
     and  (s32.isOverTime = '1'  or s32_2.cnt =0  or s32_3.cnt =0)
     and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
    --  and  exists (select 1 from spm63 where  processor_no = s41.processor_no  and quit_date is  null)
    --  and  substr(s41.processor_no,1,1)!='P'
      and s41.appl_no = p_appl_no
      ;

     
 --   dbms_output.put_line('新案,逾期:');
 
END Check_Case1;
  
  ----------------------------
  --再審程序審查
  -----------------------------
   
  PROCEDURE Check_Case2(p_appl_no in char, p_is_exist out number)
  --
  is

  BEGIN
   ap_code := 'case2';
        
     ---再審,逾期
     select case when  count(1) >0 then '1' else '0' end into p_is_exist
     from spt41 s41
     join 
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no , s31a.type_no ,s31a.step_code
      from spm56 join spt31a s31a on spm56.appl_no = s31a.appl_no
      where  spm56.form_id = 'A04'
      and s31a.step_code = '30'
      and s31a.appl_no = p_appl_no
      group by spm56.appl_no  , s31a.type_no  ,s31a.step_code
      ) s56 on s41.form_file_a = s56.form_file_a and s41.appl_no = s56.appl_no
      left join spt32 on spt32.appl_no = s41.appl_no
      where (spt32.data_seq = (select max(s32.data_seq) from spt32 s32 where spt32.appl_no= s32.appl_no) or spt32.data_seq is null)
      and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
      --and sysdate > to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20
      and trunc(sysdate) > case when valid_tw_date2(FILE_LIM_DATE)=1  then trunc(to_date('21991231','yyyyMMdd'))  else  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20) end
     -- and exists (select 1 from spm63 where  processor_no = s41.processor_no and quit_date is  null)
      and s41.appl_no = p_appl_no
      ;
     
    --    dbms_output.put_line('審查逾期:');
 
  END Check_Case2;
  
  ----------------------------
  -- 待實體審查
  -----------------------------  
  PROCEDURE Check_Case3(p_appl_no in char, p_is_exist out number)
  --  
  is
 
  BEGIN
  ap_code := 'case3';
         

      select case when  count(1) >0 then '1' else '0' end into p_is_exist
        from spt41 s41
      join 
      (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no , s31a.type_no ,s31a.step_code
      from spm56 join spt31a s31a on spm56.appl_no = s31a.appl_no
      where ( spm56.form_id = 'P18' or spm56.form_id = 'P19' )
      and s31a.step_code = '16'
      and s31a.appl_no = p_appl_no
      group by spm56.appl_no  , s31a.type_no  ,s31a.step_code
      ) s56 on s41.form_file_a = s56.form_file_a and s41.appl_no = s56.appl_no
      where (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
      and trunc(sysdate) > case when valid_tw_date2(FILE_LIM_DATE)=1  then trunc(to_date('21991231','yyyyMMdd'))  else  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20) end
      and not exists ( select 1 from spm56 where spm56.appl_no = s56.appl_no and spm56.form_id = 'P32')
    --  and exists (select 1 from spm63 where  processor_no = s41.processor_no and quit_date is  null)
      and s41.appl_no >= '091132001'
  --    and exists ( select 1 from spt31 where spt31.appl_no = s41.appl_no and spt31.material_appl_date is  null)
      and s41.appl_no = p_appl_no
     ;
     
  --    dbms_output.put_line('實體審查,逾期');
 
  END check_case3;
  ----------------------------
  -- 讓與
  -----------------------------
   PROCEDURE Check_Case4(p_appl_no in char, p_is_exist out number)
  --  
  is
   
  BEGIN
  ap_code := 'case4';
        
     select case when  count(1) >0 then '1' else '0' end into p_is_exist
        from  spt41 s41
     join
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no  ,s31a.step_code
      from spm56 
      join spt31a s31a on spm56.appl_no = s31a.appl_no
   --   join spt41 s41 on S41.Form_File_A = spm56.form_file_a 
      where  substr(spm56.appl_no,4,1) = '1' -- 只清查發明案
       and s31a.step_code in ('16','20')
       and s31a.appl_no = p_appl_no
       and s31a.appl_no not in ( select s.appl_no from spt41 s  join spm56 s56 on s.form_file_a = s56.form_file_a
                             where  s.appl_no = s31a.appl_no 
                             and s.issue_no > (select max(issue_no) from spt41 where s.appl_no = spt41.appl_no   and issue_type = '40007')
                             and ( (s.issue_type = '40101' and s56.form_id = 'B38')
                               or ( s.issue_type = '40103' and s56.form_id = 'B38')   
                               or ( s56.form_id  in ('P03-1','A06','P31') )
                               )
                        )
       and exists (select 1 from spt41 s2 where  s2.appl_no =  s31a.appl_no and s2.issue_type = '40007')
      group by spm56.appl_no  , s31a.step_code
       )  s56 on  s41.form_file_a = s56.form_file_a 
      where     ( s41.file_d_flag is null or s41.file_d_flag = ' ')
        and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
   --    and not exists (select 1 from spm56 where spm56.appl_no = s41.appl_no and spm56.form_file_a >s41.form_file_a and spm56.form_id  in ('P03-1','A06','P31'))
      and trunc(sysdate) > case when valid_tw_date2(FILE_LIM_DATE)=1  then trunc(to_date('21991231','yyyyMMdd'))  else  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20) end
    --   and exists (select 1 from spm63 where  processor_no = s41.processor_no  and quit_date is  null )
       and s41.appl_no = p_appl_no
     ;
    
 --     dbms_output.put_line('讓與,逾期:' || p_is_exist);


  END check_case4;
  ----------------------------
  -- 變更
  -----------------------------  
  PROCEDURE Check_Case5(p_appl_no in char, p_is_exist out number)
  --  
  is
  
  BEGIN
  ap_code := 'case5';
        
    
      select case when  count(1) >0 then '1' else '0' end into p_is_exist
      from  spt41 s41
     join
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no , s31a.type_no ,s31a.step_code
      from spm56 
      join spt31a s31a on spm56.appl_no = s31a.appl_no
      where  substr(s31a.appl_no,4,1) = '1' -- 只清查發明案
       and s31a.step_code in ('16','20')
       and s31a.appl_no = p_appl_no
        group by spm56.appl_no  , s31a.type_no  ,s31a.step_code
       )  s56 on s41.form_file_a = s56.form_file_a and s41.appl_no = s56.appl_no
      where    s41.appl_no in 
      ( select appl_no
      from  spt41 s41
      where     ( s41.file_d_flag is null or s41.file_d_flag = ' ')
       and s41.issue_type = '40009'
       and  substr(s41.appl_no,4,1) = '1' -- 只清查發明案
       and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
       and not exists ( select 1 from spm56 where spm56.appl_no = s41.appl_no and spm56.form_id in ('C09','C09-1','C09-2','C09-3','C10','P03-1','A06','P32') )
       and (select count(1) from spt41  where spt41.appl_no = s41.appl_no and spt41.process_result is null) =0
       )
      and trunc(sysdate) > case when valid_tw_date2(FILE_LIM_DATE)=1  then trunc(to_date('21991231','yyyyMMdd'))  else  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20) end
   --    and exists (select 1 from spm63 where processor_no = s41.processor_no  and quit_date is  null )
       and s41.appl_no = p_appl_no
      ;
    
    --   dbms_output.put_line('變更,逾期:');

 
  END Check_Case5;
----------------------------
-- 延長
----------------------------- 
  PROCEDURE Check_Case6(p_appl_no in char, p_is_exist out number)
  --  
is
  
BEGIN
   ap_code := 'case6';
         
      select case when  count(1) >0 then '1' else '0' end into p_is_exist
       from spt41 s41
      join spt21 s21 on s21.receive_no  = s41.receive_no
      join spt31a on s21.appl_no = spt31a.appl_no
      where  s41.issue_type = '22210'
      and trunc(sysdate) > trunc(add_months(to_date(to_char(to_number(substr(lpad(trim(s21.RECEIVE_DATE),7,'0'),1,3))+1911) || substr( lpad(trim(s21.RECEIVE_DATE),7,'0'),4,4),'yyyyMMdd'),7))
     -- and exists (select 1 from spm63 where  processor_no = s41.processor_no and quit_date is null) 
      and not exists ( select 1 from spm56 where spm56.form_file_a = s41.form_file_a and spm56.form_id = 'A06-2')
      and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
      and exists
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no 
      from spm56 join spt41 on spm56.form_file_a = spt41.Form_File_A
      where  spm56.form_id = 'E01'
     -- and exists ( select 1 from spm63 where  processor_no = spt41.processor_no and quit_date is null)
      and  s41.appl_no = spm56.appl_no 
      and spm56.appl_no = p_appl_no
      group by spm56.appl_no 
      ) 
       and s41.appl_no = p_appl_no
      ;
      
   --   dbms_output.put_line('延長,逾期');
 
  END Check_Case6;
 

BEGIN

  update_cnt := 0;
 
  OPEN appl_cursor;
  LOOP
    FETCH appl_cursor
      INTO l_appl_no;
    EXIT WHEN appl_cursor%NOTFOUND;
      -- initial
       l_exist :=0;
       cnt :=0;
       check_case1(l_appl_no,l_exist);
       cnt := cnt + l_exist;
       -- initial
       l_exist :=0;
       
       check_case2(l_appl_no,l_exist);
       cnt := cnt + l_exist;
       -- initial
       l_exist :=0;
       check_case3(l_appl_no,l_exist);
       cnt := cnt + l_exist;
       -- initial
       l_exist :=0;
       check_case4(l_appl_no,l_exist);
       cnt := cnt + l_exist;
       -- initial
       l_exist :=0;
       check_case5(l_appl_no,l_exist);
       cnt := cnt + l_exist;
       -- initial
       l_exist :=0;
       check_case6(l_appl_no,l_exist);
       cnt := cnt + l_exist;
    --    dbms_output.put_line(l_appl_no || ' : cnt=' || cnt);
       -----------------
       -- if didn't exist in any overtime list then remove it from list
       -----------------
      
       if cnt = 0 then -- overtime condition is not exist
            update appl
              set  IS_OVERTIME = '0' ,
                   DIVIDE_CODE  = '0',
                   ASSIGN_DATE = null
              where appl_no = l_appl_no; 
             dbms_output.put_line( l_appl_no || ' update !');
              
              update_cnt := update_cnt +1;
       end if;
      
  END LOOP;
  CLOSE appl_cursor;
          
   commit;
   p_rec := update_cnt;
   dbms_output.put_line('Finish!!' || p_rec);
EXCEPTION
  WHEN OTHERS THEN
   ecode := SQLCODE;
   p_msg := ap_code || ':' || SQLCODE || ':' || SQLERRM; 
    dbms_output.put_line('Error Code:' || ecode || '; Error Message:' || p_msg);
END CHECK_UNOVERTIME;

/
--------------------------------------------------------
--  DDL for Procedure CHECK_UNPOSTPONE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CHECK_UNPOSTPONE" ( p_rec out int)
is
    ecode            number;
    ap_code          varchar2(10);
    p_msg            varchar2(100);
    l_receive_no     char(15);
    l_processor_no   char(5);
    l_exist          number;
    cnt              number;
    CURSOR receive_cursor IS
    select receive_no, processor_no
      from receive
     where  receive.is_postpone in ( '1','2','3')
     order by receive_no;
 
 /* ModifyDate : 2015/05/26  
 */
 ---------------------------
 -- 移除緩辦- 等後續文
 ---------------------------------
PROCEDURE Check_Case1(p_receive_no in char,p_processor_no in char, p_is_exist out number)
  -- 
  is

BEGIN
     ap_code := 'case1';
     
   
     select count(1) into p_is_exist
     from receive
     where appl_no = ( select appl_no from receive where receive_no = p_receive_no)
     and receive_no > p_receive_no
     and step_code = '2'
     and processor_no = p_processor_no
     ;
 --   dbms_output.put_line('新案,逾期:');
 
END Check_Case1;
  
 ---------------------------
 -- 移除緩辦- 等規費
 ---------------------------------
   
  PROCEDURE Check_Case2(p_receive_no in char, p_is_exist out number)
  --
  is

  BEGIN
   ap_code := 'case2';
        
     select count(1) into p_is_exist
     from spt13
     where NUMBER_TYPE = 'A' -- 收文
     and receive_no = p_receive_no;
 
  END Check_Case2;
 
 -------------------------
 -- wait for document
 -------------------------
  PROCEDURE Check_Case3(p_receive_no in char, p_is_exist out number)
  --
  is

  BEGIN
   ap_code := 'case3';
        
     select count(1) into p_is_exist from DOC_IMPORT_LOG
     where import_date > (select para_no  from appl_para where sys = 'POSTPONE' and subsys = p_receive_no )
     and receive_no = p_receive_no
     ;
 
  END Check_Case3;    

BEGIN

  
 
  OPEN receive_cursor;
  LOOP
    FETCH receive_cursor
      INTO l_receive_no , l_processor_no;
    EXIT WHEN receive_cursor%NOTFOUND;
      -- initial
       l_exist :=0;
       cnt :=0;
       check_case1(l_receive_no,l_processor_no,l_exist);
       
       if l_exist > 0 then
          update receive set  is_postpone  = '0' ,	POST_REASON	 = '等來文可移除' where receive_no =l_receive_no   ;
       else
          check_case2(l_receive_no,l_exist);
          if l_exist > 0 then
             update receive set  is_postpone  = '0' ,	POST_REASON	 = '等規費可移除' where receive_no =l_receive_no   ;
          else
              check_case3(l_receive_no,l_exist);
               if l_exist > 0 then
                    update receive set  is_postpone  = '0' ,	POST_REASON	 = '等圖檔可移除' where receive_no =l_receive_no   ;
               end if;
         end if;
       end if;
      
       
      
  END LOOP;
  CLOSE receive_cursor;
  
  
     
        
   commit;
    p_rec := l_exist;
   dbms_output.put_line('Finish!!');
EXCEPTION
  WHEN OTHERS THEN
   ecode := SQLCODE;
   p_msg := ap_code || ':' || SQLCODE || ':' || SQLERRM; 
    dbms_output.put_line('Error Code:' || ecode || '; Error Message:' || p_msg);
END CHECK_UNPOSTPONE;

/
--------------------------------------------------------
--  DDL for Procedure CHIEF_FROM_OTHER_SECTION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CHIEF_FROM_OTHER_SECTION" (p_in_receive_no   in char,
                                                     p_out_msg         out varchar2) is
  l_receive_no    char(15);
  l_process_result    char(5);
  l_OUT_RESULT number;
begin
  /*----------------
     他科退辦公文
     ModifyDate: 2015/07/06
     parameter : p_in_receive_no : 公文文號
                 p_out_msg: null :執行成功 , error_message :執行失敗訊息
  -- Modify Items: 
 */ 
   ---------------------
    -- record receive transfer history
    ---------------------
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no , '70012','0',sysdate,'他科退辦公文'
      from receive
       Where receive_no = p_in_receive_no;
  
  select receive.receive_no  , spt21.process_result
    into l_receive_no, l_process_result
    from receive join spt21 on receive.receive_no = spt21.receive_no
   where receive.receive_no = p_in_receive_no;
  update receive
     set processor_no = '70012', step_code = '0' , return_no = 'C' --人工分辦
   Where receive_no = p_in_receive_no;
   
   update spt21
     set processor_no = '70012'
   Where receive_no = p_in_receive_no;

 
  p_out_msg := p_in_receive_no || ' 他科退辦公文成功';

end CHIEF_FROM_OTHER_SECTION;

/
--------------------------------------------------------
--  DDL for Procedure CHIEF_TO_DISPATCH
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CHIEF_TO_DISPATCH" (p_in_receive_no in char,
                                              p_out_msg       out varchar2) is
begin
  /* 
  Modify: 2015/07/06
  科長 退人工分辦; 退文註記改為: 5:退人工分辦; 收文狀態改為:待領
   (1) update return_no = 4 step_code = 0 processor_no=70012 process_result = null
   (2) return all receive with the same project
   (3) update spt21.processor_no = 70012
   (4) change receive_trans_log schema
  */
  
    ---------------------
    -- record receive transfer history
    ---------------------
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no , '70012','0',sysdate,'退人工分辦'
      from receive
       Where receive_no = p_in_receive_no;
       
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no , '70012','0',sysdate,'被併公文退人工分辦'
      from receive
       Where merge_master = p_in_receive_no;

   Update receive
     Set  step_code = '0', return_no = 'A', processor_no = '70012'
   Where receive_no = p_in_receive_no;
    --被併公文一起退
   update receive
     set step_code = '0' ,RETURN_NO = 'A' , processor_no = '70012', merge_master = null 
   where merge_master = p_in_receive_no;
 
   update spt21
     set process_result = null , pre_exam_date = null , pre_exam_qty = null, processor_no = '70012'
   where receive_no = p_in_receive_no;
   
   update spt21
     set processor_no = '70012', process_result = null , pre_exam_date = null , pre_exam_qty = null , complete_date = null
   where receive_no = (select receive_no from  receive where merge_master =   p_in_receive_no);
  
  commit;

  p_out_msg := p_in_receive_no || ' 退人工分辦成功';

end CHIEF_TO_DISPATCH;

/
--------------------------------------------------------
--  DDL for Procedure CHIEF_TO_OTHER_SECTION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CHIEF_TO_OTHER_SECTION" (p_in_receive_no   in char,
                                                   p_in_processor_no in char,
                                                   p_out_msg         out varchar2) is
  l_receive_no    char(15);
  l_process_result    char(5);
  l_OUT_RESULT number;
begin
  /*----------------
  -- ModifyDate: 2015/06/16
  -- 科長退他科
  -- Modify Items: (1) 5/20 : add to receive_trans_log
                   (2) 5/21 : change step_code from 1 to 8
                   (3) change receive_trans_log schema
                   (4)  return_no = '0'
 */ 
   ---------------------
    -- record receive transfer history
    ---------------------
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no , '70014','B',sysdate,'他科待辦'
      from receive
       Where receive_no = p_in_receive_no;
  
  select receive.receive_no  , spt21.process_result
    into l_receive_no, l_process_result
    from receive join spt21 on receive.receive_no = spt21.receive_no
   where receive.receive_no = p_in_receive_no;
  update receive
     set processor_no = '70014', step_code = 'B' , return_no = '0'
   Where receive_no = p_in_receive_no;
   
   update spt21
     set processor_no = '70014', process_result = null
   Where receive_no = p_in_receive_no;

 
  p_out_msg := p_in_receive_no || ' 退他科成功';

end CHIEF_TO_OTHER_SECTION;

/
--------------------------------------------------------
--  DDL for Procedure CHIEF_TO_POOL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CHIEF_TO_POOL" (p_in_receive_no in char,
                                          p_out_msg       out varchar2) is
 l_out_msg varchar2(100);
 l_rec_cnt number;
begin

  /*
  Modify: 2015/06/02
  科長退領辦區,辦理結果清空;若為外包不由批號中移除,只改變狀態為1 (退辦)
  (1) update receive set step_code=0 return_no =3 processor_no = 70012 process_result=null
  (2) return all receive with the same project
  (3) call check_receive
  (4) change receive_trans_log schema
  */
  l_rec_cnt :=0;
  
      delete tmp_get_receive  
      where receive_no in 
      (select receive_no from receive where appl_no = (select appl_no from receive
        where receive_no = p_in_receive_no)
      );

  ---------------------
    -- record receive transfer history
    ---------------------
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no , '70012','0',sysdate,'退領辦區'
      from receive
       Where receive_no = p_in_receive_no;
        INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no , '70012','0',sysdate,'被併公文退領辦區'
      from receive
       Where merge_master = p_in_receive_no;

   update receive
     set step_code = '0', RETURN_NO = '3', processor_no = '70012'
   where receive_no = p_in_receive_no;
   l_rec_cnt := l_rec_cnt +  SQL%RowCount;
   --被併公文一起退
   update receive
     set step_code = '0' ,RETURN_NO = '3' , processor_no = '70012', merge_master = null 
   where merge_master = p_in_receive_no;
   l_rec_cnt := l_rec_cnt +  SQL%RowCount;
   update spt21
     set processor_no = '70012', process_result = null , pre_exam_date = null , pre_exam_qty = null , complete_date = null
   where receive_no = p_in_receive_no;
   update spt21
     set processor_no = '70012', process_result = null , pre_exam_date = null , pre_exam_qty = null , complete_date = null
   where receive_no = (select receive_no from  receive where merge_master =   p_in_receive_no);
    commit;
    CHECK_RECEIVE('0',l_rec_cnt,l_out_msg);
  dbms_output.put_line('finish');

  p_out_msg := p_in_receive_no || ' 退領辦區成功';

end CHIEF_TO_POOL;

/
--------------------------------------------------------
--  DDL for Procedure CHIEF_TO_PROCESSOR
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CHIEF_TO_PROCESSOR" (p_in_receive_no   in char,
                                              p_in_processor_no  in char,
                                             p_from_processor_no   in char,
                                               p_out_msg         out varchar2) is
begin
  /*  
  Modify: 104/07/14
     科長退其它承辦
      將公文移出此批號,修改承辦人為指定承辦人, 公文狀態改為:待辦
       (1) update  step_code = 2 processor_no = ?
       (2)change receive_trans_log schema
       (3)  return_no = '0'
       (4) update process_date
      104/07/08: add parameter for return from who:  p_from_processor_no 
      104/07/14: update return_no for dispalying on return mark
      104/09/11: update spt31.sch_processor_no
  */
  
  ---------------------
    -- record receive transfer history
    ---------------------
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no , p_in_processor_no,'2',sysdate, p_from_processor_no ||' 退其它承辦'
      from receive
       Where receive_no = p_in_receive_no;
    

  update receive
     Set processor_no = trim(p_in_processor_no), step_code = '2' , return_no = '5', process_date = to_char(to_number(to_char(sysdate,'yyyyMMdd'))-19110000)
      , object_id = trim(p_from_processor_no)
   Where receive_no = p_in_receive_no;

  update spt21
     Set processor_no = trim(p_in_processor_no) , process_result = null , pre_exam_date = null , pre_exam_qty = null
   Where receive_no = p_in_receive_no;
   
      update spt31
      set sch_processor_no= p_in_processor_no, phy_processor_no = p_in_processor_no
      where appl_no in
      (
        select appl_no from spt31a 
        where appl_no = (select appl_no from receive where receive_no = p_in_receive_no )
        and ((step_code between '10' and '19'  and step_code != '15')
              or step_code = '30'
              or step_code = '29'
              or step_code = '49'
              or ( exists (select 1 from spt21 where appl_no = spt31.appl_no and  type_no in ('16000','16002','22210')))
            )
      and substr(appl_no,10,1) != 'N');

  p_out_msg := trim(p_in_receive_no) || ' 退承辦成功';

end CHIEF_TO_PROCESSOR;

/
--------------------------------------------------------
--  DDL for Procedure DASHBOARD_APPROVER
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."DASHBOARD_APPROVER" (
  P_IN_OBJECT_ID in varchar2,
  A_TODO out varchar2, -- 線上 公文
  A_TODO_P out varchar2, -- 紙本 公文
  A_TO_APPROVE out varchar2, -- 線上 待呈核
  A_TO_APPROVE_P out varchar2, -- 紙本 待呈核
  A_APPROVED out varchar2, -- 線上 已呈核
  A_APPROVED_P out varchar2, -- 紙本 已呈核
  A_UNSIGN_NEW out varchar2, -- 紙本已領未簽
  A_THISMON_TODO out varchar2, -- 當月應辦
  A_THISMON_DONE out varchar2, -- 當月辦結
  A_TO_EXCEED out varchar2) -- 即將逾期   
is
begin
  /* --------------------------------------------
   DESC: Dashboard for approver
   ModifyDate : 104/09/09
   ModifyItem:
  104/07/08: update the condition for waiting approved form
  104/07/31: update the condition for accept date
  104/09/09: exclude the receives which process_result = 57001
  ------------------------------------------------*/
  -- 線上 公文 Online Recieve
  SELECT  COUNT(CASE WHEN s21.PROCESS_RESULT is null  AND RECEIVE.RECEIVE_NO is not null THEN 1 ELSE NULL END) AS TODO,
          COUNT(CASE WHEN s21.PROCESS_RESULT is not null and ( (sd02.SIGN_RESULT = '1' and NODE_STATUS < '130' ) or s56.receive_no is null)    THEN 1 ELSE NULL END) AS DONE,
          COUNT(CASE WHEN (sd02.SIGN_RESULT = '1' and NODE_STATUS > '120' ) 
               THEN 1 ELSE NULL END) AS REJECTED
   INTO A_TODO, A_TO_APPROVE ,A_APPROVED
   FROM  RECEIVE  
   JOIN SPT21 s21 ON s21.RECEIVE_NO = RECEIVE.RECEIVE_NO 
   LEFT JOIN SPM56 s56 ON s56.RECEIVE_NO = RECEIVE.RECEIVE_NO AND s56.processor_no =  RECEIVE.PROCESSOR_NO and s56.record_date >= receive.process_date
   LEFT JOIN ap.sptd02 sd02 ON s56.form_file_a = sd02.form_file_a 
   WHERE  RECEIVE.step_code > '0'
    AND RECEIVE.step_code < '8'
    AND s21.process_result != '57001'
    AND RECEIVE.PROCESSOR_NO IN (
    SELECT PROCESSOR_NO   FROM SPM63 
    WHERE DEPT_NO = '70012' AND SUBSTR(PROCESSOR_NO,1,1)='P' AND QUIT_DATE IS NULL
    )
    AND (s56.form_file_a is null or s56.form_file_a = (select max(form_file_a) from spm56 where s56.receive_no = spm56.receive_no and s56.processor_no = spm56.processor_no))
    ;
  
  -- 紙本 公文
  SELECT COUNT(1)
  INTO A_TODO_P  
  FROM SPT21
  LEFT JOIN SPT23 ON SPT21.receive_no = SPT23.receive_no AND SPT21.OBJECT_ID = Spt23.OBJECT_TO
  WHERE SPT23.data_seq = (select max(data_seq) from spt23 s23 where SPT23.receive_no = s23.receive_no) 
    AND SPT23.ACCEPT_DATE IS NOT NULL
    AND PROCESS_RESULT IS NULL
    AND SPT21.object_id IN (
      SELECT PROCESSOR_NO   FROM SPM63 
     WHERE DEPT_NO = '70012' AND SUBSTR(PROCESSOR_NO,1,1)='P' AND QUIT_DATE IS NULL
    )
    AND SPT21.trans_no = '912'
    AND SPT21.process_result != '57001'
    ;
      
-- 紙本 待呈核
  SELECT COUNT(1)
  INTO A_TO_APPROVE_P
  FROM SPT21
  WHERE  PROCESS_RESULT IS NOT NULL
      AND not EXISTS (SELECT RECEIVE_NO FROM SPM56 WHERE RECEIVE_NO = SPT21.RECEIVE_NO AND ISSUE_FLAG = '1')
      AND SPT21.object_id IN (
      SELECT PROCESSOR_NO   FROM SPM63 
      WHERE DEPT_NO = '70012' AND SUBSTR(PROCESSOR_NO,1,1)='P' AND QUIT_DATE IS NULL
    )
    AND SPT21.trans_no = '912'
    AND SPT21.process_result != '57001'
    ;
  
 -- 紙本 已呈核
 SELECT COUNT(1)
 INTO A_APPROVED_P
  FROM SPT21
  JOIN spm56 on spm56.form_file_a = (select max(spm56.form_file_a) from spm56 s56 where s56.form_file_a = spm56.form_file_a)
               and spm56.receive_no = spt21.receive_no
  WHERE SPT21.PROCESS_RESULT IS NOT NULL
      AND spm56.Issue_Flag = '1'
      AND SPT21.object_id IN (
      SELECT PROCESSOR_NO   FROM SPM63 
      WHERE DEPT_NO = '70012' AND SUBSTR(PROCESSOR_NO,1,1)='P' AND QUIT_DATE IS NULL
    )
    AND SPT21.PROCESS_RESULT != '57001'
    ;
  
  -- 紙本已領未簽
  SELECT COUNT(1)
  INTO A_UNSIGN_NEW 
  FROM SPT23
  WHERE SPT23.data_seq = (select max(data_seq) from spt23 s23 where SPT23.receive_no = s23.receive_no) 
  AND  SUBSTR(SPT23.RECEIVE_NO,4,1) = '2'
      AND SPT23.TRANS_NO = '912'
      AND SPT23.ACCEPT_DATE IS NULL
       AND SPT23.OBJECT_TO IN (
      SELECT PROCESSOR_NO   FROM SPM63 
      WHERE DEPT_NO = '70012' AND SUBSTR(PROCESSOR_NO,1,1)='P' AND QUIT_DATE IS NULL
    )
    AND not exists ( select 1 from spt21 where spt21.receive_no = spt23.receive_no and spt21.process_result = '57001')
    ;
    
       -- 當月應辦 
   SELECT nvl(sum(d),0)  INTO A_THISMON_TODO
   FROM
   ( 
    SELECT  nvl(b.base,0) * nvl(mday.days,0) + nvl(a.factor,0) d
    FROM quota a JOIN quota_base b on a.processor_no = b.processor_no AND a.yyyy = b.yyyy
    LEFT JOIN (SELECT  substr(date_bc,1,6) yyyymm, count(1) days   
    FROM spmff WHERE  date_flag = 1 group by substr(date_bc,1,6) ) mday
    on mday.yyyymm = b.yyyy || a.mm
    WHERE trim(a.processor_no)  IN (
      SELECT PROCESSOR_NO   FROM SPM63 
      WHERE DEPT_NO = '70012' AND SUBSTR(PROCESSOR_NO,1,1)='P' AND QUIT_DATE IS NULL
    )
    AND a.yyyy = to_char(sysdate,'yyyy') AND a.mm = to_char(sysdate,'MM')
    )
    ;
    -- 將逾期
    SELECT  
         SUM( case when to_char(sysdate,'yyyyMMdd') between   cdate.date_bc and to_number(substr( spt21.control_date,1,3))+1911 || substr( spt21.control_date,4,4)
                   and step_code != '4' then 1 else 0 end) 
        INTO A_TO_EXCEED 
    FROM receive join spt21 On receive.receive_no = spt21.receive_no
    LEFT JOIN 
    (
      SELECT row_number() over(partition by spt21.receive_no order by date_chinese desc) d  ,spt21.control_date,  SPSB36.date_bc ,spt21.receive_no
      FROM spt21 join ap.SPSB36 on SPSB36.date_bc < to_number(substr( spt21.control_date,1,3))+1911 || substr( spt21.control_date,4,4)
      JOIN receive on spt21.receive_no = receive.receive_no
      WHERE  SPSB36.date_flag = 1
      AND receive.processor_no between 'P2121' and 'P2124'
      AND process_result != '57001'
     ) cdate on cdate.receive_no = receive.receive_no 
    WHERE  receive.step_code >= '2'
    AND    receive.step_code < '8'
    AND spt21.process_result != '57001'
    AND receive.processor_no   IN (
      SELECT PROCESSOR_NO   FROM SPM63 
      WHERE DEPT_NO = '70012' AND SUBSTR(PROCESSOR_NO,1,1)='P' AND QUIT_DATE IS NULL
    )
    AND cdate.d = 2
    AND substr(to_char(to_number(receive.process_date) + 19110000),1,6)  = to_char(sysdate,'yyyyMM')
    ;
    
   select nvl(sum(1),0) into A_THISMON_DONE  -- 當月辦結
  from receive
  where step_code = '8'
  and not exists (select 1 from spt21 where spt21.process_result = '57001' and spt21.receive_no = receive.receive_no)
  and processor_no  IN (
      SELECT PROCESSOR_NO   FROM SPM63 
      WHERE DEPT_NO = '70012' AND SUBSTR(PROCESSOR_NO,1,1)='P' AND QUIT_DATE IS NULL
    )
   and substr(to_char(to_number(sign_date) + 19110000),1,6)  = to_char(sysdate,'yyyyMM')
   ;
  
end dashboard_approver;

/
--------------------------------------------------------
--  DDL for Procedure DASHBOARD_CHIEF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."DASHBOARD_CHIEF" (P_IN_OBJECT_ID    in varchar2,
                                            S_NEW             out varchar2, -- 全部 線上 新申請 
                                            S_NEW_P           out varchar2, -- 全部 紙本 新申請
                                            S_APPEND          out varchar2, -- 全部 線上 後續文
                                            S_APPEND_P        out varchar2, -- 全部 紙本 後續文
                                            NEW_A             out varchar2, -- 可領 線上 新申請 
                                            NEW_P             out varchar2, --可領 紙本 新申請 
                                            APPEND_A          out varchar2, -- 可領 線上 後續文 
                                            APPEND_P          out varchar2, -- 可領 紙本 後續文
                                            S_TODO            out varchar2, -- 線上 公文
                                            S_DONE            out varchar2, -- 線上 已銷號
                                            S_REJECTED        out varchar2, -- 線上 主管退辦
                                            S_TODO_P          out varchar2, -- 紙本 公文
                                            S_DONE_P          out varchar2, -- 紙本 已銷號
                                            S_REJECTED_P      out varchar2, -- 紙本 主管退辦
                                            S_UNSIGN_NEW      out varchar2, -- 紙本 已領未簽 新案來文
                                            S_UNSIGN_APPEND   out varchar2, -- 紙本 已領未簽 後續來文
                                            S_DIVIDE_R        out varchar2, -- 人工分辦 文
                                            S_THISMON_TODO    out varchar2, -- 當月應辦
                                            S_THISMON_DONE    out varchar2, -- 當月辦結
                                            S_LASTMON_ACC     out varchar2, -- 上月累計
                                            S_ALL_ACC         out varchar2, -- 迄今累計
                                            S_PERSONAL_EXCEED out varchar2, -- 個人逾期
                                            S_AUTO_SHIFT      out varchar2, -- 自動輸辦
                                            S_OTHER_REJECTED  out varchar2, -- 他科退辦
                                            S_CHIEF_DISPATCH  out varchar2, -- 科長分派
                                            S_TO_EXCEED       out varchar2, -- 將逾期
                                            S_FOR_APPROVE     out varchar2, -- 陳核中
                                            S_EXCEEDED        out varchar2, -- 已逾期
                                            S_IMG_NOT_READY   out varchar2, -- 逾期影像未到之線上公文
                                            S_NOT_SECTION     out varchar2, -- 持有者都不是 70012/70014 之線上公文
                                            S_TO_APPROVE      out varchar2) -- 待核公文
 is
begin
  /*
    待核公文: receiver list waiting for approved
    ModlfyDate : 104/07/22
    104/07/22 :  add conditin sptd02.flow_step = '02'
    104/08/02 : remove the condition from paper form status
  */
  dashboard_section(P_IN_OBJECT_ID,
                    S_NEW,
                    S_NEW_P,
                    S_APPEND,
                    S_APPEND_P,
                    NEW_A,
                    NEW_P,
                    APPEND_A,
                    APPEND_P,
                    S_TODO,
                    S_DONE,
                    S_REJECTED,
                    S_TODO_P,
                    S_DONE_P,
                    S_REJECTED_P,
                    S_UNSIGN_NEW,
                    S_UNSIGN_APPEND,
                    S_DIVIDE_R,
                    S_THISMON_TODO,
                    S_THISMON_DONE,
                    S_LASTMON_ACC,
                    S_ALL_ACC,
                    S_PERSONAL_EXCEED,
                    S_AUTO_SHIFT,
                    S_OTHER_REJECTED,
                    S_CHIEF_DISPATCH,
                    S_TO_EXCEED,
                    S_FOR_APPROVE,
                    S_EXCEEDED,
                    S_IMG_NOT_READY,
                    S_NOT_SECTION);

  select sum(cnt)
    into S_TO_APPROVE
    from (
          /*
          SELECT count(1) cnt
             FROM SPT21 R
             LEFT JOIN SPM75 T
               ON R.TYPE_NO = T.TYPE_NO
             JOIN RECEIVE
               ON R.RECEIVE_NO = RECEIVE.RECEIVE_NO
             JOIN spm56
               on SPM56.receive_no = R.receive_no
              and spm56.processor_no = R.processor_no
              and SPM56.form_file_a =
                  (select max(form_file_a)
                     from spm56 s56
                    where SPM56.receive_no = s56.receive_no)
            WHERE nvl(spm56.issue_flag, '0') = '1' -- 已製稿
              AND nvl(ONLINE_SIGN, '0') != '1' --紙本
              AND R.processor_no in (select processor_no from spm63 where dept_no = '70012' and quit_date is null)
           UNION ALL */
          SELECT count(1) cnt
            FROM SPT21 R
            LEFT JOIN SPM75 T
              ON R.TYPE_NO = T.TYPE_NO
            JOIN RECEIVE
              ON R.RECEIVE_NO = RECEIVE.RECEIVE_NO
             AND R.APPL_NO = RECEIVE.APPL_NO
            JOIN SPM56
              on SPM56.receive_no = R.receive_no
             AND SPM56.processor_no = R.processor_no
             AND SPM56.form_file_a =
                 (select max(form_file_a)
                    from spm56 s56
                   where SPM56.receive_no = s56.receive_no)
            LEFT JOIN ap.SPTD02 sptd02
              on SPM56.form_file_a = SPTD02.form_file_a
           WHERE nvl(ONLINE_SIGN, '0') = '1'
             AND nvl(SPM56.issue_flag, '0') = '1'
             AND sptd02.flow_step = '02'
             AND substr(R.processor_no, 1, 1) != 'P'
             AND R.process_result != '57001'
          UNION ALL
          SELECT count(1) cnt
            FROM APPL R
            JOIN SPM56
              on SPM56.APPL_NO = R.APPL_NO
             AND SPM56.processor_no = R.processor_no
             AND SPM56.form_file_a =
                 (select max(form_file_a)
                    from spm56 s56
                   where SPM56.appl_no = s56.appl_no)
            LEFT JOIN ap.SPTD02
              on SPM56.form_file_a = SPTD02.form_file_a
           WHERE nvl(ONLINE_SIGN, '0') = '1'
             AND nvl(SPM56.issue_flag, '0') = '1'
             AND sptd02.flow_step = '02'
             AND substr(R.processor_no, 1, 1) != 'P');

end dashboard_chief;

/
--------------------------------------------------------
--  DDL for Procedure DASHBOARD_OUTSOURCING
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."DASHBOARD_OUTSOURCING" (
  P_IN_OBJECT_ID in varchar2,
  UNSIGN_NEW out varchar2, -- 新案來文
  TODO out varchar2, -- 線上公文 
  TODO_P out varchar2, -- 紙本公文 
  DONE out varchar2, -- 線上已銷號 
  DONE_P out varchar2, --紙本已銷號
  NEW_A out varchar2, -- 線上新申請
  NEW_P out varchar2, -- 紙本新申請
  THISMON_TODO out varchar2, -- 當月應辦
  THISMON_DONE out varchar2, -- 當月辦結
  LASTMON_ACC out varchar2, -- 上月累計
  TO_EXCEED out varchar2) -- 即將逾期
is
begin
  /*
  Desc: DashBoard for OutSourcing
  ModifyDate : 104/09/09
  104/07/09 : change the condition for calcuate close receive (THISMON_DONE) by sign_date (close date of form)
  104/07/22 : UNSIGN_NEW add filter AND RETURN_NO not in ('4','A','B','C');
  104/09/09: exclude the receives which process_result = 57001
  */
  -- 紙本已領未簽 新案來文
    SELECT COUNT(1)
    INTO UNSIGN_NEW
    FROM SPT23
    WHERE SPT23.data_seq = (select max(data_seq) from spt23 s23 where SPT23.receive_no = s23.receive_no) 
      AND TRANS_NO = '912'
        AND SUBSTR(RECEIVE_NO,4,1) = '2'
        AND SPT23.ACCEPT_DATE IS NULL
        AND OBJECT_TO = P_IN_OBJECT_ID
        AND not exists ( select 1 from spt21 where spt21.receive_no = spt23.receive_no and spt21.process_result = '57001')
        ;
      
  -- 線上 公文 已銷號
   SELECT
   COUNT(CASE WHEN s21.PROCESS_RESULT is null  AND RECEIVE.RECEIVE_NO is not null THEN 1 ELSE NULL END) AS TODO,
         COUNT(CASE WHEN s21.PROCESS_RESULT is not null AND s21.process_result != '57001'  THEN 1 ELSE NULL END) AS DONE
   INTO TODO, DONE
   FROM  RECEIVE  
   JOIN SPT21 s21 ON s21.RECEIVE_NO = RECEIVE.RECEIVE_NO 
   WHERE RECEIVE.PROCESSOR_NO = P_IN_OBJECT_ID
   AND RECEIVE.step_code > '0'
   AND RECEIVE.step_code < '8'
    ;
 
  
  -- 紙本 公文
  SELECT COUNT(1)
  INTO TODO_P
    FROM SPT21 R
        LEFT JOIN SPT23
          ON R.receive_no = SPT23.receive_no
         AND R.OBJECT_ID = Spt23.OBJECT_TO
        LEFT JOIN SPM75 T
          ON R.TYPE_NO = T.TYPE_NO
       WHERE SPT23.data_seq =
             (select max(data_seq)
                from spt23 s23
               where SPT23.receive_no = s23.receive_no)
         AND SPT23.ACCEPT_DATE IS NOT NULL
         AND PROCESS_RESULT IS  NULL
         AND R.object_id = P_IN_OBJECT_ID
         AND R.trans_no = '912'
         AND R.process_result != '57001'
         ;
      
  -- 紙本 已銷號
  SELECT COUNT(1)
  INTO DONE_P
  FROM SPT21
        LEFT JOIN SPM75
          on SPT21.TYPE_NO = SPM75.TYPE_NO
        LEFT JOIN SPT13
          on SPT21.RECEIVE_NO = SPT13.RECEIVE_NO
        WHERE NOT EXISTS (SELECT RECEIVE_NO FROM SPT41 WHERE RECEIVE_NO = SPT21.RECEIVE_NO and processor_no = SPT21.processor_no and check_datetime is not null)
         AND PROCESS_RESULT IS NOT NULL
         AND SPT21.object_id = P_IN_OBJECT_ID
         AND SPT21.trans_no = '912'
         AND SPT21.process_result != '57001'
         ;
      
  -- 線上 新申請 
  SELECT COUNT(1)
  INTO NEW_A
  FROM RECEIVE
  WHERE STEP_CODE = '0'
  AND doc_complete = '1'
  AND RETURN_NO not in ('4','A','B','C','D')
  AND SUBSTR(RECEIVE_NO,4,1) = '2'
  AND not exists (select 1 from spt21 where spt21.process_result = '57001' and spt21.receive_no = receive.receive_no)
  ;
  
  -- 紙本 新申請
  SELECT COUNT(1)
  INTO NEW_P
  FROM SPT21
  WHERE  SUBSTR(RECEIVE_NO,4,1) = '2'
      AND PROCESS_RESULT IS NULL
      AND OBJECT_ID IN (
          SELECT PROCESSOR_NO 
          FROM SPM63 
          WHERE DEPT_NO ='70012' AND QUIT_DATE IS NULL OR (PROCESSOR_NO='70012' )
      )
      ;
      
     -- 當月應辦 
   SELECT nvl(sum(d),0)  INTO THISMON_TODO
   FROM
   ( 
    SELECT  nvl(b.base,0) * nvl(mday.days,0) + nvl(a.factor,0) d
    FROM quota a JOIN quota_base b on a.processor_no = b.processor_no AND a.yyyy = b.yyyy
    LEFT JOIN (SELECT  substr(date_bc,1,6) yyyymm, count(1) days   
    FROM spmff WHERE  date_flag = 1 group by substr(date_bc,1,6) ) mday
    on mday.yyyymm = b.yyyy || a.mm
    WHERE trim(a.processor_no) = P_IN_OBJECT_ID
    AND a.yyyy = to_char(sysdate,'yyyy') AND a.mm = to_char(sysdate,'MM')
    )
    ;
    -- 個人將逾期
    SELECT  
         SUM( case when to_char(sysdate,'yyyyMMdd') between   cdate.date_bc and to_number(substr( spt21.control_date,1,3))+1911 || substr( spt21.control_date,4,4)
                   and step_code != '4' then 1 else 0 end) 
        INTO TO_EXCEED 
    FROM receive join spt21 On receive.receive_no = spt21.receive_no
    LEFT JOIN 
    (
      SELECT row_number() over(partition by spt21.receive_no order by date_chinese desc) d  ,spt21.control_date,  SPSB36.date_bc ,spt21.receive_no
      FROM spt21 join ap.SPSB36 on SPSB36.date_bc < to_number(substr( spt21.control_date,1,3))+1911 || substr( spt21.control_date,4,4)
      JOIN receive on spt21.receive_no = receive.receive_no
      WHERE  SPSB36.date_flag = 1
      AND receive.processor_no = P_IN_OBJECT_ID
     ) cdate on cdate.receive_no = receive.receive_no 
    WHERE  receive.step_code >= '2'
    AND    receive.step_code < '8'
    AND spt21.process_result != '57001'
    AND receive.processor_no = P_IN_OBJECT_ID
    AND cdate.d = 2
     and substr(to_char(to_number(receive.process_date) + 19110000),1,6)  = to_char(sysdate,'yyyyMM')
    ;
    
   select nvl(sum(1),0) into THISMON_DONE  -- 當月辦結
  from receive
  where step_code = '8'
  and processor_no = P_IN_OBJECT_ID
   and substr(to_char(to_number(sign_date) + 19110000),1,6)  = to_char(sysdate,'yyyyMM')
   and not exists (select 1 from spt21 where spt21.process_result = '57001' and spt21.receive_no = receive.receive_no)
   ;
   dbms_output.put_line(THISMON_TODO);
  
end dashboard_outsourcing;

/
--------------------------------------------------------
--  DDL for Procedure DASHBOARD_PERSONAL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."DASHBOARD_PERSONAL" (
  P_IN_OBJECT_ID in varchar2,
  NEW_A out varchar2 , -- 線上新申請
  NEW_P out varchar2 , -- 紙本新申請
  APPEND_A out varchar2 , -- 線上後續文
  APPEND_P out varchar2 , --紙本後續文
  TODO out varchar2 , -- 線上公文 
  TODO_P out varchar2 , -- 紙本公文 
  DONE out varchar2 , -- 線上已銷號 
  DONE_P out varchar2 , --紙本已銷號
  REJECTED out varchar2 , -- 線上主管退辦
  REJECTED_P out varchar2 , -- 紙本主管退辦
  UNSIGN_NEW out varchar2 , -- 新案來文
  UNSIGN_APPEND out varchar2 , -- 後續來文
  THISMON_TODO out varchar2 , -- 當月應辦
  THISMON_DONE out varchar2 , -- 當月辦結
  LASTMON_ACC out varchar2 , -- 上月累計
  ALL_ACC out varchar2 , -- 迄今累計
  PERSONAL_EXCEED out varchar2 , -- 個人逾期
  AUTO_SHIFT out varchar2 , --自動輸辦
  OTHER_REJECTED out varchar2 , -- 他科退辦
  CHIEF_DISPATCH out varchar2 , -- 科長分派
  TO_EXCEED out varchar2 , -- 將逾期
  FOR_APPROVE out varchar2 , -- 陳核中
  EXCEEDED out varchar2   -- 已逾期
  )
is
begin
  /*
  ModifyDate :104/09/09
   update THISMON_DONE 當月已辦的計算
  104/07/07 : change the waiting receiver calculating rule => return_no not in ('4','A','B','C')
  104/07/07 : add TO_EXCEED , FOR_APPROVE ,EXCEEDED
  104/07/09 : change the condition for calcuate close receive (THISMON_DONE) by sign_date (close date of form)
  104/07/23 : change conditoin for project  processor_no ,change from spt31.sch_processor_no to appl.appl_no
  104/07/30 : turning 紙本已領未簽 , select spt23 ,not spt21
  104/07/31: update the condition for accept date
  104/09/09: exclude the receives which process_result = 57001
  */
  -- 線上 新申請 後續文

  SELECT
     COUNT(CASE WHEN SUBSTR(RECEIVE_NO,4,1) in ('1','2') THEN  1 ELSE null END),
    COUNT(CASE WHEN SUBSTR(RECEIVE_NO,4,1) = '3' THEN  1 ELSE NULL END)
  INTO NEW_A, APPEND_A 
  FROM RECEIVE
  WHERE STEP_CODE = '0'
  AND  doc_complete = '1'
  AND RETURN_NO not in ('4','A','B','C','D')
  AND not exists (select 1 from spt21 where spt21.process_result = '57001' and spt21.receive_no = receive.receive_no)
  ;
    dbms_output.put_line( NEW_A || ',' || APPEND_A  );
  -- 紙本 新申請後續文
  SELECT
      COUNT(CASE WHEN SUBSTR(RECEIVE_NO,4,1) = '2' THEN  1 ELSE NULL END),
      COUNT(CASE WHEN SUBSTR(RECEIVE_NO,4,1) = '3' THEN  1 ELSE NULL END)
  INTO NEW_P, APPEND_P
  FROM SPT21
  WHERE  PROCESS_RESULT IS NULL
      AND OBJECT_ID IN (
          SELECT PROCESSOR_NO 
          FROM SPM63 
          WHERE DEPT_NO ='70012' AND QUIT_DATE IS NULL
      );
        dbms_output.put_line( NEW_P || ',' || APPEND_P );
  -- 線上 公文 已銷號 主管退辦
  SELECT
   COUNT(CASE WHEN s21.PROCESS_RESULT is null  AND RECEIVE.RECEIVE_NO is not null THEN 1 ELSE NULL END) AS TODO,
          COUNT(CASE WHEN s21.PROCESS_RESULT is not null AND s21.process_result != '57001'   THEN 1 ELSE NULL END) AS DONE,
          COUNT(CASE WHEN step_code = '5' and substr(RECEIVE.processor_no,1,1) != 'P'  AND s21.process_result != '57001'
               THEN 1 ELSE NULL END) AS REJECTED     
   INTO TODO, DONE, REJECTED 
  FROM  RECEIVE  
  JOIN SPT21 s21 ON s21.RECEIVE_NO = RECEIVE.RECEIVE_NO 
  WHERE RECEIVE.PROCESSOR_NO = P_IN_OBJECT_ID
  AND RECEIVE.step_code > '0'
  AND RECEIVE.step_code < '8'
    ;
    dbms_output.put_line(TODO || ',' || DONE || ',' || REJECTED );
  -- 紙本 公文
  SELECT COUNT(1)
  INTO TODO_P
  FROM SPT21
  LEFT JOIN SPT23 ON SPT21.receive_no = SPT23.receive_no  AND SPT21.OBJECT_ID = Spt23.OBJECT_TO
  WHERE SPT23.data_seq = (select max(data_seq) from spt23 s23 where SPT23.receive_no = s23.receive_no)  
    AND TRIM(PROCESS_RESULT) IS NULL
    AND SPT21.object_id = P_IN_OBJECT_ID
    AND SPT23.ACCEPT_DATE IS NOT NULL
    AND SPT21.trans_no = '912'
    ;
      dbms_output.put_line(TODO_P);
  -- 紙本 已銷號
  SELECT COUNT(1)
  INTO DONE_P
  FROM SPT21
        LEFT JOIN SPM75
          on SPT21.TYPE_NO = SPM75.TYPE_NO
        LEFT JOIN SPT13
          on SPT21.RECEIVE_NO = SPT13.RECEIVE_NO
        WHERE  NOT EXISTS (SELECT RECEIVE_NO FROM SPT41 WHERE RECEIVE_NO = SPT21.RECEIVE_NO and processor_no = SPT21.processor_no and check_datetime is not null)
         AND PROCESS_RESULT IS NOT NULL
         AND SPT21.object_id = P_IN_OBJECT_ID
         AND SPT21.trans_no = '912'
         AND PROCESS_RESULT != '57001'
   ;
  -- 紙本 主管退辦
  SELECT count(1) INTO REJECTED_P
  FROM spt21
  LEFT join spt41 on spt21.receive_no = spt41.receive_no
  AND spt41.appl_no = spt21.appl_no
  LEFT join SPT23 a on a.receive_no = SPT21.receive_no
  LEFT join SPT23 b  on b.receive_no = SPT21.receive_no
  WHERE  spt21.object_id = P_IN_OBJECT_ID
  AND spt21.process_result != '57001'
  AND a.TRANS_NO in ('921','922','923')
  AND a.OBJECT_FROM in ( select processor_no from spm63 where substr(dept_no,1,3) = '700' and title  in ('科長','專門委員','科員')  
         and processor_no = B.processor_no
        and spm63.quit_date is not null
      )
  AND b.TRANS_NO='913'
  AND b.OBJECT_TO= P_IN_OBJECT_ID
  AND a.DATA_SEQ = b.DATA_SEQ +1
  ;
      dbms_output.put_line(REJECTED_P);
  -- 紙本已領未簽 新案來文 後續來文
    SELECT COUNT(CASE WHEN SUBSTR(RECEIVE_NO,4,1) = '2' THEN 1 ELSE NULL END),
           COUNT(CASE WHEN SUBSTR(RECEIVE_NO,4,1) = '3' THEN 1 ELSE NULL END)
    INTO UNSIGN_NEW, UNSIGN_APPEND
    FROM SPT23
    WHERE data_seq = (select max(data_seq) from spt23 s23 where spt23.receive_no = s23.receive_no)  
     AND TRANS_NO = '912'
     AND ACCEPT_DATE IS NULL
     AND OBJECT_TO = P_IN_OBJECT_ID
     AND not exists (select 1 from spt21 where spt21.process_result = '57001' and spt21.receive_no = SPT23.receive_no)
     ;
   dbms_output.put_line(UNSIGN_NEW || ',' || UNSIGN_APPEND);
   -- 個人逾期 , 自動輪辦 , 他科退辦 ,科長分派
    SELECT count(CASE WHEN appl.divide_code = '1' and appl.is_overtime='1' THEN 1 ELSE null END),
           count(CASE WHEN appl.divide_code = '2' THEN 1 ELSE null END),
           count(CASE WHEN appl.divide_code = '3' THEN 1 ELSE null END),
           count(CASE WHEN appl.divide_code = '4' THEN 1 ELSE null END)
    INTO PERSONAL_EXCEED, AUTO_SHIFT ,OTHER_REJECTED ,CHIEF_DISPATCH
    FROM appl join spt31 on appl.appl_no = spt31.appl_no
    WHERE  appl.processor_no = P_IN_OBJECT_ID;
    dbms_output.put_line(PERSONAL_EXCEED|| ',' || AUTO_SHIFT || ',' ||OTHER_REJECTED || ',' ||CHIEF_DISPATCH);
    -- 個人將逾期, 已逾期
    SELECT  
         SUM( case when to_char(sysdate,'yyyyMMdd') between   cdate.date_bc and to_number(substr( spt21.control_date,1,3))+1911 || substr( spt21.control_date,4,4)
                   and (sd02.node_status is null or sd02.node_status !='900') then 1 else 0 end) ,
         SUM( case when to_char(sysdate,'yyyyMMdd') between   cdate.date_bc and to_number(substr( spt21.control_date,1,3))+1911 || substr( spt21.control_date,4,4)
                   and (sd02.node_status !='900') then 1 else 0 end) ,
         SUM( case when to_char(sysdate,'yyyyMMdd') > to_number(substr( spt21.control_date,1,3))+1911 || substr( spt21.control_date,4,4)
              then 1 else 0 end)      
        INTO TO_EXCEED , FOR_APPROVE ,EXCEEDED
    FROM receive join spt21 On receive.receive_no = spt21.receive_no
    LEFT JOIN SPM56 s56 ON s56.RECEIVE_NO = RECEIVE.RECEIVE_NO AND s56.processor_no =  RECEIVE.PROCESSOR_NO
                             AND s56.issue_flag = '1'
    LEFT JOIN ap.sptd02 sd02 ON s56.form_file_a = sd02.form_file_a 
    LEFT JOIN 
    (
      SELECT row_number() over(partition by spt21.receive_no order by date_chinese desc) d  ,spt21.control_date,  SPSB36.date_bc ,spt21.receive_no
      FROM spt21 join ap.SPSB36 on SPSB36.date_bc < to_number(substr( spt21.control_date,1,3))+1911 || substr( spt21.control_date,4,4)
      JOIN receive on spt21.receive_no = receive.receive_no
      WHERE  SPSB36.date_flag = 1
      AND receive.processor_no = P_IN_OBJECT_ID
     ) cdate on cdate.receive_no = receive.receive_no 
    WHERE  receive.step_code >= '2'
    AND    receive.step_code < '8'
    AND spt21.process_result != '57001'
    AND receive.processor_no = P_IN_OBJECT_ID
    AND cdate.d = 2
    and substr(to_char(to_number(receive.process_date) + 19110000),1,6)  = to_char(sysdate,'yyyyMM')
    ;
   dbms_output.put_line(TO_EXCEED || ',' || EXCEEDED);
    -- 當月應辦 
   SELECT nvl(sum(d),0)  INTO THISMON_TODO
   FROM
   ( 
    SELECT  nvl(b.base,0) * nvl(mday.days,0) + nvl(a.factor,0) d
    FROM quota a JOIN quota_base b on a.processor_no = b.processor_no AND a.yyyy = b.yyyy
    LEFT JOIN (SELECT  substr(date_bc,1,6) yyyymm, count(1) days   
    FROM spmff WHERE  date_flag = 1 group by substr(date_bc,1,6) ) mday
    on mday.yyyymm = b.yyyy || a.mm
    WHERE trim(a.processor_no) = P_IN_OBJECT_ID
    AND a.yyyy = to_char(sysdate,'yyyy') AND a.mm = to_char(sysdate,'MM')
    )
    ;
    
        
  select nvl(sum(1),0) into THISMON_DONE  -- 當月辦結
  from receive
  where step_code = '8'
   AND processor_no = P_IN_OBJECT_ID
   AND substr(to_char(to_number(sign_date) + 19110000),1,6)  = to_char(sysdate,'yyyyMM')
   AND not exists (select 1 from spt21 where spt21.process_result = '57001' and spt21.receive_no = receive.receive_no)
   ;
   dbms_output.put_line(THISMON_TODO);
   
   select nvl(sum(1),0) into LASTMON_ACC -- 上月累計
  from receive
  where step_code = '8'
   AND processor_no = P_IN_OBJECT_ID
   AND substr(to_char(to_number(sign_date) + 19110000),1,6) = to_char(add_months(sysdate,-1),'yyyyMM')
   AND not exists (select 1 from spt21 where spt21.process_result = '57001' and spt21.receive_no = receive.receive_no)
   ;
   
  select nvl(sum(1),0) into ALL_ACC -- 迄今累計
  from receive
  where step_code = '8'
  and sign_date is not null
  AND processor_no = P_IN_OBJECT_ID
  AND not exists (select 1 from spt21 where spt21.process_result = '57001' and spt21.receive_no = receive.receive_no)
  ;
end dashboard_personal;

/
--------------------------------------------------------
--  DDL for Procedure DASHBOARD_SECTION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."DASHBOARD_SECTION" (P_IN_OBJECT_ID    in varchar2,
                                              S_NEW             out varchar2, -- 全部 線上 新申請 
                                              S_NEW_P           out varchar2, -- 全部 紙本 新申請
                                              S_APPEND          out varchar2, -- 全部 線上 後續文
                                              S_APPEND_P        out varchar2, -- 全部 紙本 後續文
                                              NEW_A             out varchar2, -- 可領 線上 新申請 
                                              NEW_P             out varchar2, --可領 紙本 新申請 
                                              APPEND_A          out varchar2, -- 可領 線上 後續文 
                                              APPEND_P          out varchar2, -- 可領 紙本 後續文
                                              S_TODO            out varchar2, -- 線上 公文
                                              S_DONE            out varchar2, -- 線上 已銷號
                                              S_REJECTED        out varchar2, -- 線上 主管退辦
                                              S_TODO_P          out varchar2, -- 紙本 公文
                                              S_DONE_P          out varchar2, -- 紙本 已銷號
                                              S_REJECTED_P      out varchar2, -- 紙本 主管退辦
                                              S_UNSIGN_NEW      out varchar2, -- 紙本 已領未簽 新案來文
                                              S_UNSIGN_APPEND   out varchar2, -- 紙本 已領未簽 後續來文
                                              S_DIVIDE_R        out varchar2, -- 人工分辦 文
                                              S_THISMON_TODO    out varchar2, -- 當月應辦
                                              S_THISMON_DONE    out varchar2, -- 當月辦結
                                              S_LASTMON_ACC     out varchar2, -- 上月累計
                                              S_ALL_ACC         out varchar2, -- 迄今累計
                                              S_PERSONAL_EXCEED out varchar2, -- 個人逾期
                                              S_AUTO_SHIFT      out varchar2, -- 自動輸辦
                                              S_OTHER_REJECTED  out varchar2, -- 他科退辦
                                              S_CHIEF_DISPATCH  out varchar2, -- 科長分派
                                              S_TO_EXCEED       out varchar2, -- 將逾期
                                              S_FOR_APPROVE     out varchar2, -- 陳核中
                                              S_EXCEEDED        out varchar2, -- 已逾期
                                              S_IMG_NOT_READY   out varchar2, -- 逾期影像未到之線上公文
                                              S_NOT_SECTION     out varchar2) -- 持有者都不是 70012/70014 之線上公文
 is
begin
  /*
   Desc: Dashboard of manager
   ModifyDate : 104/09/24
   (1) update S_THISMON_TODO (已辦案數) judge by  step_code
   (2) S_TO_EXCEED,S_FOR_APPROVE,S_EXCEEDED 重複統計
    104/6/26: Modify 已辦案數
    104/07/09 : change the condition for calcuate close receive (S_THISMON_DONE) by sign_date (close date of form)
    104/07/30 : turning 紙本已領未簽 , select spt23 ,not spt21
    104/07/31: update the condition for accept date
    104/08/10: add S_IMG_NOT_READY and S_NOT_SECTION
    104/09/09: exclude the receives which process_result = 57001
    104/09/24: tune the performance for return-paper-recieve
  */
  --  線上可領 新申請 後續文     
  SELECT COUNT(CASE
                 WHEN SUBSTR(RECEIVE_NO, 4, 1) in ('1', '2') THEN
                  1
                 ELSE
                  null
               END),
         COUNT(CASE
                 WHEN SUBSTR(RECEIVE_NO, 4, 1) = '3' THEN
                  1
                 ELSE
                  null
               END)
    INTO NEW_A, APPEND_A
    FROM RECEIVE
     WHERE  STEP_CODE ='0'
     AND  doc_complete = '1'
     AND return_no not in ('4','A','B','C','D')
     AND not exists (select 1 from spt21 where spt21.process_result = '57001' and spt21.receive_no = receive.receive_no)
     ;

  --  紙本可領 新申請 後續文
  SELECT COUNT(CASE
                 WHEN SUBSTR(RECEIVE_NO, 4, 1) = '2' THEN
                  1
                 ELSE
                  NULL
               END),
         COUNT(CASE
                 WHEN SUBSTR(RECEIVE_NO, 4, 1) = '3' THEN
                  1
                 ELSE
                  NULL
               END)
    INTO NEW_P, APPEND_P
    FROM SPT21
   WHERE PROCESS_RESULT IS NULL
     AND object_id IN (SELECT PROCESSOR_NO
                         FROM SPM63
                        WHERE DEPT_NO = '70012'
                          AND QUIT_DATE IS NULL)
    ;

  -- 全部 線上 新申請 後續文
  SELECT COUNT(CASE
                 WHEN SUBSTR(SPT21.RECEIVE_NO, 4, 1) = '2'  THEN
                  1
                 ELSE
                  NULL
               END),
         COUNT(CASE
                 WHEN SUBSTR(SPT21.RECEIVE_NO, 4, 1) = '3' THEN
                  1
                 ELSE
                  NULL
               END)
    INTO S_NEW, S_APPEND
    FROM SPT21 JOIN RECEIVE ON SPT21.receive_no = RECEIVE.receive_no
   WHERE  SPT21.DEPT_NO = '70012'
   AND SPT21.process_result != '57001'
       ;

  --  紙本全部 新申請 後續文
  select COUNT(CASE  WHEN SUBSTR(spt21.RECEIVE_NO, 4, 1) = '2' THEN    1
                 ELSE    NULL        END),
         COUNT(CASE  WHEN SUBSTR(spt21.RECEIVE_NO, 4, 1) = '3' THEN    1
                 ELSE    NULL        END)
    INTO S_NEW_P, S_APPEND_P
  from spt21 join spt23
  on spt21.receive_no = spt23.receive_no
  and spt21.trans_seq = spt23.data_seq
  where ( spt21.object_id  = '70012' or spt21.object_id  = '60037' )
  and spt21.accept_date is not null
  and (spt21.process_result !='57001' or spt21.process_result is null)
 ;

  -- 線上 公文 已銷號 主管退辦
  SELECT COUNT(CASE WHEN s21.PROCESS_RESULT is null  AND RECEIVE.RECEIVE_NO is not null THEN 1 ELSE NULL END) AS TODO,
          COUNT(CASE WHEN s21.PROCESS_RESULT is not null  AND s21.process_result != '57001'  THEN 1 ELSE NULL END) AS DONE,
          COUNT(CASE WHEN RECEIVE.step_code = '5' AND s21.process_result != '57001' and substr(SPM63.processor_no,1,1) != 'P' 
               THEN 1 ELSE NULL END) AS REJECTED
    INTO S_TODO, S_DONE, S_REJECTED
     FROM SPM63 LEFT JOIN RECEIVE  ON   SPM63.PROCESSOR_NO = RECEIVE.PROCESSOR_NO 
      JOIN SPT21 s21 ON s21.RECEIVE_NO = RECEIVE.RECEIVE_NO 
      WHERE SPM63.DEPT_NO='70012' AND SPM63.QUIT_DATE IS NULL    
      AND RECEIVE.step_code > '0'
      AND RECEIVE.step_code < '8'
      ;

  -- 紙本 公文
  SELECT COUNT(1)
    INTO S_TODO_P
    FROM SPT21
    LEFT JOIN SPT23
      ON SPT21.receive_no = SPT23.receive_no
     AND SPT21.object_id = Spt23.OBJECT_TO
   WHERE SPT23.data_seq =
         (select max(data_seq)
            from spt23 s23
           where SPT23.receive_no = s23.receive_no)
     AND PROCESS_RESULT IS NULL
     AND SPT23.ACCEPT_DATE IS NOT NULL
     AND SPT21.object_id IN (SELECT PROCESSOR_NO
                         FROM SPM63
                        WHERE DEPT_NO = '70012'
                          AND QUIT_DATE IS NULL)
     AND SPT21.trans_no = '912'
    ;

  -- 紙本 已銷號
  SELECT COUNT(1)
    INTO S_DONE_P
    FROM SPT21
    WHERE  PROCESS_RESULT IS NOT NULL
     AND  PROCESS_RESULT != '57001'
     AND NOT EXISTS (SELECT RECEIVE_NO FROM SPT41 WHERE RECEIVE_NO = SPT21.RECEIVE_NO and processor_no = SPT21.processor_no and check_datetime is not null)
     AND object_id IN (SELECT PROCESSOR_NO
                         FROM SPM63
                        WHERE DEPT_NO = '70012'
                          AND QUIT_DATE IS NULL)
    AND trans_no = '912'
    ;

  -- 紙本主管退辦
  SELECT COUNT(1)
    INTO S_REJECTED_P
    FROM SPT21
    LEFT JOIN SPT41
      ON SPT21.RECEIVE_NO = SPT41.RECEIVE_NO
     AND SPT41.APPL_NO = SPT21.APPL_NO
    LEFT JOIN SPT23 A
      ON A.RECEIVE_NO = SPT21.RECEIVE_NO
    LEFT JOIN SPT23 B
      ON B.RECEIVE_NO = SPT21.RECEIVE_NO
   WHERE SPT21.object_id IN (SELECT PROCESSOR_NO
                               FROM SPM63
                              WHERE DEPT_NO = '70012'
                                AND QUIT_DATE IS NULL)
     AND SPT21.PROCESS_RESULT != '57001'
     AND A.TRANS_NO IN ('921', '922', '923')
     AND a.OBJECT_FROM in ( select processor_no from spm63 where substr(dept_no,1,3) = '700' and title  in ('科長','專門委員','科員')  
         and processor_no = B.processor_no
        and spm63.quit_date is not null
      )
     AND B.TRANS_NO = '913'
     AND B.OBJECT_TO = SPT21.object_id
     AND A.DATA_SEQ = B.DATA_SEQ + 1
     AND SPT21.PROCESSOR_NO IS NOT NULL;

  -- 紙本已領未簽 新案來文 後續來文
  SELECT COUNT(CASE
                 WHEN SUBSTR(RECEIVE_NO, 4, 1) = '2' THEN
                  1
                 ELSE
                  NULL
               END),
         COUNT(CASE
                 WHEN SUBSTR(RECEIVE_NO, 4, 1) = '3' THEN
                  1
                 ELSE
                  NULL
               END)
    INTO S_UNSIGN_NEW, S_UNSIGN_APPEND
    FROM SPT23
   WHERE TRANS_NO = '912'
     AND ACCEPT_DATE IS NULL
     AND Object_To IN (SELECT PROCESSOR_NO
                         FROM SPM63
                        WHERE DEPT_NO = '70012'
                          AND QUIT_DATE IS NULL)
     AND data_seq = (select max(data_seq)
                       from spt23 s23
                      where spt23.receive_no = s23.receive_no)
     AND not exists ( select 1 from spt21 where spt21.receive_no = spt23.receive_no and spt21.process_result = '57001') 
   order by receive_no desc;

  -- 人工分辦
  -- SELECT COUNT(1) INTO S_DIVIDE_C FROM APPL WHERE DIVIDE_CODE = '4'; -- 案
  SELECT COUNT(1)
    INTO S_DIVIDE_R
    FROM RECEIVE
   WHERE RETURN_NO in ('4', 'A', 'B', 'C','D')
     AND STEP_CODE = '0'
     AND not exists ( select 1 from spt21 where spt21.receive_no = RECEIVE.receive_no and spt21.process_result = '57001') 
     ; -- 文

  -- 當月應辦 

  SELECT SUM(d)
    INTO S_THISMON_TODO
    FROM (SELECT sum(nvl(b.base, 0) * nvl(mday.days, 0) + nvl(a.factor, 0)) d
            FROM quota a
            JOIN quota_base b
              on a.processor_no = b.processor_no
             AND a.yyyy = b.yyyy
            LEFT JOIN (SELECT substr(date_bc, 1, 6) yyyymm, count(1) days
                        FROM spmff
                       WHERE date_flag = 1
                       group by substr(date_bc, 1, 6)) mday
              on mday.yyyymm = b.yyyy || a.mm
           where trim(a.processor_no) IN
                 (SELECT PROCESSOR_NO
                    FROM SPM63
                   WHERE DEPT_NO = '70012'
                     AND QUIT_DATE IS NULL)
             AND a.yyyy = to_char(sysdate, 'yyyy')
             AND a.mm = to_char(sysdate, 'MM'));

  select sum(case
               when divide_code = '1' and is_overtime = '1' then
                1
               else
                0
             end),
         sum(case
               when divide_code = '2' then
                1
               else
                0
             end),
         sum(case
               when divide_code = '3' then
                1
               else
                0
             end),
         sum(case
               when divide_code = '4' then
                1
               else
                0
             end)
    into S_PERSONAL_EXCEED,
         S_AUTO_SHIFT,
         S_OTHER_REJECTED,
         S_CHIEF_DISPATCH
    from appl;

  --- 當月辦結
  select nvl(sum(1), 0)
    into S_THISMON_DONE
    from receive
   where step_code = '8'
     AND substr(to_char(to_number(sign_date) + 19110000), 1, 6) =
         to_char(sysdate, 'yyyyMM')
     AND not exists ( select 1 from spt21 where spt21.receive_no = RECEIVE.receive_no and spt21.process_result = '57001')     
         ;
         
  select nvl(sum(1),0) into S_LASTMON_ACC -- 上月累計
  from receive
  where step_code = '8'
   AND substr(to_char(to_number(sign_date) + 19110000),1,6) = to_char(add_months(sysdate,-1),'yyyyMM')
   AND not exists ( select 1 from spt21 where spt21.receive_no = RECEIVE.receive_no and spt21.process_result = '57001') 
   ;
   
  select nvl(sum(1),0) into S_ALL_ACC -- 迄今累計
  from receive
  where step_code = '8'
  and sign_date is not null
   AND not exists ( select 1 from spt21 where spt21.receive_no = RECEIVE.receive_no and spt21.process_result = '57001') 
  ;

  -- 個人將逾期, 已逾期
  SELECT SUM(case
               when to_char(sysdate, 'yyyyMMdd') between cdate.date_bc and
                    to_number(substr(spt21.control_date, 1, 3)) + 1911 ||
                    substr(spt21.control_date, 4, 4) and step_code != '4' then
                1
               else
                0
             end),
         SUM(case
               when to_char(sysdate, 'yyyyMMdd') between cdate.date_bc and
                    to_number(substr(spt21.control_date, 1, 3)) + 1911 ||
                    substr(spt21.control_date, 4, 4) and step_code = '4' then
                1
               else
                0
             end),
         SUM(case
               when to_char(sysdate, 'yyyyMMdd') >
                    to_number(substr(spt21.control_date, 1, 3)) + 1911 ||
                    substr(spt21.control_date, 4, 4) then
                1
               else
                0
             end)
    INTO S_TO_EXCEED, S_FOR_APPROVE, S_EXCEEDED
    FROM receive
    join spt21
      On receive.receive_no = spt21.receive_no
    LEFT JOIN (SELECT row_number() over(partition by spt21.receive_no order by date_chinese desc) d,
                      spt21.control_date,
                      SPSB36.date_bc,
                      spt21.receive_no
                 FROM spt21
                 join ap.SPSB36
                   on SPSB36.date_bc <
                      to_number(substr(spt21.control_date, 1, 3)) + 1911 ||
                      substr(spt21.control_date, 4, 4)
                 JOIN receive
                   on spt21.receive_no = receive.receive_no
                WHERE SPSB36.date_flag = 1
                  AND receive.processor_no IN
                      (SELECT PROCESSOR_NO
                         FROM SPM63
                        WHERE DEPT_NO = '70012'
                          AND QUIT_DATE IS NULL)) cdate
      on cdate.receive_no = receive.receive_no
   WHERE receive.step_code >= '2'
     AND receive.step_code < '8'
     AND spt21.process_result != '57001'
     AND receive.processor_no IN
         (SELECT PROCESSOR_NO
            FROM SPM63
           WHERE DEPT_NO = '70012'
             AND QUIT_DATE IS NULL)
     AND cdate.d = 2;

  -- 逾期影像未到之線上公文
  select count(1) into S_IMG_NOT_READY
  from (
      SELECT spt21.receive_no,
                    spt21.appl_no,
                    spt21.receive_date,
                    spt21.type_no,
                    spt21.processor_no,
                    spt21.dept_no
            FROM spt21
            join ap.SPSB36
              on SPSB36.date_bc > to_number(substr(spt21.RECEIVE_DATE, 1, 3)) + 1911 ||
                 substr(spt21.RECEIVE_DATE, 4, 4)
           WHERE SPSB36.date_flag = 1
             and spt21.process_result !='57001'
             and SPSB36.date_bc <= to_char(sysdate, 'yyyyMMdd')
             and spt21.online_flg = 'Y'
             and spt21.dept_no = '70012'
             and exists (select 1
                    from receive
                   where receive.receive_no = spt21.receive_no
                     and doc_complete = '0'
                     and is_postpone = '0')
           group by spt21.receive_no,
                    spt21.appl_no,
                    spt21.receive_date,
                    spt21.type_no,
                    spt21.processor_no,
                    spt21.dept_no
          having count(1) > 7 );

  -- 持有者都不是 70012/70014 之線上公文

      select count(1) into S_NOT_SECTION
            from spt21
           where online_flg = 'Y'
             and dept_no not in ('70012', '70014')
             and process_result != '57001'
     ;
end dashboard_section;

/
--------------------------------------------------------
--  DDL for Procedure DISPATCH_RCL_APPLS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."DISPATCH_RCL_APPLS" (P_OUT_MSG out number,p_out_list     out sys_refcursor) 
is
l_rcl_version_no CHAR(6):=null;

/*更新SPM21B*/
PROCEDURE UPDATE_SPM21B
AS
BEGIN
  --刪除公開版IPC
  delete from spm21b
  where ROWID in (
    select spm21b.ROWID
      from spm21b,IPC_TRACE
     where IPC_TRACE.VERSION_NO=l_rcl_version_no
       and spm21b.appl_no=IPC_TRACE.appl_no
       and spm21b.step_code='B'
       and Ipc_Trace.Processor_No='A6119' and IPC_TRACE.NOTICE_STATUS ='7')
    ;
  --刪除公告版IPC
  delete from spm21b
  where ROWID in (
    select spm21b.ROWID
      from spm21b,IPC_TRACE
     where IPC_TRACE.VERSION_NO=l_rcl_version_no
       and spm21b.appl_no=IPC_TRACE.appl_no
       and spm21b.step_code='V'
       and Ipc_Trace.Processor_No='A6119' and IPC_TRACE.NOTICE_STATUS ='8')
    ;
  --更新公開版IPC
  insert into spm21b
  select s.appl_no,'B' step_code,s.DATA_SEQ,s.DATA_SEQ SORT_ID,s.IPC_CODE_MS_NEW IPC_CODE_MS,s.IPC_CODE_DT_NEW IPC_CODE_DT,VERSION_NO_NEW VERSION_NO,s.IPC_REF_TYPE
    from IPC_TRACE_LIST s,IPC_TRACE t
   where s.VERSION_NO=l_rcl_version_no and s.VERSION_NO=t.VERSION_NO
     and s.appl_no=t.appl_no
     and t.Processor_No='A6119' and t.NOTICE_STATUS = '7' /*and s.DEL_FLAG='1'*/
     and t.S_FLAG='0'
     ;
  --更新公告版IPC
  insert into spm21b
  select s.appl_no,'V' step_code,s.DATA_SEQ,s.DATA_SEQ SORT_ID,s.IPC_CODE_MS_NEW IPC_CODE_MS,s.IPC_CODE_DT_NEW IPC_CODE_DT,VERSION_NO_NEW VERSION_NO,s.IPC_REF_TYPE
    from IPC_TRACE_LIST s,IPC_TRACE t
   where s.VERSION_NO=l_rcl_version_no and s.VERSION_NO=t.VERSION_NO
     and s.appl_no=t.appl_no
     and t.Processor_No='A6119' and t.NOTICE_STATUS = '8' /*and s.DEL_FLAG='1'*/
     and t.S_FLAG='0'
     ;      
END;

/*更新SPM21*/
PROCEDURE UPDATE_SPM21
AS
BEGIN
  merge into spm21 d
     using (
        select s.APPL_NO,
               s.DATA_SEQ,
               s.IPC_CODE_MS_NEW,
               s.IPC_CODE_DT_NEW,
               s.VERSION_NO_NEW
          from IPC_TRACE_LIST s,IPC_TRACE t
         where s.VERSION_NO=l_rcl_version_no 
           and s.VERSION_NO=t.VERSION_NO
           and s.appl_no=t.appl_no
           and t.Processor_No='A6119' and t.NOTICE_STATUS in ('7','8')
           and t.S_FLAG='0' and s.DEL_FLAG='1') s
        on ( d.appl_no=s.appl_no and d.DATA_SEQ=s.DATA_SEQ)
  when Matched then
  update set 
       d.IPC_CODE_MS_PRV=s.IPC_CODE_MS_NEW,
       d.IPC_CODE_DT_PRV=s.IPC_CODE_DT_NEW,
       d.VERSION_NO_PRV=s.VERSION_NO_NEW,
       d.IPC_CODE_MS=s.IPC_CODE_MS_NEW,
       d.IPC_CODE_DT=s.IPC_CODE_DT_NEW,
       d.VERSION_NO=s.VERSION_NO_NEW
    ;
END;
/*更新SPM21C*/
PROCEDURE UPDATE_SPM21C
AS
BEGIN
  merge into spm21c d
     using (
        select s.APPL_NO,
               s.DATA_SEQ,
               s.DATA_SEQ SORT_ID,
               s.IPC_CODE_MS_NEW,
               s.IPC_CODE_DT_NEW,
               s.VERSION_NO_NEW
          from IPC_TRACE_LIST s,IPC_TRACE t
         where s.VERSION_NO=l_rcl_version_no 
           and s.VERSION_NO=t.VERSION_NO
           and s.appl_no=t.appl_no
           and t.NOTICE_STATUS='9'
           and t.S_FLAG='1' and s.DEL_FLAG='1') s
        on ( d.appl_no=s.appl_no and d.DATA_SEQ=s.DATA_SEQ)
  when Matched then
  update set 
       d.IPC_CODE_MS=s.IPC_CODE_MS_NEW,
       d.IPC_CODE_DT=s.IPC_CODE_DT_NEW,
       d.VERSION_NO=s.VERSION_NO_NEW
    ;
END;

/*備份IPC*/
PROCEDURE BACKUP_IPC
AS
BEGIN
  delete from tmp_spm21;  --TRUNCATE table tmp_spm21;
  delete from tmp_spm21b; --TRUNCATE table tmp_spm21b;
  delete from tmp_spm21c; --TRUNCATE table tmp_spm21c;
  
  insert into tmp_spm21
  select spm21.*
    from spm21,IPC_TRACE
   where IPC_TRACE.VERSION_NO=l_rcl_version_no
     and spm21.appl_no=IPC_TRACE.appl_no
     ;
  
  insert into tmp_spm21b
  select spm21b.*
    from spm21b,IPC_TRACE
   where IPC_TRACE.VERSION_NO=l_rcl_version_no
     and spm21b.appl_no=IPC_TRACE.appl_no
     --and spm21b.step_code='B'
     ;
  
  
  insert into tmp_spm21c
  select spm21c.*
    from spm21c,IPC_TRACE
   where IPC_TRACE.VERSION_NO=l_rcl_version_no
     and spm21c.appl_no=IPC_TRACE.appl_no
     ;
END;

/*建立回溯清單大項*/
PROCEDURE BUILD_IPC_TRACE
as
begin
  insert into IPC_TRACE
  with spm22_t as ((
      select spm22.IPC_CODE_MS,spm22.IPC_CODE_DT,spm22.VERSION_NO from spm22
      left join rcl_detail on rcl_detail.VERSION_NO=l_rcl_version_no 
                          and spm22.IPC_CODE_MS=rcl_detail.IPC_CODE_MS_PRV 
                          and spm22.IPC_CODE_DT=rcl_detail.IPC_CODE_DT_PRV
      where M_FLAG is not null 
      and spm22.VERSION_NO<l_rcl_version_no
      and rcl_detail.VERSION_NO is null
      and spm22.VERSION_NO is not null
    )union(
      select IPC_CODE_MS_PRV IPC_CODE_MS,IPC_CODE_DT_PRV IPC_CODE_DT,'0' VERSION_NO from rcl_detail
      where VERSION_NO=l_rcl_version_no
      and IPC_CODE_MS_PRV is not null
      and IPC_CODE_DT_PRV is not null
    )
  ),ipc_rcl_appl as( --找尋回溯案件
    select appl_no,ipc_processor_no,FIRST_DEPT_NO,PATENT_CLASS,PRV_FLAG,PHYSICAL_FLAG,NOTICE_STATUS,IPC_TYPE,S_FLAG,M_VERSION_NO from(
      select spt31.appl_no,
             spt31.ipc_processor_no,
             spt31.FIRST_DEPT_NO,
             case when spt31.PATENT_CLASS in ('1','2','4','5','6') then spt31.PATENT_CLASS else null end PATENT_CLASS,
             case when substr(spt31a.step_code,1,1) in ('2','4','6') and spt41.issue_no is null then 1 else 0 end PHYSICAL_FLAG, --實審未發審定書
             case when spt31b.STEP_CODE<='60' and (spt82.NOTICE_NO_2 is null or spt82.NOTICE_NO_2='0'  or spt82.NOTICE_DATE_2>TODAY) then appl_21.PRV_FLAG --待公開
                  when (spt31b.STEP_CODE>='50' or substr(spt31.appl_no,4,1)='2') and (spt82.NOTICE_NO is null or spt82.NOTICE_NO='0' or spt82.NOTICE_DATE>TODAY) then appl_21.PRV_FLAG --待公告
                  when (spt31b.STEP_CODE>='50' and spt82.NOTICE_NO_2 >'0' or substr(spt31.appl_no,4,1)='2') and spt82.NOTICE_NO >'0'  then nvl(appl_21c.PRV_FLAG,appl_21.PRV_FLAG) --已公開已公告
                  else null end PRV_FLAG,
             case when spt31b.STEP_CODE<='60' and (spt82.NOTICE_NO_2 is null or spt82.NOTICE_NO_2='0'  or spt82.NOTICE_DATE_2>TODAY) then '0' --待公開
                  when (spt31b.STEP_CODE>='50' or substr(spt31.appl_no,4,1)='2') and (spt82.NOTICE_NO is null or spt82.NOTICE_NO='0' or spt82.NOTICE_DATE>TODAY) then '1' --待公告
                  when (spt31b.STEP_CODE>='50' and spt82.NOTICE_NO_2 >'0' or substr(spt31.appl_no,4,1)='2') and spt82.NOTICE_NO >'0' then '2' --已公開已公告
                  else null end NOTICE_STATUS,
             case when spm21c.appl_no is not null then substr(spm21c.IPC_CODE_MS,1,1)
                  when spm21.appl_no is not null then substr(spm21.IPC_CODE_MS_PRV,1,1)
                  else null end IPC_TYPE,
             case when appl_21.appl_no is not null and (nvl(NOTICE_NO_2,'0')='0' or nvl(NOTICE_NO,'0')='0' or NOTICE_NO >'0' and (NOTICE_NO_2 >'0' or substr(spt31.appl_no,4,1)='2') and appl_21c.appl_no is null) then '0'
                  when NOTICE_NO >'0' and (NOTICE_NO_2 >'0' or substr(spt31.appl_no,4,1)='2') and appl_21c.appl_no is not null then '1'
                  else null end S_FLAG,
             case when appl_21.appl_no is not null and (nvl(NOTICE_NO_2,'0')='0' or nvl(NOTICE_NO,'0')='0' or NOTICE_NO >'0' and (NOTICE_NO_2 >'0' or substr(spt31.appl_no,4,1)='2') and appl_21c.appl_no is null) then (
                       select max(version_no_prv) from spm21 where appl_no=spt31.appl_no)
                  when NOTICE_NO >'0' and (NOTICE_NO_2 >'0' or substr(spt31.appl_no,4,1)='2') and appl_21c.appl_no is not null then (
                       select max(version_no) from spm21c where appl_no=spt31.appl_no)
                  else null end M_VERSION_NO,
             row_number() over (partition by spt31.appl_no order by spt41.FORM_FILE_A desc) as rn
        from spt31
        left join spt31b on spt31.APPL_NO=spt31b.APPL_NO
        left join spt82 on spt31.APPL_NO=spt82.APPL_NO
        left join (
                select APPL_NO,PRV_FLAG
                from(
                  select APPL_NO,PRV_FLAG ,row_number() over (partition by APPL_NO order by PRV_FLAG) as rn
                  from(
                           select distinct APPL_NO,decode(spm22_t.VERSION_NO,'0',0,1) PRV_FLAG 
                             from spm21c,spm22_t
                            where substr(appl_no,4,1) in ('1','2')
                              and spm21c.IPC_CODE_MS=spm22_t.IPC_CODE_MS 
                              and spm21c.IPC_CODE_DT=spm22_t.IPC_CODE_DT 
                              and (spm22_t.VERSION_NO='0' or spm21c.VERSION_NO=spm22_t.VERSION_NO)
                              and spm21c.VERSION_NO<l_rcl_version_no
                  )
                )where rn=1
             ) appl_21c on spt31.APPL_NO=appl_21c.APPL_NO
        left join (
               select APPL_NO,PRV_FLAG
               from(
                  select APPL_NO,PRV_FLAG ,row_number() over (partition by APPL_NO order by PRV_FLAG) as rn
                  from(
                         select distinct APPL_NO,decode(spm22_t.VERSION_NO,'0',0,1) PRV_FLAG 
                           from spm21,spm22_t
                          where substr(appl_no,4,1) in ('1','2')
                            and (      spm21.IPC_CODE_MS_PRV=spm22_t.IPC_CODE_MS 
                                   and spm21.IPC_CODE_DT_PRV=spm22_t.IPC_CODE_DT 
                                   and (spm22_t.VERSION_NO='0' or spm21.VERSION_NO_PRV=spm22_t.VERSION_NO)
                                   and spm21.VERSION_NO_PRV<l_rcl_version_no
                                or     spm21.IPC_CODE_MS=spm22_t.IPC_CODE_MS 
                                   and spm21.IPC_CODE_DT=spm22_t.IPC_CODE_DT 
                                   and (spm22_t.VERSION_NO='0' or spm21.VERSION_NO=spm22_t.VERSION_NO)
                                   and spm21.VERSION_NO<l_rcl_version_no)
                  )
               )where rn=1      
             ) appl_21 on spt31.APPL_NO=appl_21.APPL_NO
        left join spm21c on spt31.appl_no=spm21c.appl_no and spm21c.DATA_SEQ='1'
        left join spm21 on spt31.appl_no=spm21.appl_no and spm21.DATA_SEQ='1'
        left join spt31a on spt31.appl_no=spt31a.APPL_NO 
        left join spt41 on spt31a.APPL_NO=spt41.APPL_NO and spt41.process_result in ('56001','56003','56097') and (trim(spt41.file_d_flag) is null  or spt41.file_d_flag<>'9') /*已發審定書*/
        left join (select TO_CHAR(TO_NUMBER(TO_CHAR(sysdate, 'YYYYMMDD')) - 19110000) TODAY from dual) on 1=1
      where (spt31b.STEP_CODE>='30' and spt31b.STEP_CODE<='60' or substr(spt31.appl_no,4,1)='2' and spt31a.step_code >='15' and spt31a.step_code<'70')
        and (appl_21.appl_no is not null and (nvl(NOTICE_NO_2,'0')='0' or nvl(NOTICE_NO,'0')='0' or NOTICE_NO >'0' and (NOTICE_NO_2 >'0' or substr(spt31.appl_no,4,1)='2') and appl_21c.appl_no is null) 
             or NOTICE_NO >'0' and (NOTICE_NO_2 >'0' or substr(spt31.appl_no,4,1)='2') and appl_21c.appl_no is not null)
        and spt31.BACK_CODE is null and spt31.sc_flag='0' and spt31.PUBLIC_FLAG is null
      )where rn=1 
  ), tmp_appl as( --找尋1-1回溯案件
    select appl_no
    from(
      select APPL_NO,M_VERSION_NO
             ,count(case when IPC_CODE_MS_NEW is not null then 1 else null end) m_count
             ,count(case when IPC_CODE_MS_NEW is null and M_FLAG is not null then 1 else null end) d_count
      from (
        select 
        a.APPL_NO,
        a.M_VERSION_NO,
        decode(a.s_flag,'1',spm21c.DATA_SEQ,spm21.DATA_SEQ) DATA_SEQ_PRV,
        decode(a.s_flag,'1',spm21c.IPC_CODE_MS,spm21.IPC_CODE_MS_PRV) IPC_CODE_MS_PRV,
        decode(a.s_flag,'1',spm21c.IPC_CODE_DT,spm21.IPC_CODE_DT_PRV) IPC_CODE_DT_PRV,
        decode(a.s_flag,'1',spm21c.VERSION_NO,spm21.VERSION_NO_PRV) VERSION_NO_PRV,
        rcl_detail.IPC_CODE_MS_NEW,
        spm22.M_FLAG
        from ipc_rcl_appl a
        left join spm21c on a.appl_no=spm21c.appl_no and a.s_flag='1'
        left join spm21 on a.appl_no=spm21.appl_no and a.s_flag='0'
        left join rcl_detail on rcl_detail.VERSION_NO=l_rcl_version_no and (spm21c.IPC_CODE_MS=rcl_detail.IPC_CODE_MS_PRV 
                                and spm21c.IPC_CODE_DT=rcl_detail.IPC_CODE_DT_PRV 
                                and spm21c.VERSION_NO<l_rcl_version_no 
                                or
                                spm21.IPC_CODE_MS_PRV=rcl_detail.IPC_CODE_MS_PRV 
                                and spm21.IPC_CODE_DT_PRV=rcl_detail.IPC_CODE_DT_PRV 
                                and spm21.VERSION_NO_PRV<l_rcl_version_no)
        left join spm22 on spm22.M_FLAG is not null and (spm21c.IPC_CODE_MS=spm22.IPC_CODE_MS
                                and spm21c.IPC_CODE_DT=spm22.IPC_CODE_DT 
                                and spm21c.VERSION_NO=spm22.VERSION_NO
                                or
                                spm21.IPC_CODE_MS_PRV=spm22.IPC_CODE_MS
                                and spm21.IPC_CODE_DT_PRV=spm22.IPC_CODE_DT
                                and spm21.VERSION_NO_PRV=spm22.VERSION_NO)
        where (spm21c.appl_no is not null or spm21.appl_no is not null)
      )
      group by APPL_NO,M_VERSION_NO,DATA_SEQ_PRV,IPC_CODE_MS_PRV,IPC_CODE_DT_PRV,VERSION_NO_PRV
    )group by APPL_NO,M_VERSION_NO having sum(d_count)=0 
                                      and count(case when m_count =1 then 1 else null end) =count(case when m_count >0 then 1 else null end) 
                                      and (M_VERSION_NO>'07' or count(case when m_count =1 then 1 else null end)=count(*))
  ),person_skills as ( --承辦人專長
    select processor_no,skill,row_number() over (partition by skill order by dbms_random.random) as rn
    from((
      select authority.processor_no,'0' skill
      from authority,spm63 
      where  BITAND(skills,1) >0 and substr(group_id,2,1)='B'
      and authority.processor_no=spm63.processor_no and substr(authority.processor_no,1,1)<>'P'
      and spm63.DEPT_NO='70014' and spm63.QUIT_DATE is null
    )union(
      select authority.processor_no,'1' skill
      from authority,spm63 
      where  BITAND(skills,1) >0 and nvl(substr(group_id,2,1),'A')='A'
      and authority.processor_no=spm63.processor_no and substr(authority.processor_no,1,1)<>'P'
      and spm63.DEPT_NO='70014' and spm63.QUIT_DATE is null
    )union(
      select authority.processor_no,'2' skill
      from authority,spm63 
      where  BITAND(skills,2) >0
      and authority.processor_no=spm63.processor_no and substr(authority.processor_no,1,1)<>'P'
      and spm63.DEPT_NO='70014' and spm63.QUIT_DATE is null
    )union(
      select authority.processor_no,'3' skill
      from authority,spm63 
      where  BITAND(skills,4) >0
      and authority.processor_no=spm63.processor_no and substr(authority.processor_no,1,1)<>'P'
      and spm63.DEPT_NO='70014' and spm63.QUIT_DATE is null
    )union(
      select authority.processor_no,'4' skill
      from authority,spm63 
      where  BITAND(skills,8) >0
      and authority.processor_no=spm63.processor_no and substr(authority.processor_no,1,1)<>'P'
      and spm63.DEPT_NO='70014' and spm63.QUIT_DATE is null
    )union(
      select authority.processor_no,'5' skill
      from authority,spm63 
      where  BITAND(skills,16) >0
      and authority.processor_no=spm63.processor_no and substr(authority.processor_no,1,1)<>'P'
      and spm63.DEPT_NO='70014' and spm63.QUIT_DATE is null
    )union(
      select authority.processor_no,'6' skill
      from authority,spm63 
      where  BITAND(skills,32) >0
      and authority.processor_no=spm63.processor_no and substr(authority.processor_no,1,1)<>'P'
      and spm63.DEPT_NO='70014' and spm63.QUIT_DATE is null
    )union(
      select '70014' processor_no,'*' skill from dual
    ))    
  )
  (   --待公開、待公告、外包已公開已公告、實審未核發審定書
      select a.APPL_NO,
      l_rcl_version_no VERSION_NO,
      nvl(spm63.processor_no,'70014') PROCESSOR_NO,
      sysdate ASSIGN_DATE,
      null COMPLETE_DATE,
      a.PATENT_CLASS,
      case when a.physical_flag=0 or a.NOTICE_STATUS in ('2') then to_char(a.NOTICE_STATUS+a.PRV_FLAG*4) else to_char(a.NOTICE_STATUS+7) end NOTICE_STATUS,
      a.IPC_TYPE,
      a.S_FLAG
      from ipc_rcl_appl a
      left join tmp_appl on a.appl_no=tmp_appl.appl_no
      left join spm63 on a.ipc_processor_no=spm63.processor_no and dept_no='70014' and spm63.quit_date is null
      where tmp_appl.appl_no is null and (a.NOTICE_STATUS in ('0','1') or a.NOTICE_STATUS in ('2') and spm63.processor_no like 'P%')
  )union( --已公開 已公告(不含外包)
      select a.APPL_NO,
      l_rcl_version_no VERSION_NO,
      nvl(b.processor_no,'70014') PROCESSOR_NO,
      sysdate ASSIGN_DATE,
      null COMPLETE_DATE,
      a.PATENT_CLASS,
      to_char(a.NOTICE_STATUS+a.PRV_FLAG*4) NOTICE_STATUS,
      a.IPC_TYPE,
      a.S_FLAG
      from (
        select x.*, row_number() over (partition by skill order by dbms_random.random) as rn from (
          select y.* , 
                 case when PATENT_CLASS='1' and FIRST_DEPT_NO ='70025' then '0'
                      when PATENT_CLASS='1' then '1' --FIRST_DEPT_NO ='70026'
                      when PATENT_CLASS>='2' and PATENT_CLASS<='6' then PATENT_CLASS
                      else null end skill
            from 
                (select ipc_rcl_appl.APPL_NO,ipc_rcl_appl.PATENT_CLASS,ipc_rcl_appl.FIRST_DEPT_NO,
                   ipc_rcl_appl.NOTICE_STATUS,ipc_rcl_appl.PRV_FLAG,
                   ipc_rcl_appl.IPC_TYPE,
                   ipc_rcl_appl.S_FLAG
                   from ipc_rcl_appl
                   left join tmp_appl on ipc_rcl_appl.appl_no=tmp_appl.appl_no
                   left join spm63 on ipc_rcl_appl.ipc_processor_no like 'P%' and ipc_rcl_appl.ipc_processor_no=spm63.processor_no and dept_no='70014' and spm63.quit_date is null
                   where tmp_appl.appl_no is null and ipc_rcl_appl.NOTICE_STATUS in ('2') and spm63.processor_no is null) y
        ) x
      )a
      left join (select skill,count(*) max_cnt from person_skills group by skill) c on nvl(a.skill,'*')=c.skill
      left join person_skills b on nvl(a.skill,'*')=b.skill
      left join tmp_appl on a.appl_no=tmp_appl.appl_no
      where mod(a.rn,c.max_cnt)+1 = b.rn and tmp_appl.appl_no is null
  )union(
      select a.APPL_NO,
      l_rcl_version_no VERSION_NO,
      'A6119' PROCESSOR_NO,
      sysdate ASSIGN_DATE,
      null COMPLETE_DATE,
      a.PATENT_CLASS,
      to_char(a.NOTICE_STATUS+7) NOTICE_STATUS,
      a.IPC_TYPE,
      a.S_FLAG
      from ipc_rcl_appl a,tmp_appl 
      where a.appl_no=tmp_appl.appl_no
  )
  ;
end;

/*建立回溯清單細項*/
PROCEDURE BUILD_IPC_TRCE_LIST
as
BEGIN
  insert into IPC_TRACE_LIST 
  select IPC_TRACE_LIST_ID_SEQ.nextval ID,
        l_rcl_version_no VERSION_NO,
        a.APPL_NO,
        case when a.s_flag ='1' then spm21c.DATA_SEQ else spm21.DATA_SEQ end DATA_SEQ,
        null SOIRT_ID,
        decode(a.s_flag,'1',spm21c.IPC_CODE_MS,spm21.IPC_CODE_MS_PRV) IPC_CODE_MS_PRV,
        decode(a.s_flag,'1',spm21c.IPC_CODE_DT,spm21.IPC_CODE_DT_PRV) IPC_CODE_DT_PRV,
        decode(a.s_flag,'1',spm21c.VERSION_NO,spm21.VERSION_NO_PRV) VERSION_NO_PRV,
        nvl(rcl_detail.IPC_CODE_MS_NEW,decode(a.s_flag,'1',spm21c.IPC_CODE_MS,spm21.IPC_CODE_MS_PRV)) IPC_CODE_MS_NEW,
        nvl(rcl_detail.IPC_CODE_DT_NEW,decode(a.s_flag,'1',spm21c.IPC_CODE_DT,spm21.IPC_CODE_DT_PRV)) IPC_CODE_DT_NEW,
        case when rcl_detail.attribute_new='t' then (
                  select max(spm22.version_no)
                    from spm22 
                   where spm22.IPC_CODE_MS=rcl_detail.IPC_CODE_MS_NEW
                     and spm22.IPC_CODE_DT=rcl_detail.IPC_CODE_DT_NEW
                     and spm22.VERSION_NO<l_rcl_version_no
                     and spm22.M_FLAG is null
                  )
             when rcl_detail.attribute_new is null then decode(a.s_flag,'1',spm21c.VERSION_NO,spm21.VERSION_NO_PRV)
             else to_char(l_rcl_version_no) end  VERSION_NO_NEW,
        decode(a.s_flag,'1',spm21c.IPC_REF_TYPE,spm21.IPC_REF_TYPE) IPC_REF_TYPE,
        case when a.processor_no='A6119' then '1'
             when rcl_detail.attribute_new is null then '0'
             else '2' end DEL_FLAG
    from IPC_TRACE a
    left join spm21c on a.appl_no=spm21c.appl_no and a.S_FLAG='1'
    left join spm21 on a.appl_no=spm21.appl_no and a.S_FLAG='0'
    left join RCL_DETAIL on RCL_DETAIL.VERSION_NO=l_rcl_version_no and 
                            (RCL_DETAIL.IPC_CODE_MS_PRV=spm21.IPC_CODE_MS_PRV and RCL_DETAIL.IPC_CODE_DT_PRV=spm21.IPC_CODE_DT_PRV
                             or RCL_DETAIL.IPC_CODE_MS_PRV=spm21c.IPC_CODE_MS and RCL_DETAIL.IPC_CODE_DT_PRV=spm21c.IPC_CODE_DT)
  where (spm21c.appl_no is not null or spm21.appl_no is not null) and a.VERSION_NO=l_rcl_version_no
  ;
end;


/*初始化*/
PROCEDURE INIT
AS
BEGIN
  delete from IPC_TRACE where version_no=l_rcl_version_no;
  delete from IPC_TRACE_LIST where version_no=l_rcl_version_no;
END;

begin
  P_OUT_MSG:=0;
  
  --選取 RCL 版本
  select min(version_no) into l_rcl_version_no
  from rcl_ver 
  where COMPLETE_DATE is null 
  and START_DATE is not null;
  
  begin
    --找到RCL版本
    if l_rcl_version_no > '07' then
      INIT;
      BUILD_IPC_TRACE;      --建立回溯清單大項
      BUILD_IPC_TRCE_LIST;  --建立回溯清單細項
      BACKUP_IPC;           --備份IPC
      UPDATE_SPM21B;        --更新SPM21B
      UPDATE_SPM21;         --更新SPM21
      UPDATE_SPM21C;        --更新SPM21C
      
      --更新COMPLETE_DATE
      update rcl_ver set COMPLETE_DATE=sysdate where version_no=l_rcl_version_no and COMPLETE_DATE is null and START_DATE is not null;
      
      select count(*) into P_OUT_MSG
	    from IPC_TRACE
	    where VERSION_NO=l_rcl_version_no
	    and NOTICE_STATUS < '7'
	    ;
      
    end if;
  exception
    WHEN OTHERS THEN
      P_OUT_MSG:=0;
      --RESET_ALL;
  end;
  
  open p_out_list for
  select a.appl_no, a.processor_No, b.patent_Name_C,
         TO_CHAR(TO_NUMBER(TO_CHAR(a.complete_date, 'YYYYMMDD')) - 19110000) complete_date,
			   b. APPL_DATE  
	from IPC_TRACE a, spt31 b
	where a.VERSION_NO=l_rcl_version_no
	and a.NOTICE_STATUS <'7'
  and a.appl_no=b.appl_no	
  ;
  
end DISPATCH_RCL_APPLS;

/
--------------------------------------------------------
--  DDL for Procedure ERROR_REPORT_CHANGE_STATUS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."ERROR_REPORT_CHANGE_STATUS" (p_in_id     in varchar2,
                                                       p_in_status in varchar2) is
  --更新狀態
begin
  UPDATE ERROR_REPORTING
     SET STATUS = p_in_status, STATUS_DATE = SYSDATE
   WHERE ID = p_in_id;
end error_report_change_status;

/
--------------------------------------------------------
--  DDL for Procedure ERROR_REPORT_LIST
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."ERROR_REPORT_LIST" (p_in_processor_no in char,
                                              p_in_last         in varchar2,
                                              p_out_list        out sys_refcursor) is
  --錯誤通報清單
begin
  --  科及個人
  open p_out_list for
    SELECT RAWTOHEX(A.ID) AS ID,
           A.RECEIVE_NO,
           A.PROCESSOR_NO,
           A.STATUS,
           A.APPL_NO,
           A.MESSAGE,
           B.NAME_C,
           EXTRACT(YEAR FROM A.REPORT_DATE) - 1911 ||
           TO_CHAR(A.REPORT_DATE, 'MMDD HH24:MI') AS REPORT_DATE,
           EXTRACT(YEAR FROM A.STATUS_DATE) - 1911 ||
           TO_CHAR(A.STATUS_DATE, 'MMDD HH24:MI') AS STATUS_DATE
      FROM ERROR_REPORTING A, SPM63 B
     WHERE A.PROCESSOR_NO = B.PROCESSOR_NO
       AND A.PROCESSOR_NO = NVL(p_in_processor_no, A.PROCESSOR_NO)
       AND A.STATUS_DATE > SYSDATE - p_in_last
     ORDER BY A.REPORT_DATE DESC;

end error_report_list;

/
--------------------------------------------------------
--  DDL for Procedure ERROR_REPORT_LIST_APPROVER
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."ERROR_REPORT_LIST_APPROVER" (p_in_last  in varchar2,
                                                       p_out_list out sys_refcursor) is
  --錯誤通報清單
begin
  -- 查驗人員
  open p_out_list for
    SELECT RAWTOHEX(A.ID) AS ID,
           A.RECEIVE_NO,
           A.PROCESSOR_NO,
           A.STATUS,
           A.APPL_NO,
           A.MESSAGE,
           B.NAME_C,
           EXTRACT(YEAR FROM A.REPORT_DATE) - 1911 ||
           TO_CHAR(A.REPORT_DATE, 'MMDD HH24:MI') AS REPORT_DATE,
           EXTRACT(YEAR FROM A.STATUS_DATE) - 1911 ||
           TO_CHAR(A.STATUS_DATE, 'MMDD HH24:MI') AS STATUS_DATE
      FROM ERROR_REPORTING A, SPM63 B
     WHERE A.PROCESSOR_NO = B.PROCESSOR_NO
       AND SUBSTR(A.PROCESSOR_NO, 1, 1) = 'P'
       AND A.STATUS_DATE > SYSDATE - p_in_last
     ORDER BY A.REPORT_DATE DESC;

end error_report_list_approver;

/
--------------------------------------------------------
--  DDL for Procedure ERROR_REPORT_REDO
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."ERROR_REPORT_REDO" (p_in_id      in varchar2,
                                              p_in_message in varchar2) is
  --再通報
begin
  UPDATE ERROR_REPORTING
     SET STATUS = 0, REPORT_DATE = SYSDATE, MESSAGE = p_in_message
   WHERE ID = p_in_id;
end error_report_redo;

/
--------------------------------------------------------
--  DDL for Procedure ERROR_REPORT_SAVE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."ERROR_REPORT_SAVE" (p_in_processor_no in char,
                                              p_in_receive_no   in char,
                                              p_in_appl_no      in varchar2,
                                              p_in_message      in varchar2) is
  --通報
begin

  delete error_reporting
   where receive_no = p_in_receive_no
     and processor_no = p_in_processor_no
     and status = 0;

  INSERT INTO ERROR_REPORTING
    (RECEIVE_NO, PROCESSOR_NO, APPL_NO, MESSAGE)
  VALUES
    (p_in_receive_no, p_in_processor_no, p_in_appl_no, p_in_message);

end error_report_save;

/
--------------------------------------------------------
--  DDL for Procedure GET_ANNEX
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."GET_ANNEX" (
  p_in_appl_no in char, 
  p_in_online_flg in char, 
  p_out_annex_code out char, 
  p_out_annex_desc out char)
is
begin
  if p_in_online_flg = 'Y' then
    begin
      select pre_exam_list
        into p_out_annex_code
        from appl
       where appl_no = p_in_appl_no;
    exception
      when no_data_found then null;
    end;
    begin
      select annex_desc
        into p_out_annex_desc
        from appl50
       where appl_no = p_in_appl_no
         and series_no = '38';
    exception
      when no_data_found then null;
    end;
  else
    begin
      select annex_code
        into p_out_annex_code
        from spt50a
       where appl_no = p_in_appl_no;
    exception
      when no_data_found then null;
    end;
    begin
      select annex_desc
        into p_out_annex_desc
        from spt50
       where appl_no = p_in_appl_no
         and series_no = '38';
    exception
      when no_data_found then null;
    end;
  end if;
end get_annex;

/
--------------------------------------------------------
--  DDL for Procedure GET_BATCH
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."GET_BATCH" (checkdate in varchar2,
                                        is_fix    in char,
                                        p_rec     out int
                                         ) IS
  /*
  DESC: 產生外包批次資料,只處理線上公文
  PARAMETER: checkdate : 送核日期
             s_fix: 是否凍結 ; (0: 白天批次執行,每小時加入公文到批次中; 1: 晚上執行最後一次批次新增; 之後,不再增加公文)
  ModifyDate : 104/07/08
  104/07/23: change return record parameter 
  */

  CURSOR BATCH_CUR IS
    SELECT distinct d02.create_date  || '-' || s21.processor_no , s21.processor_no, s21.receive_no ,s21.appl_no
      FROM spm56 s56
      JOIN receive s21
        on s56.appl_no = s21.appl_no
       and s56.receive_no = s21.receive_no  and s56.processor_no = s21.processor_no
       JOIN (
      select d02.form_file_a, d03.create_date 
      from ap.sptd02  d02
      join ap.sptd03 d03 on  d02.form_file_a = d03.form_file_a and d02.node_no = d03.node_no
      where  d02.flow_step ='02'
      ) d02 on d02.form_file_a = s56.form_file_a
     WHERE s21.processor_no  between 'P2121' and 'P2124'
       and s56.ISSUE_FLAG = '1'
       AND d02.create_date  = checkdate
        and s56.receive_no not in (select bd2.receive_no from batch_detail bd2  join batch b2 on b2.batch_seq = bd2.batch_seq and b2.batch_no = bd2.batch_no
         and bd2.is_rejected = '0'
         and b2.step_code <='3'
         and b2.batch_seq = (select max(batch_seq) from batch where batch_no = b2.batch_no)
         )
       ;

  l_batch_date      varchar2(10);
  l_batch_processor varchar2(10);
  l_receive_no      varchar2(15);
  l_appl_no         varchar2(15);
  l_step_code       char;
  l_batch_no        varchar2(50);
  l_cnt1            number;

  l_urec            integer;
BEGIN
 l_cnt1 := 0;
 l_urec := 0;
 p_rec  := 0;
  OPEN BATCH_CUR;
    LOOP
      FETCH BATCH_CUR
        INTO l_batch_no, l_batch_processor,l_receive_no,l_appl_no;
      EXIT WHEN BATCH_CUR%NOTFOUND;
      
   --   l_cnt1 := l_cnt1 + 1;
       dbms_output.put_line( l_cnt1 || ':l_batch_no:' || l_batch_no || ';receive_no =' || l_receive_no);
  -------------------------
  -- Insert Batch
  -------------------------
    INSERT INTO batch
    (batch_seq, batch_no, outsourcing, step_code,process_date)
    select '1',l_batch_no ,
                  l_batch_processor,
                    '0', -- 未凍結
                   substr(l_batch_no,1,7)
      FROM dual
      LEFT JOIN BATCH
        on BATCH.Batch_No = l_batch_no
     WHERE Batch.Batch_No is null;
     --  l_urec :=  SQL%RowCount;
       
             
       update receive
       set step_code = '4' --陳核中
       where receive_no = l_receive_no
       and not exists
       (select 1 FROM BATCH_DETAIL bd
         WHERE  bd.batch_no = l_batch_no
          AND bd.receive_no = l_receive_no
          )
        and exists ( select 1 from batch where Batch_No = l_batch_no and step_code = '0')
        ;
     --   l_urec := l_urec +  SQL%RowCount;
          dbms_output.put_line('update record:' || l_urec);
          
           select count(1) into l_urec
        FROM dual
       WHERE  not exists (select 1 from   BATCH_DETAIL bd
                 where bd.Batch_No = l_batch_no and bd.receive_no = l_receive_no)
        and exists ( select 1 from batch where Batch_No = l_batch_no and step_code = '0')
     ;
     p_rec := p_rec + l_urec;
        
     INSERT INTO batch_detail
      SELECT distinct 1,
                    l_batch_no,
                    l_receive_no,
                    l_appl_no,
                    '0',
                    '0',
                    null,
                    '0'
      FROM dual
    WHERE  not exists (select 1 from   BATCH_DETAIL bd
        where bd.Batch_No = l_batch_no and bd.receive_no = l_receive_no)
     ;
     
    --  l_urec := l_urec +  SQL%RowCount;
        dbms_output.put_line('update + insert record:' || l_urec);
  ----------------------------------------------------------
  -- Fix records , no more record can be added to batch
  ----------------------------------------------------------
    
  END LOOP;
  CLOSE BATCH_CUR;
    COMMIT;
  
   
      IF is_fix = '1' THEN
         UPDATE batch
         SET STEP_CODE = '1', PROCESS_DATE = checkdate, approver= (select max(checker) from ap.spm72 where dept_no = '70012' and processor_no = batch.outsourcing)
          WHERE substr(batch_no,1,7) = checkdate; 
         --  p_rec := p_rec + SQL%RowCount;
       END IF;
   p_rec := nvl(p_rec,0);
  dbms_output.put_line('Finish total record:' || p_rec);
--EXCEPTION
--  WHEN OTHERS THEN
  
  --  dbms_output.put_line('Error Code:' || SQLCODE || ' : ' || SQLERRM);
END GET_Batch;

/
--------------------------------------------------------
--  DDL for Procedure GET_BATCH_DAY
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."GET_BATCH_DAY" (p_rec  out int
                                         ) IS
  /*
  產生外包批次資料,只處理線上公文-送核日期前一日的所有公文
  參數: checkdate : 送核日期
       is_fix: 是否凍結 ; (0: 白天批次執行,每小時加入公文到批次中; 1: 晚上執行最後一次批次新增; 之後,不再增加公文)
  
  */
BEGIN

  GET_Batch(to_char(to_number(to_char(sysdate-1,'yyyyMMdd'))-19110000),'1',p_rec);

EXCEPTION
  WHEN OTHERS THEN
  
    dbms_output.put_line('Error Code:' || SQLCODE || ' : ' || SQLERRM);
END GET_Batch_DAY;

/
--------------------------------------------------------
--  DDL for Procedure GET_BATCH_HR
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."GET_BATCH_HR" (p_rec  out int
                                         ) IS
  /*
  產生外包批次資料,只處理線上公文
  參數: checkdate : 送核日期
       is_fix: 是否凍結 ; (0: 白天批次執行,每小時加入公文到批次中; 1: 晚上執行最後一次批次新增; 之後,不再增加公文)
  
  */
BEGIN
  GET_Batch(to_char(to_number(to_char(sysdate,'yyyyMMdd'))-19110000),'0',p_rec);
  dbms_output.put_line('Finish total record:' || p_rec);
  
   /*-------------------------------------
     check batch status by form status
    
    --------------------------------------*/
    update batch 
    set step_code = '3'
    where batch_no in 
    (
        select batch.batch_no
        from batch_detail 
        join batch on batch.batch_no = batch_detail.batch_no and batch.batch_seq = batch_detail.batch_seq
        join spm56 on spm56.receive_no = batch_detail.receive_no 
        join ap.sptd02 sd02 on sd02.form_file_a = spm56.form_file_a
        where batch.batch_seq  = (select max(batch_seq) from batch where batch_no = batch_detail.batch_no)
        and batch.step_code = '1'
        and batch.process_result = '1' -- pass
        and is_rejected='0'
        and spm56.form_file_a = (select max(form_file_a) from spm56 s56 where s56.receive_no = spm56.receive_no and s56.issue_flag = '1')
        group by batch.batch_no
        having  sum(case when sd02.flow_step != '04' then 1 else 0 end )=0
        )
        ;
         p_rec := p_rec +  SQL%RowCount;
        dbms_output.put_line('batch pass record:' || SQL%RowCount);

        update batch 
        set step_code = '2'
        where batch_no in 
        (
          select batch.batch_no
          from batch_detail 
          join batch on batch.batch_no = batch_detail.batch_no and batch.batch_seq = batch_detail.batch_seq
          join spm56 on spm56.receive_no = batch_detail.receive_no 
          join ap.sptd02 sd02 on sd02.form_file_a = spm56.form_file_a
          where batch.batch_seq  = (select max(batch_seq) from batch where batch_no = batch_detail.batch_no)
          and batch.step_code = '1'
          and batch.process_result in ('2','3') -- fail
          and is_rejected='0'
          and spm56.form_file_a = (select max(form_file_a) from spm56 s56 where s56.receive_no = spm56.receive_no and s56.issue_flag = '1')
          group by batch.batch_no
          having sum(case when sd02.flow_step != '01' then 1 else 0 end )=0 --
        )
        ;
        dbms_output.put_line('batch fail record:' || SQL%RowCount);
       p_rec := p_rec +  SQL%RowCount;
        commit;

EXCEPTION
  WHEN OTHERS THEN
  
    dbms_output.put_line('Error Code:' || SQLCODE || ' : ' || SQLERRM);
END GET_Batch_HR;

/
--------------------------------------------------------
--  DDL for Procedure GET_DIRECT_PAGE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."GET_DIRECT_PAGE" (
  p_in_appl_no in spt31.appl_no%type,
  p_in_processor_no in char,
  p_out_direct_info_map out pair_tab,
  p_out_priority_right_array out priority_right_tab,
  p_out_biomaterial_array out biomaterial_tab,
  p_out_grace_period_array out grace_period_tab,
  p_out_message_array out varchar2_tab,
  p_out_readonly_message out varchar2,
  p_out_success out varchar2)
is

  --常數
  c_yes         constant char(1) := '1';
  c_no          constant char(1) := '0';
  
  procedure add_direct_info_map(p_key in varchar2, p_value in varchar2, p_auto_trim in boolean default true)
  is
  begin
    p_out_direct_info_map.extend;
    if p_auto_trim then
      p_out_direct_info_map(p_out_direct_info_map.last) := pair_obj(p_key, trim(p_value));
    else
      p_out_direct_info_map(p_out_direct_info_map.last) := pair_obj(p_key, p_value);
    end if;
  end add_direct_info_map;
  
  procedure add_message(p_message in varchar2)
  is
  begin
    p_out_message_array.extend;
    p_out_message_array(p_out_message_array.last) := p_message;
  end add_message;
  
  procedure check_readonly
  is
  begin
    if check_appl_processor(p_in_appl_no, p_in_processor_no) = 0 then
      p_out_readonly_message := '非案件或公文承辦人,不能辦理';
      return;
    end if;
  end check_readonly;
begin
  p_out_direct_info_map := pair_tab();
  p_out_message_array := varchar2_tab();
  p_out_success := 'Y';

  declare
    v_appl_no            spt31.appl_no%type;
    v_appl_date          spt31.appl_date%type;
    v_patent_name_c      spt31.patent_name_c%type;
    v_foreign_language   spt31.foreign_language%type;
    v_twis_flag          spt31.twis_flag%type;
    v_material_appl_date spt31.material_appl_date%type;
    v_name_c             spm63.name_c%type;
  begin
    select a.appl_no, a.appl_date, a.patent_name_c, a.foreign_language, a.twis_flag, a.material_appl_date, b.name_c
      into v_appl_no, v_appl_date, v_patent_name_c, v_foreign_language, v_twis_flag, v_material_appl_date, v_name_c
      from spt31 a, spm63 b
     where a.appl_no = p_in_appl_no
       and a.sch_processor_no = b.processor_no(+);
    add_direct_info_map('APPL_NO', v_appl_no);
    add_direct_info_map('APPL_DATE', v_appl_date);
    add_direct_info_map('PATENT_NAME_C', v_patent_name_c);
    add_direct_info_map('FOREIGN_LANGUAGE', v_foreign_language);
    add_direct_info_map('TWIS_FLAG', v_twis_flag);
    add_direct_info_map('MATERIAL_APPL_DATE', v_material_appl_date);
    add_direct_info_map('NAME_C', v_name_c);
  exception
    when no_data_found then
      p_out_success := 'N';
      add_message('無原案件資料(SPT31)，請查明之');
  end;
  
  declare
    v_material_code spt31b.material_code%type;
    v_priority_code spt31b.priority_code%type;
  begin
    select a.material_code, a.priority_code 
      into v_material_code, v_priority_code
      from spt31b a
     where appl_no = p_in_appl_no;
    if v_material_code = '10' and nvl(v_priority_code, '_') <> '10'then
      add_direct_info_map('APPL_EXAM_FLAG', c_yes);
    end if;
    if v_priority_code = '10' then
	    add_direct_info_map('APPL_PRIORITY_EXAM_FLAG', c_yes);
    end if;
  exception
    when no_data_found then null;
  end;

  declare
    v_annex_code appl.pre_exam_list%type;
    v_annex_desc appl50.annex_desc%type;
  begin
    get_annex(p_in_appl_no, 'Y', v_annex_code, v_annex_desc);
    add_direct_info_map('ANNEX_CODE', v_annex_code);
    add_direct_info_map('ANNEX_DESC', v_annex_desc);
  end;
  
  declare
    v_spt21c_receive_no varchar2(15 char);
  begin
    select decode(type, '1', receive_no, '人工整檔')
      into v_spt21c_receive_no
      from spt21c
     where appl_no = p_in_appl_no;
    add_direct_info_map('SPT21C_RECEIVE_NO', v_spt21c_receive_no);
  exception
    when no_data_found then null;
  end;
  
  select priority_right_obj(
           appl_no,           priority_flag,
           data_seq,          priority_date,
           priority_appl_no,  priority_nation_id,
           priority_doc_flag, priority_revive,
           access_code,       ip_type,
           null
         )
    bulk collect
    into p_out_priority_right_array
    from spt32
   where appl_no = p_in_appl_no;

  if p_out_priority_right_array.count > 0 then
    declare
      function get_response_status(p_appl_no in varchar2, p_access_code in varchar2)
      return varchar2
      is
        v_response_status spt32_rq.response_status%type;
      begin
        select response_status
          into v_response_status
          from (
            select response_status
              from spt32_rq
             where trim(ref_doc_number) = trim(p_appl_no)
               and access_code = nvl(p_access_code, access_code)
             order by ack_id desc)
         where rownum = 1;
        return v_response_status;
      exception
        when no_data_found then return null;--不處理
      end;
    begin
      for l_idx in p_out_priority_right_array.first .. p_out_priority_right_array.last
      loop
        p_out_priority_right_array(l_idx).response_status
          := get_response_status(p_in_appl_no, p_out_priority_right_array(l_idx).access_code);
      end loop;
    end;
  end if;
  
  if substr(p_in_appl_no, 4, 1) not in ('2', '3') then
    select biomaterial_obj(
             appl_no,         data_seq,    microbe_date,     microbe_org_id,
             microbe_appl_no, national_id, microbe_org_name
           )
      bulk collect
      into p_out_biomaterial_array
      from spt33
     where appl_no = p_in_appl_no
     order by data_seq;
  end if;
  
  select grace_period_obj(
           appl_no, data_seq, novel_flag, novel_item, novel_date, sort_id
         )
    bulk collect
    into p_out_grace_period_array
    from spt31l
   where appl_no = p_in_appl_no
   order by sort_id;
  
  if p_out_success = 'Y' then
    check_readonly;
  end if;
  
end get_direct_page;

/
--------------------------------------------------------
--  DDL for Procedure GET_PROCCESS_PAGE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."GET_PROCCESS_PAGE" (
  p_in_receive_no in spt21.receive_no%type,
  p_in_processor_no in spt21.processor_no%type,
  p_out_proccess_info out proccess_info_obj,
  p_out_priority_right_array out priority_right_tab,
  p_out_biomaterial_array out biomaterial_tab,
  p_out_grace_period_array out grace_period_tab,
  p_out_request_item_array out varchar2_tab,
  p_out_message_array out varchar2_tab,
  p_out_readonly_message out varchar2,
  p_out_success out varchar2)
is
  --常數
  c_yes         constant char(1) := '1';
  c_no          constant char(1) := '0';
  c_tw_sysdate  constant char(7) := to_char(sysdate, 'yyyymmdd') - 19110000;

  --spt21 收文資料
  v_appl_no                 spt21.appl_no%type;            --申請案號
  v_receive_no              spt21.receive_no%type;         --收文文號
  v_type_no                 spt21.type_no%type;            --收文案由
  v_assign_date             spt21.assign_date%type;        --分辦日期
  v_processor_no            spt21.processor_no%type;       --承辦人代碼
  v_receive_date            spt21.receive_date%type;       --收文日期
  v_object_id               spt21.object_id%type;          --持有者
  v_process_result          spt21.process_result%type;     --辦理結果
  v_pre_exam_date           spt21.pre_exam_date%type;      --補正期限
  v_pre_exam_qty            spt21.pre_exam_qty%type;       --補正日數
  v_receive_area            spt21.receive_area%type;       --收文區域代碼
  v_online_flg              spt21.online_flg%type;         --線上標記
  --spt31 案件資料
  v_appl_date               spt31.appl_date%type;          --申請日
  v_re_appl_date            spt31.re_appl_date%type;       --再審申請日
  v_material_appl_date      spt31.material_appl_date%type; --申請實體審查日
  v_sc_flag                 spt31.sc_flag%type;            --國家機密註記
  v_twis_flag               spt31.twis_flag%type;          --一案兩請註記
  v_foreign_language        spt31.foreign_language%type;   --外文本種類
  --spt31b 案件公開狀態資料檔
  v_pre_date                spt31b.pre_date%type;          --公開準備起始日
  --receive 收文辦理檔
  v_unusual                 receive.unusual%type;          --程序覆核

  v_name_c                  spm63.name_c%type;             --承辦人姓名
  --spt13 規費收據紀錄
  v_receipt_amt             number(7);                     --收據金額
  v_receipt_flg             varchar2(2 char);              --收據註記
  --spt82 專利公告資料
  v_notice_date             spt82.notice_date%type;        --公告日期
  v_notice_date2            spt82.notice_date_2%type;      --公開日期
  --spmf1 專利權資料
  v_charge_expir_date       spmf1.charge_expir_date%type;  --年費有效日期
  v_revoke_date             spmf1.revoke_date%type;        --撤銷日期
  --spm75 案由資料
  v_process_result_name     spm75.type_name%type;          --辦理結果中文
  -- 邏輯判斷
  v_appl_exam_flag          varchar2(1);                   --申請實體審查
  v_appl_priority_exam_flag varchar2(1);                   --申請實體審查與優先審查

  v_show_exam_fee           varchar2(1);                   --是否顯示審查費細項資料
  v_exam_fee_page_cnt       spt31.page_cnt%type;           --案件頁數
  v_exam_fee_scope_items    spt31n.scope_items%type;       --申請專利範圍項數
  v_exam_fee_exam_pay       spt31n.exam_pay%type;          --應繳審查費
  v_exam_fee_exam_have_pay  number(6);                     --已繳審查費
  v_exam_fee_tax_amount     spt31n.tax_amount%type;        --補繳或退還審查費
  v_exam_fee_e_flag         spt31n.e_flag%type;            --英譯
  v_exam_fee_f_flag         spt31n.f_flag%type;            --電子

  v_spmfi_coment            ap.spmfi.coment%type;             --代為更正備忘

  v_revise_value            appl.pre_exam_list%type;       --補正選項資訊
  v_annex_desc              appl50.annex_desc%type;        --附件說明

  procedure add_message (p_message in varchar2)
  --============--
  --新增回傳訊息--
  --============--
  is
  begin
    p_out_message_array.extend;
    p_out_message_array(p_out_message_array.last) := p_message;
  end add_message;

  procedure check_readonly
  is
    v_count number;
  begin
    select count(1)
      into v_count
      from spt21 a, spt31 b
     where a.receive_no = v_receive_no
       and a.appl_no = b.appl_no
       and b.sc_flag = '1';
    if v_count != 0 then
      p_out_readonly_message := '此公文有國防機密註記，不可編輯';
      return;
    end if;
    select count(1)
      into v_count
      from spt21
     where online_flg = 'Y'
       and receive_no = v_receive_no;
    if v_count = 0 then
      p_out_readonly_message := '紙本文件只能檢視不能辦理';
      return;
    end if;
    --- add by Susan for exclude the receives which process_result = 57001
     select count(1)
      into v_count
      from spt21
     where process_result = '57001'
       and receive_no = v_receive_no;
    if v_count >0  then
      p_out_readonly_message := '此文已作廢!不能辦理';
      return;
    end if;
    select count(1)
      into v_count
      from spt21
      left join receive
        on spt21.receive_no = receive.receive_no
     where ((spt21.att_doc_flg = 'Y' and spt21.accept_date is not null and
           spt21.object_id = receive.processor_no) or
           spt21.att_doc_flg = 'N')
       and spt21.receive_no = v_receive_no;
    if v_count = 0 then
      p_out_readonly_message := '實體附件未簽收不能辦理';
      return;
    end if;
    select count(1)
      into v_count
      from spt21
     where processor_no = p_in_processor_no
       and receive_no = v_receive_no;
    if v_count = 0 then
      p_out_readonly_message := '非承辦之文件不能辦理';
      return;
    end if;
    select count(1)
      into v_count
      from receive
     where processor_no = p_in_processor_no
       and step_code = '8'
       and receive_no = v_receive_no;
    if v_count > 0 then
      p_out_readonly_message := '文已辦結,不能編輯';
      return;
    end if;
    select count(1)
      into v_count
      from doc
     where receive_no = v_receive_no;
    if v_count = 0 then
      p_out_readonly_message := '影像未到不能辦理';
      return;
    end if;
    select count(1)
      into v_count
      from spt21 a, spt31 b
     where a.receive_no = v_receive_no
       and a.appl_no = b.appl_no
       and a.process_result = '43199'
       and b.first_day < '0920701';
    if v_count > 0 then
      p_out_readonly_message := '辦理結果為43199且首次收文日早於0920701';
      return;
    end if;
    declare
      v_merge_master receive.merge_master%type;
    begin
      select trim(merge_master)
        into v_merge_master
        from receive
       where receive_no = v_receive_no;
      if v_merge_master is not null then
         p_out_readonly_message := '已併主文' || v_merge_master || '辦理';
         return;
      end if;
    exception
      when no_data_found then null;
    end;
  end check_readonly;
begin
  p_out_message_array := varchar2_tab();
  p_out_success := 'Y';

  begin
    select a.appl_no,                      a.receive_no,
           a.type_no,                      a.assign_date,
           a.processor_no,                 a.online_flg,
           a.receive_date,                 a.object_id,
           a.process_result,               a.pre_exam_date,
           a.pre_exam_qty,                 a.receive_area,
           b.name_c
      into v_appl_no,                      v_receive_no,
           v_type_no,                      v_assign_date,
           v_processor_no,                 v_online_flg,
           v_receive_date,                 v_object_id,
           v_process_result,               v_pre_exam_date,
           v_pre_exam_qty,                 v_receive_area,
           v_name_c
      from spt21 a, spm63 b
     where a.receive_no = p_in_receive_no
       and a.processor_no = b.processor_no(+);
  exception
    when no_data_found then
      p_out_success := 'N';
      add_message('無原設計專利收文資料(SPT21)，請查明之');
  end;

  begin
    select appl_date,          re_appl_date,
           sc_flag,            twis_flag,
           foreign_language,   material_appl_date
      into v_appl_date,        v_re_appl_date,
           v_sc_flag,          v_twis_flag,
           v_foreign_language, v_material_appl_date
      from spt31
     where appl_no = v_appl_no;
    if v_type_no = '24100' and trim(v_re_appl_date) is null then
      add_message('此案無再審申請日期，無法製稿');
    end if;
  exception
    when no_data_found then
      p_out_success := 'N';
      add_message('無原設計專利案件資料(SPT31)，請查明之！');
  end;

  if v_process_result in ('41505', '43007')
    and substr(v_appl_no, 10, 1) = 'N' then
    declare
      l_charge_expir_date spmf1.charge_expir_date%type;
    begin
      select charge_expir_date
        into l_charge_expir_date
        from spmf1
       where trim(appl_no) = substr(v_appl_no, 1, 9)
         and revoke_flag != '1';
      if c_tw_sysdate > l_charge_expir_date then
        add_message('年費有效期限逾期');
      end if;
    exception
      when no_data_found then
        add_message('無年費資訊');
    end;
  end if;

  select nvl(sum(fee_amt), 0), decode(nvl(min(nvl(length(trim(receipt_no)), 0)), 0), 0, '未開', '已開')
    into v_receipt_amt, v_receipt_flg
    from spt13
   where receive_no = v_receive_no
     and number_type = 'A';

  begin
    select unusual
      into v_unusual
      from receive
     where receive_no = v_receive_no;
  exception
    when no_data_found then
      v_unusual := '0';
  end;

  begin
    select notice_date,   notice_date_2
      into v_notice_date, v_notice_date2
      from spt82
     where appl_no = v_appl_no;
  exception
    when no_data_found then
      v_notice_date := '';
      v_notice_date2 := '';
  end;

  declare
    l_notice_date spmf1.notice_date%type;
  begin
    select charge_expir_date,   revoke_date,   notice_date
      into v_charge_expir_date, v_revoke_date, l_notice_date
      from spmf1
     where trim(appl_no) = substr(v_appl_no, 1, 9)
       and revoke_flag != '1';
    if substr(v_appl_no, 4, 1) = '3' and trim(l_notice_date) is not null then
      add_message('原設計專利已公告，不得申請衍生設計專利');
    end if;
  exception
    when no_data_found then
      v_charge_expir_date := '';
      v_revoke_date := '';
  end;

  if v_process_result is not null then
    begin
      select type_name
        into v_process_result_name
        from spm75
       where type_no = v_process_result;
    exception
      when no_data_found then
        v_process_result_name := '';
    end;
  end if;

  begin
    select case
             when material_code = '10' then c_yes
             else c_no
           end,
           case
             when material_code = '10' and priority_code = '10' then c_yes
             else c_no
           end,
           case
             when trim(pre_date) is not null then
               add_twdate_months(trim(pre_date), 15)
             else
               ''
           end
      into v_appl_exam_flag,
           v_appl_priority_exam_flag,
           v_pre_date
      from spt31b
     where appl_no = v_appl_no;
  exception
      when no_data_found then
        v_appl_exam_flag := c_no;
        v_appl_priority_exam_flag := c_no;
  end;

  if v_type_no = '10000' and trim(v_process_result) is null then
    declare
      v_count    number(3);
    begin
      select count(1)
        into v_count
        from spt31f
       where receive_no = v_receive_no;
      if v_count > 0 then
        v_appl_exam_flag := c_yes;
      end if;
    end;
  end if;

  v_show_exam_fee := '';
  v_exam_fee_page_cnt := 0;
  v_exam_fee_scope_items := 0;
  v_exam_fee_exam_pay := 0;
  v_exam_fee_exam_have_pay := 0;
  v_exam_fee_tax_amount := 0;
  v_exam_fee_e_flag := c_no;
  v_exam_fee_f_flag := c_no;

  begin
    select nvl(a.page_cnt, 0),    nvl(b.scope_items, 0),  nvl(b.exam_pay, 0),
           nvl(b.tax_amount, 0),  nvl(b.e_flag, c_no),    nvl(b.f_flag, c_no)
      into v_exam_fee_page_cnt,   v_exam_fee_scope_items, v_exam_fee_exam_pay,
           v_exam_fee_tax_amount, v_exam_fee_e_flag,      v_exam_fee_f_flag
      from spt31 a, spt31n b
     where a.appl_no = b.appl_no
       and b.receive_no = v_receive_no
       and b.appl_no = v_appl_no;
  exception
    when no_data_found then null;--不處理
  end;

  begin
    select coment
      into v_spmfi_coment
      from ap.spmfi
     where appl_no = v_appl_no;
  exception
    when no_data_found then null; --不處理
  end;

  get_annex(v_appl_no, v_online_flg, v_revise_value, v_annex_desc);

  for r_spm11a in (
    select b.attorney_class, b.attorney_no, b.degister_date, b.join_date ,status
      from spm11a a, spm61 b , spt31a c
     where a.appl_no = v_appl_no
       and a.attorney_class = b.attorney_class
       and a.attorney_no = b.attorney_no
       and A.Appl_No = c.appl_no
       and c.step_code = '10'
  ) loop
  --add_message('r_spm11a.attorney_class=' || r_spm11a.attorney_class || ';r_spm11a.degister_date='|| nvl(r_spm11a.degister_date,'1'));
    if r_spm11a.attorney_class = '1' and nvl(r_spm11a.degister_date,'1') ='1' then
      add_message('本案件之代理人專利師 ' || r_spm11a.attorney_no || ' 尚未登錄，請注意');
    elsif r_spm11a.status = '3' then
      add_message('本案件之代理人：' || r_spm11a.attorney_no || ' 已變更身分，請注意');
    elsif r_spm11a.attorney_class = '1' and trim(r_spm11a.join_date) is null then
      add_message('本案件之代理人：'  || r_spm11a.attorney_no || ' ，尚未加入專利師公會，請通知專利一組一科，分機：7240');
    end if;
  end loop;

  /*declare
    v_count number;
  begin
    select count(1)
      into v_count
      from spm33
     where appl_no = v_appl_no
       and new_old_type = '0'
       and type_no in ('11000', '11002', '11004', '11006', '11008', '11010', '11090', '11092');
    if v_count > 0 then
      add_message('此案件已被改請');
    end if;
  end;*/

  /*if length(trim(v_appl_no)) = 9 and v_type_no in ('16000', '16002', '16004') then
    declare
      v_count number;
    begin
      select count(1)
        into v_count
        from spt21
       where appl_no like trim(v_appl_no) || '%'
         and type_no = '15000';
      if v_count > 0 then
        add_message('此案有申請舉發相關收文，請注意此收文的申請案號資料是否需修改');
      end if;
    end;
  end if;*/

  select priority_right_obj(
           appl_no,           priority_flag,
           data_seq,          priority_date,
           priority_appl_no,  priority_nation_id,
           priority_doc_flag, priority_revive,
           access_code,       ip_type,
           null
         )
    bulk collect
    into p_out_priority_right_array
    from spt32
   where appl_no = v_appl_no;

  if p_out_priority_right_array.count > 0 then
    declare
      function get_response_status(p_appl_no in varchar2, p_access_code in varchar2)
      return varchar2
      is
        v_response_status spt32_rq.response_status%type;
      begin
        select response_status
          into v_response_status
          from (
            select response_status
              from spt32_rq
             where trim(ref_doc_number) = trim(p_appl_no)
               and access_code = nvl(p_access_code, access_code)
             order by ack_id desc)
         where rownum = 1;
        return v_response_status;
      exception
        when no_data_found then return null;--不處理
      end;
    begin
      for l_idx in p_out_priority_right_array.first .. p_out_priority_right_array.last
      loop
        p_out_priority_right_array(l_idx).response_status
          := get_response_status(v_appl_no, p_out_priority_right_array(l_idx).access_code);
      end loop;
    end;
  end if;

  if substr(v_appl_no, 4, 1) not in ('2', '3') then
    select biomaterial_obj(
             appl_no,         data_seq,    microbe_date,     microbe_org_id,
             microbe_appl_no, national_id, microbe_org_name
           )
      bulk collect
      into p_out_biomaterial_array
      from spt33
     where appl_no = v_appl_no
     order by data_seq;
  end if;

  select grace_period_obj(
           appl_no, data_seq, novel_flag, novel_item, novel_date, sort_id
         )
    bulk collect
    into p_out_grace_period_array
    from spt31l
   where appl_no = v_appl_no
   order by sort_id;

  select appl_seq || '#' || status || '#' || process_result
    bulk collect
    into p_out_request_item_array
    from ap.spt31w
   where appl_no = v_appl_no;

  p_out_proccess_info := proccess_info_obj(
    appl_no                 => v_appl_no,
    receive_no              => v_receive_no,
    type_no                 => v_type_no,
    assign_date             => v_assign_date,
    processor_no            => v_processor_no,
    receive_date            => v_receive_date,
    object_id               => v_object_id,
    process_result          => v_process_result,
    pre_exam_date           => v_pre_exam_date,
    pre_exam_qty            => v_pre_exam_qty,
    receive_area            => v_receive_area,
    appl_date               => v_appl_date,
    re_appl_date            => v_re_appl_date,
    sc_flag                 => v_sc_flag,
    twis_flag               => v_twis_flag,
    foreign_language        => v_foreign_language,
    pre_date                => v_pre_date,
    unusual                 => v_unusual,
    material_appl_date      => v_material_appl_date,
    name_c                  => v_name_c,
    receipt_amt             => v_receipt_amt,
    receipt_flg             => v_receipt_flg,
    charge_expir_date       => v_charge_expir_date,
    revoke_date             => v_revoke_date,
    notice_date             => v_notice_date,
    notice_date2            => v_notice_date2,
    process_result_name     => v_process_result_name,
    appl_exam_flag          => v_appl_exam_flag,
    appl_priority_exam_flag => v_appl_priority_exam_flag,
    show_exam_fee           => v_show_exam_fee,
    exam_fee_page_cnt       => v_exam_fee_page_cnt,
    exam_fee_scope_items    => v_exam_fee_scope_items,
    exam_fee_exam_pay       => v_exam_fee_exam_pay,
    exam_fee_exam_have_pay  => v_exam_fee_exam_have_pay,
    exam_fee_tax_amount     => v_exam_fee_tax_amount,
    exam_fee_e_flag         => v_exam_fee_e_flag,
    exam_fee_f_flag         => v_exam_fee_f_flag,
    spmfi_coment            => v_spmfi_coment,
    revise_value            => v_revise_value,
    annex_desc              => v_annex_desc,
    online_flg              => v_online_flg
  );

  if p_out_success = 'Y' then
    check_readonly;
  end if;

--exception when others then
--  dbms_output.put_line(dbms_utility.format_error_stack);
end get_proccess_page;

/
--------------------------------------------------------
--  DDL for Procedure GET_PUBLIC_BIBLIOGRAPHY
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."GET_PUBLIC_BIBLIOGRAPHY" (
  P_APPL_NO IN CHAR, 
  APPL_NO OUT CHAR,           --申請案號
  APPL_DATE OUT CHAR,         --申請日期
  PATENT_NAME_C OUT VARCHAR2, --專利中文名稱
  PATENT_NAME_E OUT VARCHAR2, --專利英文名稱
  NOTICE_NO_2 OUT CHAR,       --公開號
  NOTICE_DATE_2 OUT CHAR,     --公開日
  APPL_FLAG OUT CHAR,         --實體審查申請註記
  IPCS OUT SYS_REFCURSOR,         --國際專利分類
  APPLICANTS OUT SYS_REFCURSOR,   --申請人資料
  INVENTORS OUT SYS_REFCURSOR,    --發明人資料
  PROXYS OUT SYS_REFCURSOR        --代理人資料
)IS 
  V_SPT82_NOTICE_NO_2   SPT82.NOTICE_NO_2%TYPE;
  V_SPM21B_STEP_CODE    SPM21B.STEP_CODE%TYPE;
  V_SPM21B_IPC_REF_TYPE SPM21B.IPC_REF_TYPE%TYPE;
BEGIN
  SELECT A.APPL_NO, A.APPL_DATE, A.PATENT_NAME_C, A.PATENT_NAME_E, 
         B.NOTICE_NO_2, B.NOTICE_DATE_2,
         C.APPL_FLAG
    INTO APPL_NO, APPL_DATE, PATENT_NAME_C, PATENT_NAME_E,
         NOTICE_NO_2, NOTICE_DATE_2,
         APPL_FLAG
    FROM SPT31 A, SPT82 B, (
           SELECT APPL_NO, MAX(APPL_FLAG) AS APPL_FLAG
             FROM SPT31F 
            WHERE APPL_NO = P_APPL_NO
            GROUP BY APPL_NO
         ) C
   WHERE A.APPL_NO = B.APPL_NO(+)
     AND A.APPL_NO = C.APPL_NO(+)
     AND A.APPL_NO = P_APPL_NO;
  
  BEGIN
    SELECT NOTICE_NO_2
      INTO V_SPT82_NOTICE_NO_2
      FROM SPT82
     WHERE APPL_NO = P_APPL_NO;
    IF TRIM(V_SPT82_NOTICE_NO_2) IS NOT NULL THEN
      V_SPM21B_STEP_CODE := 'B';
      V_SPM21B_IPC_REF_TYPE := '7';
    ELSE
      V_SPM21B_STEP_CODE := 'V';
      V_SPM21B_IPC_REF_TYPE := '6';
    END IF;
  EXCEPTION
    WHEN no_data_found THEN
      V_SPM21B_STEP_CODE := 'B';
      V_SPM21B_IPC_REF_TYPE := '6';
  END;
  
  OPEN IPCS FOR
    SELECT IPC_CODE_MS, IPC_CODE_DT, SUBSTR(VERSION_NO, 1, 4) || '.' || SUBSTR(VERSION_NO, 5, 2) AS VERSION_NO
      FROM SPM21B
     WHERE APPL_NO = P_APPL_NO
       AND STEP_CODE = V_SPM21B_STEP_CODE
       AND IPC_REF_TYPE = V_SPM21B_IPC_REF_TYPE;
    
  OPEN APPLICANTS FOR
    SELECT NAME_C, NAME_E, ADDR_C, ADDR_E 
      FROM SPM11 
     WHERE APPL_NO = P_APPL_NO
       AND ID_TYPE = '1' 
     ORDER BY DATA_SEQ;
  
  OPEN INVENTORS FOR 
    SELECT NAME_C, NAME_E 
      FROM SPM11 
     WHERE APPL_NO = P_APPL_NO
       AND ID_TYPE = '2' 
     ORDER BY DATA_SEQ;
  
  OPEN PROXYS FOR
    SELECT A.NAME_C 
      FROM SPM61 A, SPM11A B 
     WHERE A.ATTORNEY_NO = B.ATTORNEY_NO 
       AND B.APPL_NO = P_APPL_NO;
  
END GET_PUBLIC_BIBLIOGRAPHY;

/
--------------------------------------------------------
--  DDL for Procedure GET_RECEIVE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."GET_RECEIVE" (p_object_id in varchar2,
                                        p_quota     in number,
                                        p_out_msg   out varchar2) is
---------------------------------
-- Get receive
-- Modify Date : 104/07/16
-- Get type_no from spt21
-- 5/20 record transfer history
-- 6/2  change receive_trans_log schema
-- 6/25 update process_date
-- 104/07/16 change the rule of getting number ,reference parameter
---------------------------------
  type receive_no_tab is table of spt21.receive_no%type;
  l_rec        number;
  l_rec2       number;
  g_difference number;
  g_total      number;
  g_maxNO      number;
  g_holdNO     number;
  ecode        number;
  g_reason     nvarchar2(100);
  v_rec_no   char(15);
  v_pre_no   char(15);
  v_receive_date char(7);
  
  CURSOR list_cursor IS 
     select distinct spt21.receive_date,  tmp.receive_no, tmp.pre_no 
    from  tmp_get_receive tmp join spt21 on  tmp.receive_no = spt21.receive_no
    where  (exists (select processor_no
                      from skill
                     where (case
                             when tmp.skill = 'INVENTION' then  INVENTION
                             when tmp.skill = 'UTILITY' then   UTILITY
                             when tmp.skill = 'DESIGN' then    DESIGN
                             when tmp.skill = 'DERIVATIVE' then  DERIVATIVE
                             when tmp.skill = 'IMPEACHMENT' then IMPEACHMENT
                             when tmp.skill = 'REMEDY' then     REMEDY
                             when tmp.skill = 'PETITION' then  PETITION
                             when tmp.skill = 'DIVIDING' then  DIVIDING
                             when tmp.skill = 'CONVERTING' then CONVERTING
                             when tmp.skill = 'DIVIDING_AMEND' then  DIVIDING_AMEND
                             when tmp.skill = 'CONVERTING_AMEND' then   CONVERTING_AMEND
                             when tmp.skill = 'MISC_AMEND' then MISC_AMEND
                           end) = '1'
                       and processor_no = p_object_id --:login_user  -- 
                    ) )
    order by  spt21.receive_date,  tmp.pre_no,tmp.receive_no
    ;
     
/*
不限要求件數,一?領取
*/
procedure transfer_p
  --移轉文號
  is
  begin
  
    select count(1) into g_total from tmp_get_receive where skill = p_object_id and is_get = '0';
   
    update receive set step_code = '2', processor_no  = p_object_id , process_date = to_char(to_number(to_char(sysdate,'yyyyMMdd'))-19110000)
          where receive_no in (select receive_no from tmp_get_receive where skill = p_object_id  and is_get = '0');
    update spt21 set  processor_no  = p_object_id ,process_result = null
          where receive_no in (select receive_no from tmp_get_receive where skill = p_object_id and is_get = '0');
          
          
    update spt31
    set sch_processor_no= p_object_id, phy_processor_no = p_object_id
    where appl_no in 
    (
      select appl_no from spt31a
      where appl_no in
      (
      select appl_no from  spt21   where receive_no in (select receive_no from tmp_get_receive where skill = p_object_id and is_get = '0')
          )
        and substr(appl_no,10,1) != 'N'
        and ((step_code between '10' and '19'  and step_code != '15')
              or step_code = '30'
              or step_code = '29'
              or step_code = '49'
              or  exists (
                select 1 from  spt21   where receive_no in (select receive_no from tmp_get_receive where skill = p_object_id and is_get = '0')
               and  type_no in ('16000','16002','22210')
          )
        ))
      ;
     ---------------------
    -- record receive transfer history
    ---------------------
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1')  seq , 
              receive.receive_no, receive.appl_no , p_object_id,'2',sysdate,'領辦'
      from receive
       where receive_no in (select receive_no from tmp_get_receive where skill = p_object_id  and is_get = '0');
         
    update tmp_get_receive  set  is_get ='1'  
    where receive_no in (select receive_no from tmp_get_receive where skill = p_object_id and is_get = '0');
              
    commit;
  end;

/*--------------
  判斷領取件數
----------------*/
  procedure transfer
  --移轉文號
   is
  begin
  
    OPEN list_cursor;
   LOOP
      FETCH list_cursor INTO v_receive_date,v_rec_no,v_pre_no ;
       EXIT WHEN  list_cursor%NOTFOUND;
           
             dbms_output.put_line('v_rec_no:' || v_rec_no || ';v_pre_no:' ||v_pre_no  );
                  l_rec2 := 0;
                
                --- the record should be gotten
                select count(1) into l_rec2 from receive 
                where receive_no in (
                 select distinct receive_no from tmp_get_receive where pre_no = v_pre_no and is_get ='0'                  
                 ) and  step_code = '0';
                
                IF l_rec2 >0 THEN
                  update receive set step_code = '2', processor_no  = p_object_id, process_date = to_char(to_number(to_char(sysdate,'yyyyMMdd'))-19110000)
                  where receive_no in (
                       select distinct receive_no from tmp_get_receive where pre_no = v_pre_no and is_get ='0' 
                       ) and  step_code = '0';
                       
                   l_rec2 := SQL%ROWCOUNT; -- the real records are gotten
                   dbms_output.put_line(l_rec2 || ':'||l_rec2);
                   IF l_rec2 > 0 THEN
                       ---------------------
                        -- record receive transfer history
                       ---------------------
                        INSERT INTO RECEIVE_TRANS_LOG
                        SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1')  seq , 
                                receive.receive_no, receive.appl_no , p_object_id,'2',sysdate,'領辦'
                                from receive
                                where receive_no in (
                                 select distinct receive_no from tmp_get_receive where pre_no = v_pre_no and is_get ='0' 
                                 ) ;
                       ---------------------------------------------
                        update spt21 set  processor_no  = p_object_id , process_result = null  where receive_no in (
                         select distinct receive_no from tmp_get_receive where pre_no = v_pre_no and is_get ='0' 
                          ) ;
                        
                        update spt31
                        set sch_processor_no= p_object_id, phy_processor_no = p_object_id
                        where appl_no in 
                        (
                            select appl_no from spt31a
                              where appl_no in
                              (
                                select appl_no from  spt21   where receive_no in (
                                    select distinct receive_no from tmp_get_receive where pre_no =  v_pre_no
                                    and is_get ='0'             )
                              )
                              and substr(appl_no,10,1) != 'N'
                              and ((step_code between '10' and '19'  and step_code != '15')
                                    or step_code = '30'
                                    or step_code = '29'
                                    or step_code = '49'
                                    or  exists (
                                        select 1 from  spt21   where receive_no in (
                                    select distinct receive_no from tmp_get_receive where pre_no =  v_pre_no
                                    and is_get ='0'             )
                                    and  type_no in ('16000','16002','22210')
                                      )
                                ))
                            ;  
                          
                        update tmp_get_receive  set  is_get ='1'  where pre_no = v_pre_no and is_get ='0' ;
                    END IF;
               commit;
               g_total := g_total + l_rec2;
             END IF;
       EXIT WHEN g_total >= g_difference;
   END LOOP;
   CLOSE list_cursor;
  
  
  end;
  procedure related_case2
  --  外包自動退文,和後續文一起領
  --  需整包全領,判斷條件
   is
   -- v_collect receive_no_tab;
  begin
   dbms_output.put_line('update 外包自動退文');
    update receive
       set return_no = '1', step_code = '0', processor_no = '70012'
     where receive_no in
           (Select distinct a.receive_no
              from receive a
              join receive b
                on a.appl_no = b.appl_no
             where substr(a.processor_no, 1, 1) = 'P'
               And a.step_code = '2'
               and substr(a.receive_no, 4, 1) = '2'
               and a.return_no = '0'
               and exists (select 1
                      from receive b join spt21 s21 on b.receive_no = s21.receive_no
                     where b.appl_no = a.appl_no
                       and substr(b.receive_no, 4, 1) = '3'
                       and b.step_code = '0'
                       and s21.type_no in ('10010','13002','15002','16004','16006',
                                         '24708','17000','24022','24308','21002',
                                         '24004','24010','24018','24028','24060',
                                         '20000','20002','20004','20006','20008',
                                         '20010','24500','24502',
                                         '24714','24716','24712','24720','21400','24706','24710'
                                         ))
                        )
          and not  exists (select 1
                            from spt32
                            where spt32.PRIORITY_NATION_ID = 'TW'
                            and spt32.appl_no = receive.appl_no);
   update spt21
       set  processor_no = '70012'
     where receive_no in
           (Select distinct a.receive_no
              from receive a
              join receive b
                on a.appl_no = b.appl_no
             where substr(a.processor_no, 1, 1) = 'P'
               And a.step_code = '2'
               and substr(a.receive_no, 4, 1) = '2'
               and a.return_no = '0'
               and exists (select 1
                      from receive b join spt21 s21 on b.receive_no = s21.receive_no
                     where b.appl_no = a.appl_no
                       and substr(b.receive_no, 4, 1) = '3'
                       and b.step_code = '0'
                       and s21.type_no in ('10010','13002','15002','16004','16006',
                                         '24708','17000','24022','24308','21002',
                                         '24004','24010','24018','24028','24060',
                                         '20000','20002','20004','20006','20008',
                                         '20010','24500','24502'))
                      );                                         
    commit;                                         
    insert into tmp_get_receive
    select receive_no , pre_no ,'related_case2','MISC_AMEND','外包自動退文,和後續文一起領','0'
      from (Select a.receive_no, a.receive_no pre_no
              from receive a
             where a.return_no = '1'
               And a.step_code = '0'
            union all
            Select b.receive_no , c.receive_no pre_no
              from receive b 
              join (select appl_no ,receive_no
                                   from receive a
                                  where a.return_no = '1'
                                    And a.step_code = '0') c
                  on b.appl_no = c.appl_no
             where substr(b.receive_no, 4, 1) = '3'
               and b.step_code = '0'
               )
     ;
    commit;
  --  g_reason := '外包自動退文,和後續文一起領';

  end related_case2;

begin
  g_difference := p_quota;
  g_total      := 0;
  l_rec        := 0;

  SELECT count(1) into l_rec from receive where step_code = '0' and return_no not in ('4','A','B','C');
 
 ------------------------------------------
 -- Batch , for test
 --------------------------------------------
  -- CHECK_RECEIVE(p_out_msg);
  related_case2;
  transfer_p;
  
  select pname into g_maxNO from parameter where para_no = 'MAX_REC';
  select count(1) into g_holdNO from receive where processor_no = p_object_id and step_code in ('2','3','5');
  
  IF g_holdNO >= g_maxNO THEN
     p_out_msg := '您的線上公文已超過最大件數:' || g_maxNO;
  ELSE
    IF g_maxNO - g_holdNO < p_quota THEN
        g_difference := g_maxNO - g_holdNO ;
    ELSE
        g_difference := p_quota;
    END IF;
    
    transfer;
    
     IF l_rec = 0 THEN
       p_out_msg := '無可領之線上公文';
     ELSE
        IF g_total = 0 THEN
           p_out_msg := '無權限可領';
        ELSE
          p_out_msg := '領取' || g_total || '筆件數';
        END IF;
     END IF;
  END IF;
  
 

  dbms_output.put_line(p_out_msg);
EXCEPTION
  WHEN OTHERS THEN
    ecode     := SQLCODE;
    p_out_msg := SQLCODE || ' : ' || SQLERRM;
    dbms_output.put_line('Error Code:' || ecode || '; Error Message:' ||
                         p_out_msg);
END GET_RECEIVE;

/
--------------------------------------------------------
--  DDL for Procedure LIST_CASE_SECTION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."LIST_CASE_SECTION" (p_out_list out sys_refcursor) is
begin
  /*
   ModifyDate : 2015/07/23
   DESC: Statistics of projects handled by processor
   104/07/23 : change conditoin for project  processor_no ,change from spt31.sch_processor_no to appl.appl_no
  */

  OPEN p_out_list FOR
    select spm63.processor_no,
           spm63.name_c,
           sum(case
                 when divide_code = '1' and is_overtime = '1' then
                  1
                 else
                  0
               end) as PERSONAL_EXCEED,
           sum(case
                 when divide_code = '2' then
                  1
                 else
                  0
               end) as AUTO_SHIFT,
           sum(case
                 when divide_code = '3' then
                  1
                 else
                  0
               end) as OTHER_REJECTED,
           sum(case
                 when divide_code = '4' then
                  1
                 else
                  0
               end) as CHIEF_DISPATCH
      from  spm63 
     left join  appl on appl.processor_no = spm63.processor_no
      left join spt31 on appl.appl_no = spt31.appl_no
     where   spm63.dept_no = '70012'
       and spm63.quit_date IS NULL
       and substr(spm63.processor_no,1,1) != 'P'
       and spm63.processor_no != '60043'
     group by spm63.processor_no, spm63.name_c
     ORDER BY PROCESSOR_NO;

end LIST_CASE_SECTION;

/
--------------------------------------------------------
--  DDL for Procedure LIST_CHEK_RECEIVE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."LIST_CHEK_RECEIVE" (
  p_out_list out sys_refcursor) 
is
begin
  /*
  Desc: statistic the receive is overtime or waiting form signed ...
        公文稽催(同仁+外包) 統計 
  ModifyDate: 104/08/02
  104/09/10 : exclude the receives which process_result = 57001
  */
  OPEN p_out_list FOR
    SELECT   spm63.processor_no,
          spm63.name_c,
          nvl(s.S_TO_EXCEED,0) S_TO_EXCEED ,
          nvl(s.S_FOR_APPROVE,0) S_FOR_APPROVE,
          nvl(s.S_EXCEEDED,0) S_EXCEEDED
from spm63
left join
(
SELECT   receive.processor_no ,
         SUM( case when to_char(sysdate,'yyyyMMdd') between   cdate.date_bc and to_number(substr( spt21.control_date,1,3))+1911 || substr( spt21.control_date,4,4)
              and step_code != '4' then 1 else 0 end) S_TO_EXCEED ,
         SUM( case when to_char(sysdate,'yyyyMMdd') between   cdate.date_bc and to_number(substr( spt21.control_date,1,3))+1911 || substr( spt21.control_date,4,4)
              and step_code = '4' then 1 else 0 end) S_FOR_APPROVE ,
         SUM( case when to_char(sysdate,'yyyyMMdd') > to_number(substr( spt21.control_date,1,3))+1911 || substr( spt21.control_date,4,4)
              then 1 else 0 end)       S_EXCEEDED 
    FROM  receive 
    join spt21 On receive.receive_no = spt21.receive_no 
    LEFT JOIN SPM56 s56 ON s56.receive_no = spt21.receive_no and s56.processor_no = spt21.processor_no and s56.issue_flag = '1'
    LEFT JOIN 
    (
      SELECT row_number() over(partition by spt21.receive_no order by date_chinese desc) d  ,spt21.control_date,  SPSB36.date_bc ,spt21.receive_no
      FROM spt21 join ap.SPSB36 on SPSB36.date_bc < to_number(substr( spt21.control_date,1,3))+1911 || substr( spt21.control_date,4,4)
      JOIN receive on spt21.receive_no = receive.receive_no
      WHERE  SPSB36.date_flag = 1
      AND spt21.process_result != '57001'
      AND receive.processor_no  IN (
          SELECT PROCESSOR_NO 
          FROM SPM63 
          WHERE DEPT_NO ='70012' AND QUIT_DATE IS NULL )
     ) cdate on cdate.receive_no = receive.receive_no 
    WHERE receive.step_code >= '2'
    AND  receive.step_code < '8'
    AND spt21.process_result != '57001'
    AND cdate.d = 2
    group by receive.processor_no 
) s on spm63.processor_no = s.processor_no
where SPM63.DEPT_NO ='70012' 
    AND SPM63.QUIT_DATE IS NULL 
    ORDER BY spm63.PROCESSOR_NO
  ;
  
  
end LIST_CHEK_RECEIVE;

/
--------------------------------------------------------
--  DDL for Procedure LIST_PERFORMANCE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."LIST_PERFORMANCE" (
  p_in_year in varchar2,
  p_in_processor_no in varchar2,
  p_out_list out sys_refcursor) 
is
/* desc: 年度績效 Performance Yearly
   ModifyDate : 104/07/09
   ModityItem: online receive dated by close date of form signed ( receive.sign_date)
*/
begin    
  OPEN p_out_list FOR  
  SELECT  A.PROCESSOR_NO, A.NAME_C,
          (A.JAN || '*' || NVL(B.JAN,0)) AS T1 ,
          (A.FEB || '*' || NVL(B.FEB,0) ) AS T2 ,
          (A.MAR || '*' || NVL(B.MAR,0) ) AS T3 ,
          (A.APR || '*' || NVL(B.APR,0) ) AS T4 ,
          (A.MAY || '*' || NVL(B.MAY,0) ) AS T5 ,
          (A.JUN || '*' || NVL(B.JUN,0) ) AS T6 ,
          (A.JUL || '*' || NVL(B.JUL,0) ) AS T7 ,
          (A.AUG || '*' || NVL(B.AUG,0) ) AS T8 ,
          (A.SEP || '*' || NVL(B.SEP,0) ) AS T9 ,
          (A.OCT || '*' || NVL(B.OCT,0)) AS T10,
          (A.NOV || '*' || NVL(B.NOV,0)) AS T11,
          (A.DEC || '*' || NVL(B.DEC,0)) AS T12
  FROM (
    SELECT TRIM(PROCESSOR_NO) AS PROCESSOR_NO, NAME_C, "JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC" FROM (
      SELECT A.PROCESSOR_NO, S.NAME_C, A.YYYY , A.MM, (BASE * WORKDAY + FACTOR) AS QUOTA
      FROM QUOTA A, QUOTA_BASE B, SPM63 S,
        (
          SELECT SUBSTR(DATE_BC,1,4) AS YYYY, SUBSTR(DATE_BC,5,2) AS MM, SUM(DATE_FLAG) AS WORKDAY
          FROM SPMFF
          GROUP BY SUBSTR(DATE_BC,1,4), SUBSTR(DATE_BC,5,2)
        ) W
      WHERE A.PROCESSOR_NO=B.PROCESSOR_NO AND A.YYYY=B.YYYY
            AND A.PROCESSOR_NO=S.PROCESSOR_NO
            AND A.YYYY=W.YYYY AND A.MM=W.MM
            AND A.YYYY=p_in_year
      ORDER BY A.MM
    )
    PIVOT
    (
       SUM(QUOTA)
       FOR MM IN ('01' AS JAN, '02' AS FEB, '03' AS MAR, '04' AS APR, '05' AS MAY,
        '06' AS JUN, '07' AS JUL, '08' AS AUG, '09' AS SEP, '10' AS OCT, '11' AS NOV, '12' AS DEC)
    )
  ) A
  LEFT JOIN
  (
    SELECT TRIM(PROCESSOR_NO) AS PROCESSOR_NO, NAME_C, "JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC" FROM (
      SELECT W.PROCESSOR_NO, S.NAME_C, W.YYYY , W.MM,  QUOTA
      FROM  SPM63 S
      LEFT JOIN
        (
          select processor_no,
                substr(to_char(to_number(sign_date) + 19110000),1,4) YYYY,
                substr(to_char(to_number(sign_date) + 19110000),5,2) MM,
                count(1)  AS QUOTA
            from receive 
            where receive.step_code = '8'
            group by  substr(to_char(to_number(sign_date) + 19110000),1,4) ,
              substr(to_char(to_number(sign_date) + 19110000),5,2) ,
              processor_no 
        ) W
        ON  W.PROCESSOR_NO=S.PROCESSOR_NO
      WHERE  W.YYYY=p_in_year
      ORDER BY W.MM
    )
    PIVOT
    (
       SUM(QUOTA)
       FOR MM IN ('01' AS JAN, '02' AS FEB, '03' AS MAR, '04' AS APR, '05' AS MAY,
        '06' AS JUN, '07' AS JUL, '08' AS AUG, '09' AS SEP, '10' AS OCT, '11' AS NOV, '12' AS DEC)
    )
  ) B   ON A.PROCESSOR_NO = B.PROCESSOR_NO
  WHERE  A.PROCESSOR_NO = NVL(p_in_processor_no, A.PROCESSOR_NO)      
  ORDER BY A.PROCESSOR_NO;
  
end LIST_PERFORMANCE;

/
--------------------------------------------------------
--  DDL for Procedure LIST_RECEIVE_TRANS_LOG
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."LIST_RECEIVE_TRANS_LOG" (p_in_receive_no in char,
                                                   p_out_list      out sys_refcursor) is
begin
/*
文案歷程
ModifyDate : 2015/06/25
Desc : (1) add status : 待分, 主管退辦
(2) change date format
*/

  OPEN p_out_list FOR
    select to_char(RECEIVE_TRANS_LOG.trans_date, 'yyyy/MM/dd HH24:mi') as trans_date,
           RECEIVE_TRANS_LOG.receive_no,
           spm63.name_c,
          case
             when step_code_d = '0' and return_no = '4' then
              '待分'
             when step_code_d = '0'  then
              '待領'
             when step_code_d = '1' then
              '它科待辦'
             when step_code_d = '2' then
              '待辦'
             when step_code_d = '3' then
              '已銷號'
             when step_code_d = '4' and return_no = '5' then 
              '主管退辦'
             when step_code_d = '4'  then 
              '送核'
             when step_code_d = '5' then
              '將逾期'
             when step_code_d = '6' then
              '已逾期'
             when step_code_d = '8' then
              '辦結'
             else
              '無'
           end as step,
           memo
      from RECEIVE_TRANS_LOG
      left join receive on RECEIVE_TRANS_LOG.receive_no = receive.receive_no
      left join spm63
        on RECEIVE_TRANS_LOG.processor_no_d = spm63.processor_no
     where RECEIVE_TRANS_LOG.receive_no = p_in_receive_no
     order by RECEIVE_TRANS_LOG.trans_date
     ;

end LIST_RECEIVE_TRANS_LOG;

/
--------------------------------------------------------
--  DDL for Procedure LIST_RECEIVE_TRANS_LOG_INFO
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."LIST_RECEIVE_TRANS_LOG_INFO" (p_in_receive_no in char,
                                                        receive_no      out varchar2,
                                                        receive_date    out varchar2,
                                                        last_pno        out varchar2,
                                                        last_step_code  out varchar2) is
begin
/*
 ModifyDate : 2015/06/02
*/

  select receive_no,
         (select receive_date from spt21 where receive_no = lg.receive_no) as receive_date,
         processor_no_d last_pno,
         case
           when step_code_d = '0' then
            '待領'
           when step_code_d = '1' then
            '他科待辦'
           when step_code_d = '2' then
            '待辦'
           when step_code_d = '3' then
            '已銷號'
           when step_code_d = '4' then
            '陳核中'
           when step_code_d = '5' then
            '將逾期'
           when step_code_d = '6' then
            '已逾期'
           when step_code_d = '8' then
            '辦結'
           else
            '無'
         end as last_step_code
    into receive_no, receive_date, last_pno, last_step_code
    from RECEIVE_TRANS_LOG lg
   where receive_no = p_in_receive_no
     and trans_date = (select max(trans_date)
                         from RECEIVE_TRANS_LOG
                        where lg.receive_no = receive_no);
exception
  when no_data_found then
    receive_no     := p_in_receive_no;
    receive_date   := '';
    last_pno       := '';
    last_step_code := '';
  
end LIST_RECEIVE_TRANS_LOG_INFO;

/
--------------------------------------------------------
--  DDL for Procedure LIST_SECTION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."LIST_SECTION" (
  p_out_list out sys_refcursor) 
is
begin
  /*
   Modify Date : 104/09/10
   104/09/10 : exclude the receives which process_result =57001
  */
  OPEN p_out_list FOR
 SELECT SPM63.PROCESSOR_NO, SPM63.NAME_C, NVL(A.TODO,0) TODO, NVL(A.DONE,0) DONE, NVL(A.REJECTED,0) REJECTED, 
         NVL(B.TODO_P,0) TODO_P, -- 紙本公文
         NVL(C.DONE_P,0) DONE_P, -- 紙本已銷號
         NVL(D.REJECTED_P,0) REJECTED_P -- 紙本退辦
  FROM SPM63
   LEFT JOIN (
       SELECT RECEIVE.PROCESSOR_NO,
          COUNT(CASE WHEN s21.PROCESS_RESULT is null  AND RECEIVE.RECEIVE_NO is not null THEN 1 ELSE NULL END) AS TODO,
          COUNT(CASE WHEN s21.PROCESS_RESULT is not null  AND s21.process_result != '57001'   AND return_no not in ('4','A','B','C','D') THEN 1 ELSE NULL END) AS DONE,
          COUNT(CASE WHEN receive.step_code = '5' and substr(RECEIVE.processor_no,1,1) != 'P'  AND s21.process_result != '57001'
               THEN 1 ELSE NULL END) AS REJECTED
      FROM  RECEIVE  
       JOIN SPT21 s21 ON s21.RECEIVE_NO = RECEIVE.RECEIVE_NO 
      WHERE  RECEIVE.step_code > '0'
        AND RECEIVE.step_code < '8'
      GROUP BY RECEIVE.PROCESSOR_NO
  ) A ON   SPM63.PROCESSOR_NO = A.PROCESSOR_NO
  LEFT JOIN (
      SELECT SPT21.object_id as PROCESSOR_NO, COUNT(SPT21.RECEIVE_NO) AS TODO_P
      FROM SPT21
      LEFT JOIN SPT23 ON SPT21.receive_no = SPT23.receive_no AND SPT21.OBJECT_ID = Spt23.OBJECT_TO
      WHERE SPT23.data_seq = (select max(data_seq) from spt23 s23 where SPT23.receive_no = s23.receive_no) 
      AND SPT23.ACCEPT_DATE IS NOT NULL
      AND PROCESS_RESULT IS NULL
      AND SPT21.object_id IN (SELECT PROCESSOR_NO FROM SPM63 WHERE DEPT_NO ='70012' AND QUIT_DATE IS NULL)
      AND SPT21.trans_no = '912'
      GROUP BY SPT21.object_id
   ) B ON SPM63.PROCESSOR_NO = B.PROCESSOR_NO
   LEFT JOIN
    (
      SELECT SPT21.object_id as PROCESSOR_NO, COUNT(SPT21.RECEIVE_NO) AS DONE_P
      FROM SPT21
      WHERE  PROCESS_RESULT IS NOT NULL
      AND PROCESS_RESULT != '57001'
      AND NOT EXISTS (SELECT RECEIVE_NO FROM SPT41 WHERE RECEIVE_NO = SPT21.RECEIVE_NO and processor_no = SPT21.processor_no and check_datetime is not null)
      AND SPT21.object_id IN (SELECT PROCESSOR_NO FROM SPM63 WHERE DEPT_NO ='70012' AND QUIT_DATE IS NULL)
      AND SPT21.trans_no = '912'
      GROUP BY SPT21.object_id
   ) C ON SPM63.PROCESSOR_NO=C.PROCESSOR_NO
   LEFT JOIN 
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
   ) D ON SPM63.PROCESSOR_NO=D.PROCESSOR_NO 
   WHERE SPM63.PROCESSOR_NO IS NOT NULL 
   AND SPM63.DEPT_NO = '70012'
   AND SPM63.QUIT_DATE is null
  ORDER BY SPM63.PROCESSOR_NO;
  
  
end LIST_SECTION;

/
--------------------------------------------------------
--  DDL for Procedure LIST_VIEW
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."LIST_VIEW" (p_in_type        in varchar2,
                                      p_in_proccess_no in varchar2,
                                      p_in_code        in varchar,
                                      p_out_list       out sys_refcursor) is
begin
  /*
   ModifyDate: 104/09/10
   Desc: receive list
   (1) add column: post_reason
   (2) add list: manager assign directly
   0630: add column form_file_a
   0703: add column att_doc_flg 實體附件 for paper list
   0706: add column return_reason
   104/07/14 : modify return reason from return_no = 5
   104/07/22 : add list S_TO_EXCEED 將逾期 , S_FOR_APPROVE 陳核中, S_EXCEEDED 已逾期
   104/07/24 : add situation for postpone  WHEN  trim(post_reason) is null  and IS_POSTPONE ='4' THEN
                 '其它'
   104/08/02 : change the condition for receive statur of is overtime, waiting form signed for has overtimed
   104/08/10 : add S_IMG_NOT_READY and S_NOT_SECTION
   104/09/10 : exclude the receives which process_result = 57001
  */

  if p_in_type in ('TODO', 'DONE', 'REJECTED') then
    -- 線上 公文 已銷號 主管退辦
    OPEN p_out_list FOR
      SELECT R.RECEIVE_DATE,
             R.RECEIVE_NO,
             R.APPL_NO,
             R.TYPE_NO || ' ' || T.TYPE_NAME AS TYPE_NAME,
             R.TRANS_NO,
             R.CONTROL_DATE,
             R.ATT_DOC_FLG,
             R.ACCEPT_DATE,
             RECEIVE.RETURN_NO,
             CASE
               WHEN RECEIVE.RETURN_NO = '0' THEN
                ''
               WHEN RECEIVE.RETURN_NO = '1' THEN
                '外包自動退文'
               WHEN RECEIVE.RETURN_NO = '2' THEN
                '查驗人員退領辦區'
               WHEN RECEIVE.RETURN_NO = '3' THEN
                '主管退辦'
               WHEN RECEIVE.RETURN_NO = '4' THEN
                '函稿作廢'
               WHEN RECEIVE.RETURN_NO = 'A' THEN
                '主管人工分辦'
               WHEN RECEIVE.RETURN_NO = 'B' THEN
                '查驗人員退人工分辦'
               WHEN RECEIVE.RETURN_NO = 'C' THEN
                '他科退辦'
               WHEN RECEIVE.RETURN_NO = 'D' THEN
                '一組二科紙本轉線上'
               WHEN RECEIVE.RETURN_NO = '5' THEN
                (select name_c from spm63 where processor_no = receive.object_id) ||
                ' 退承辦'
               WHEN RECEIVE.RETURN_NO = '6' THEN
                '函稿退辦'
               ELSE
                '其它原因'
             END return_reason,
             RECEIVE.PROCESS_DATE,
             CASE
              WHEN trim(post_reason) is null and IS_POSTPONE = '4' THEN
                '其它'
               WHEN IS_POSTPONE = '4' THEN
                post_reason --1:等來文、2:等規費、3:等圖檔 
               WHEN IS_POSTPONE = '1' THEN
                '等來文'
               WHEN IS_POSTPONE = '2' THEN
                '等規費'
               WHEN IS_POSTPONE = '3' THEN
                '等圖檔'
               ELSE
                post_reason
             END AS post_reason,
             (SELECT FEE_AMT
                FROM SPT13
               WHERE DATA_SEQ =
                     (SELECT MAX(DATA_SEQ)
                        FROM SPT13
                       WHERE SPT13.RECEIVE_NO = R.RECEIVE_NO)
                 AND SPT13.RECEIVE_NO = R.RECEIVE_NO) AS FEE_AMT,
             RECEIVE.merge_master,
             (select max(b.FORM_FILE_A)
                from spm56 b
               where b.RECEIVE_NO = s56.RECEIVE_NO
                 and b.processor_no = s56.processor_no
                 and s56.record_date > receive.process_date ) FORM_FILE_A
        FROM SPT21 R
        LEFT JOIN SPM75 T
          ON R.TYPE_NO = T.TYPE_NO
        JOIN RECEIVE
          ON R.RECEIVE_NO = RECEIVE.RECEIVE_NO
         AND R.APPL_NO = RECEIVE.APPL_NO
        LEFT JOIN SPM56 s56 
          ON s56.receive_no = R.receive_no
         and s56.processor_no = R.processor_no
         and s56.record_date >= RECEIVE.process_date
         LEFT JOIN ap.sptd02 sd02 ON s56.form_file_a = sd02.form_file_a 
       WHERE   RECEIVE.PROCESSOR_NO = p_in_proccess_no
         AND case when R.PROCESS_RESULT is null  AND RECEIVE.RECEIVE_NO is not null  then '2'
                  when  receive.step_code = '5' AND R.process_result != '57001' and substr(RECEIVE.processor_no,1,1) != 'P'  then '5'
                  when R.PROCESS_RESULT is not null AND R.process_result != '57001'  then '3'
                  end = p_in_code
         AND RECEIVE.step_code > '0'
         AND RECEIVE.step_code < '8'
         AND (s56.form_file_a is null or s56.form_file_a = (select max(form_file_a) from spm56 where s56.receive_no = spm56.receive_no and s56.processor_no = spm56.processor_no))
          ;
    return;
  END if;

  if p_in_type in ('TODO_P') then
    -- 紙本 公文
    OPEN p_out_list FOR
      SELECT R.RECEIVE_DATE,
             R.RECEIVE_NO,
             R.APPL_NO,
             R.TYPE_NO || ' ' || T.TYPE_NAME AS TYPE_NAME,
             R.TRANS_NO,
             SPT23.ACCEPT_DATE,
             R.CONTROL_DATE,
             '' post_reason,
             R.ONLINE_FLG, ---線上註記 
             (SELECT FEE_AMT
                FROM SPT13
               WHERE DATA_SEQ =
                     (SELECT MAX(DATA_SEQ)
                        FROM SPT13
                       WHERE SPT13.RECEIVE_NO = R.RECEIVE_NO)
                 AND SPT13.RECEIVE_NO = R.RECEIVE_NO) AS FEE_AMT
        FROM SPT21 R
        LEFT JOIN SPT23
          ON R.receive_no = SPT23.receive_no
         AND R.OBJECT_ID = Spt23.OBJECT_TO
        LEFT JOIN SPM75 T
          ON R.TYPE_NO = T.TYPE_NO
       WHERE SPT23.data_seq =
             (select max(data_seq)
                from spt23 s23
               where SPT23.receive_no = s23.receive_no)
         AND SPT23.ACCEPT_DATE IS NOT NULL
         AND PROCESS_RESULT IS  NULL
         AND R.object_id = p_in_proccess_no
         AND R.trans_no = '912'
          ;
  
    return;
  end if;

  if p_in_type in ('DONE_P') then
    -- 紙本 已銷號
    OPEN p_out_list FOR
      SELECT SPT21.RECEIVE_DATE,
             SPT21.RECEIVE_NO,
             SPT21.APPL_NO,
             SPT21.TYPE_NO,
             SPM75.TYPE_NAME,
             SPT21.PROCESSOR_NO,
             SPT21.ACCEPT_DATE,
             SPT21.TRANS_NO,
             SPT21.CONTROL_DATE,
             SPT21.PROCESS_RESULT,
              (SELECT FEE_AMT
                FROM SPT13
               WHERE DATA_SEQ =
                     (SELECT MAX(DATA_SEQ)
                        FROM SPT13
                       WHERE SPT13.RECEIVE_NO = SPT21.RECEIVE_NO)
                 AND SPT13.RECEIVE_NO = SPT21.RECEIVE_NO) AS FEE_AMT,
             SPT21.ONLINE_FLG, ---線上註記 
             '' post_reason
        FROM SPT21
        LEFT JOIN SPM75
          on SPT21.TYPE_NO = SPM75.TYPE_NO
        WHERE  NOT EXISTS (SELECT RECEIVE_NO FROM SPT41 WHERE RECEIVE_NO = SPT21.RECEIVE_NO and processor_no = SPT21.processor_no and check_datetime is not null)
         AND PROCESS_RESULT IS NOT NULL
         AND SPT21.object_id = p_in_proccess_no
         AND trans_no = '912'
         AND process_result != '57001'
         ;
    return;
  end if;

  if p_in_type in ('REJECTED_P') then
    -- 紙本 主管退辦
    OPEN p_out_list FOR
      SELECT SPT21.RECEIVE_DATE,
             SPT21.RECEIVE_NO,
             SPT21.APPL_NO,
             SPT21.TYPE_NO,
             SPM75.TYPE_NAME,
             SPT21.PROCESSOR_NO,
             SPT21.ACCEPT_DATE,
             SPT21.TRANS_NO,
             SPT21.CONTROL_DATE,
             SPT21.PROCESS_RESULT,
             SPT13.FEE_AMT,
             SPT21.ONLINE_FLG, ---線上註記 
             '' post_reason
        FROM spt21
        LEFT JOIN spt41
          on spt21.receive_no = spt41.receive_no
         AND spt41.appl_no = spt21.appl_no
        LEFT JOIN SPT23 a
          on a.receive_no = SPT21.receive_no
        LEFT JOIN SPT23 b
          on b.receive_no = SPT21.receive_no
        LEFT JOIN SPT13
          on SPT21.RECEIVE_NO = SPT13.RECEIVE_NO
        LEFT JOIN SPM75
          on SPT21.TYPE_NO = SPM75.TYPE_NO
       WHERE SPT21.PROCESS_RESULT IS NOT NULL --（銷號註記）
         AND SPT21.PROCESS_RESULT != '57001'
         AND spt21.object_id = p_in_proccess_no
         AND spt21.COMPLETE_DATE is null
         AND a.TRANS_NO in ('921', '922', '923')
         AND a.OBJECT_FROM in (SELECT b.processor_no
                                 from spm63 a
                                 join spm63 b
                                   on a.dept_no = b.dept_no
                                WHERE a.processor_no = p_in_proccess_no
                                  and b.title = '科長'
                                  and b.quit_date is null)
         AND b.TRANS_NO = '913'
         AND b.OBJECT_TO = p_in_proccess_no
         AND a.DATA_SEQ = b.DATA_SEQ + 1;
    return;
  end if;

  if p_in_type in ('NEW', 'APPEND') then
    -- 線上 新申請 後續文
    OPEN p_out_list FOR
      SELECT R.RECEIVE_DATE,
             R.RECEIVE_NO,
             R.APPL_NO,
             R.TYPE_NO || ' ' || T.TYPE_NAME AS TYPE_NAME,
             R.TRANS_NO,
             R.CONTROL_DATE,
             R.ATT_DOC_FLG,
             RECEIVE.RETURN_NO,
             CASE
               WHEN RECEIVE.RETURN_NO = '0' THEN
                ''
               WHEN RECEIVE.RETURN_NO = '1' THEN
                '外包退辦'
               WHEN RECEIVE.RETURN_NO = '2' THEN
                '查驗人員退辦'
               WHEN RECEIVE.RETURN_NO = '3' THEN
                '主管退辦'
               WHEN RECEIVE.RETURN_NO = '4' THEN
                '函稿作廢'
               WHEN RECEIVE.RETURN_NO = 'A' THEN
                '主管退人工分辦'
               WHEN RECEIVE.RETURN_NO = 'B' THEN
                '查驗人員退人工分辦'
               WHEN RECEIVE.RETURN_NO = 'C' THEN
                '他科退辦'
               WHEN RECEIVE.RETURN_NO = 'D' THEN
                '一組二科紙本轉線上'
               WHEN RECEIVE.RETURN_NO = '5' THEN
                '外包自動退文'
               WHEN RECEIVE.RETURN_NO = '6' THEN
                '函稿退辦'
               ELSE
                '其它原因'
             END return_reason,
             RECEIVE.PROCESS_DATE,
             CASE
              WHEN trim(post_reason) is null and IS_POSTPONE = '4' THEN
                '其它'
               WHEN IS_POSTPONE = '4' THEN
                post_reason --1:等來文、2:等規費、3:等圖檔 
               WHEN IS_POSTPONE = '1' THEN
                '等來文'
               WHEN IS_POSTPONE = '2' THEN
                '等規費'
               WHEN IS_POSTPONE = '3' THEN
                '等圖檔'
               ELSE
                post_reason
             END AS post_reason,
             (SELECT FEE_AMT
                FROM SPT13
               WHERE DATA_SEQ =
                     (SELECT MAX(DATA_SEQ)
                        FROM SPT13
                       WHERE SPT13.RECEIVE_NO = R.RECEIVE_NO)
                 AND SPT13.RECEIVE_NO = R.RECEIVE_NO) AS FEE_AMT,
             RECEIVE.merge_master
        FROM SPT21 R
        LEFT JOIN SPM75 T
          ON R.TYPE_NO = T.TYPE_NO
        JOIN RECEIVE
          ON RECEIVE.RECEIVE_NO = R.RECEIVE_NO
       WHERE RECEIVE.STEP_CODE = '0'
         AND R.process_result !='57001'
         AND doc_complete = '1'
         AND RETURN_NO not in ('4', 'A', 'B', 'C','D') -- 人工分辦
         AND SUBSTR(RECEIVE.RECEIVE_NO, 4, 1) = p_in_code;
    return;
  end if;

  if p_in_type in ('NEW_P', 'APPEND_P') then
    -- 紙本 新申請 後續文
    OPEN p_out_list FOR
      SELECT R.RECEIVE_DATE,
             R.RECEIVE_NO,
             R.APPL_NO,
             R.TYPE_NO || ' ' || T.TYPE_NAME AS TYPE_NAME,
             R.TRANS_NO,
             R.ACCEPT_DATE,
             R.CONTROL_DATE,
             '' post_reason,
             R.ONLINE_FLG, ---線上註記 
             (SELECT FEE_AMT
                FROM SPT13
               WHERE DATA_SEQ =
                     (SELECT MAX(DATA_SEQ)
                        FROM SPT13
                       WHERE SPT13.RECEIVE_NO = R.RECEIVE_NO)
                 AND SPT13.RECEIVE_NO = R.RECEIVE_NO) AS FEE_AMT
        FROM SPT21 R
        LEFT JOIN SPM75 T
          ON R.TYPE_NO = T.TYPE_NO
       WHERE SUBSTR(R.RECEIVE_NO, 4, 1) = p_in_code
         AND R.process_result != '57001'
         AND PROCESS_RESULT IS NULL
         AND R.object_id IN (SELECT PROCESSOR_NO
                                FROM SPM63
                               WHERE DEPT_NO = '70012'
                                 AND QUIT_DATE IS NULL);
    return;
  end if;

  if p_in_type in ('S_DIVIDE_R') then
    -- 人工分辦數
    OPEN p_out_list FOR
      SELECT R.RECEIVE_DATE,
             R.RECEIVE_NO,
             R.APPL_NO,
             R.TYPE_NO || ' ' || T.TYPE_NAME AS TYPE_NAME,
             R.TRANS_NO,
             R.CONTROL_DATE,
             R.ATT_DOC_FLG,
             R.ACCEPT_DATE,
             RECEIVE.RETURN_NO,
             CASE
               WHEN RECEIVE.RETURN_NO = '0' THEN
                ''
               WHEN RECEIVE.RETURN_NO = '1' THEN
                '外包退辦'
               WHEN RECEIVE.RETURN_NO = '2' THEN
                '查驗人員退辦'
               WHEN RECEIVE.RETURN_NO = '3' THEN
                '主管退辦'
               WHEN RECEIVE.RETURN_NO = '4' THEN
                '函稿作廢'
               WHEN RECEIVE.RETURN_NO = 'A' THEN
                '主管退人工分辦'
               WHEN RECEIVE.RETURN_NO = 'B' THEN
                '查驗人員退人工分辦'
               WHEN RECEIVE.RETURN_NO = 'C' THEN
                '他科退辦'
              WHEN RECEIVE.RETURN_NO = 'D' THEN
                '一組二科紙本轉線上'
               WHEN RECEIVE.RETURN_NO = '5' THEN
                '外包自動退文'
               WHEN RECEIVE.RETURN_NO = '6' THEN
                '函稿退辦'
               ELSE
                '其它原因'
             END return_reason,
             RECEIVE.PROCESS_DATE,
             CASE
               WHEN trim(post_reason) is null and IS_POSTPONE = '4' THEN
                '其它'
               WHEN IS_POSTPONE = '4' THEN
                post_reason --1:等來文、2:等規費、3:等圖檔 
               WHEN IS_POSTPONE = '1' THEN
                '等來文'
               WHEN IS_POSTPONE = '2' THEN
                '等規費'
               WHEN IS_POSTPONE = '3' THEN
                '等圖檔'
               ELSE
                post_reason
             END AS post_reason,
             (SELECT FEE_AMT
                FROM SPT13
               WHERE DATA_SEQ =
                     (SELECT MAX(DATA_SEQ)
                        FROM SPT13
                       WHERE SPT13.RECEIVE_NO = R.RECEIVE_NO)
                 AND SPT13.RECEIVE_NO = R.RECEIVE_NO) AS FEE_AMT,
             RECEIVE.merge_master
        FROM SPT21 R
        LEFT JOIN SPM75 T
          ON R.TYPE_NO = T.TYPE_NO
        JOIN RECEIVE
          ON R.RECEIVE_NO = RECEIVE.RECEIVE_NO
         AND R.APPL_NO = RECEIVE.APPL_NO
       WHERE return_no in ('4', 'A', 'B', 'C','D')
         AND R.process_result != '57001'
         AND step_code = '0'
         AND RECEIVE.PROCESSOR_NO IN
             (SELECT PROCESSOR_NO
                FROM SPM63
               WHERE DEPT_NO = '70012'
                 AND QUIT_DATE IS NULL
                  OR (PROCESSOR_NO = '70012' ));
    return;
  end if;
  ---------------------------------------
  -- 待核公文 
  ---------------------------------------
  if p_in_type in ('S_TO_APPROVE') then
    OPEN p_out_list FOR
    
    /*  SELECT R.RECEIVE_DATE,
                                     R.RECEIVE_NO,
                                     R.APPL_NO,
                                     s63.name_c, -- 承辦人
                                     R.TYPE_NO || ' ' || T.TYPE_NAME AS TYPE_NAME,
                                     R.TRANS_NO,
                                     R.CONTROL_DATE,
                                     R.ATT_DOC_FLG,
                                     R.ACCEPT_DATE,
                                     RECEIVE.PROCESS_DATE,
                                     (SELECT FEE_AMT
                                        FROM SPT13
                                       WHERE DATA_SEQ =
                                             (SELECT MAX(DATA_SEQ)
                                                FROM SPT13
                                               WHERE SPT13.RECEIVE_NO = R.RECEIVE_NO)
                                         AND SPT13.RECEIVE_NO = R.RECEIVE_NO) AS FEE_AMT,
                                     RECEIVE.merge_master,
                                     SPM56.form_file_a
                                FROM SPT21 R
                                LEFT JOIN SPM75 T
                                  ON R.TYPE_NO = T.TYPE_NO
                                LEFT JOIN SPM63 s63
                                  ON R.processor_no = s63.processor_no
                                JOIN RECEIVE
                                  ON R.RECEIVE_NO = RECEIVE.RECEIVE_NO
                                JOIN spm56
                                  on SPM56.receive_no = R.receive_no
                                 and spm56.processor_no = R.processor_no
                                 and SPM56.form_file_a =
                                     (select max(form_file_a)
                                        from spm56 s56
                                       where SPM56.receive_no = s56.receive_no)
                               WHERE nvl(spm56.issue_flag, '0') = '1' -- 已製稿
                                 AND nvl(ONLINE_SIGN, '0') != '1' --紙本
                                 AND R.trans_no = '921'
                              UNION ALL */
      SELECT R.RECEIVE_DATE,
             R.RECEIVE_NO,
             R.APPL_NO,
             s63.name_c, -- 承辦人
             R.TYPE_NO || ' ' || T.TYPE_NAME AS TYPE_NAME,
             R.TRANS_NO,
             R.CONTROL_DATE,
             R.ATT_DOC_FLG,
             R.ACCEPT_DATE,
             RECEIVE.PROCESS_DATE,
             (SELECT FEE_AMT
                FROM SPT13
               WHERE DATA_SEQ =
                     (SELECT MAX(DATA_SEQ)
                        FROM SPT13
                       WHERE SPT13.RECEIVE_NO = R.RECEIVE_NO)
                 AND SPT13.RECEIVE_NO = R.RECEIVE_NO) AS FEE_AMT,
             RECEIVE.merge_master,
             SPM56.form_file_a
        FROM SPT21 R
        LEFT JOIN SPM75 T
          ON R.TYPE_NO = T.TYPE_NO
        LEFT JOIN SPM63 s63
          ON R.processor_no = s63.processor_no
        JOIN RECEIVE
          ON R.RECEIVE_NO = RECEIVE.RECEIVE_NO
         AND R.APPL_NO = RECEIVE.APPL_NO
        JOIN SPM56
          on SPM56.receive_no = R.receive_no
         and SPM56.processor_no = R.processor_no
         and SPM56.form_file_a =
             (select max(form_file_a)
                from spm56 s56
               where SPM56.receive_no = s56.receive_no)
        LEFT JOIN ap.SPTD02
          on SPM56.form_file_a = SPTD02.form_file_a
       WHERE nvl(ONLINE_SIGN, '0') = '1'
         and R.process_result != '57001'
         and nvl(SPM56.issue_flag, '0') = '1'
         and sptd02.flow_step = '02'
         AND substr(R.processor_no, 1, 1) != 'P'
      union all
      SELECT spm56.record_date RECEIVE_DATE,
             ' ' RECEIVE_NO,
             R.APPL_NO,
             s63.name_c, -- 承辦人
             T.TYPE_NO || ' ' || T.TYPE_NAME AS TYPE_NAME,
             '' TRANS_NO,
             '' CONTROL_DATE,
             '' ATT_DOC_FLG,
             '' ACCEPT_DATE,
             '' PROCESS_DATE,
             0 AS FEE_AMT,
             '' merge_master,
             SPM56.form_file_a
        FROM APPL R
        LEFT JOIN SPM63 s63
          ON R.processor_no = s63.processor_no
        JOIN SPM56
          on SPM56.APPL_NO = R.APPL_NO
         and SPM56.processor_no = R.processor_no
         and SPM56.form_file_a =
             (select max(form_file_a)
                from spm56 s56
               where SPM56.appl_no = s56.appl_no)
        LEFT JOIN ap.SPTD02
          on SPM56.form_file_a = SPTD02.form_file_a
        LEFT JOIN SPM75 T
          ON spm56.type_no = T.TYPE_NO
       WHERE nvl(ONLINE_SIGN, '0') = '1'
         and nvl(SPM56.issue_flag, '0') = '1'
         and sptd02.flow_step = '02'
         and substr(s63.processor_no, 1, 1) != 'P';
    return;
  end if;

  if p_in_type = 'S_TO_EXCEED' then
    -- 將逾期
    OPEN p_out_list FOR
      SELECT R.RECEIVE_DATE,
             R.RECEIVE_NO,
             R.APPL_NO,
             R.TYPE_NO || ' ' || T.TYPE_NAME AS TYPE_NAME,
             R.TRANS_NO,
             R.CONTROL_DATE,
             R.ATT_DOC_FLG,
             R.ACCEPT_DATE,
             RECEIVE.RETURN_NO,
             CASE
               WHEN RECEIVE.RETURN_NO = '0' THEN
                ''
               WHEN RECEIVE.RETURN_NO = '1' THEN
                '外包自動退文'
               WHEN RECEIVE.RETURN_NO = '2' THEN
                '查驗人員退領辦區'
               WHEN RECEIVE.RETURN_NO = '3' THEN
                '主管退辦'
               WHEN RECEIVE.RETURN_NO = '4' THEN
                '函稿作廢'
               WHEN RECEIVE.RETURN_NO = 'A' THEN
                '主管人工分辦'
               WHEN RECEIVE.RETURN_NO = 'B' THEN
                '查驗人員退人工分辦'
               WHEN RECEIVE.RETURN_NO = 'C' THEN
                '他科退辦'
               WHEN RECEIVE.RETURN_NO = 'D' THEN
                '一組二科紙本轉線上'
               WHEN RECEIVE.RETURN_NO = '5' THEN
                (select name_c from spm63 where processor_no = receive.object_id) ||
                ' 退承辦'
               WHEN RECEIVE.RETURN_NO = '6' THEN
                '函稿退辦'
               ELSE
                '其它原因'
             END return_reason,
             RECEIVE.PROCESS_DATE,
             CASE
              WHEN trim(post_reason) is null and IS_POSTPONE = '4' THEN
                '其它'
               WHEN IS_POSTPONE = '4' THEN
                post_reason --1:等來文、2:等規費、3:等圖檔 
               WHEN IS_POSTPONE = '1' THEN
                '等來文'
               WHEN IS_POSTPONE = '2' THEN
                '等規費'
               WHEN IS_POSTPONE = '3' THEN
                '等圖檔'
               ELSE
                post_reason
             END AS post_reason,
             (SELECT FEE_AMT
                FROM SPT13
               WHERE DATA_SEQ =
                     (SELECT MAX(DATA_SEQ)
                        FROM SPT13
                       WHERE SPT13.RECEIVE_NO = R.RECEIVE_NO)
                 AND SPT13.RECEIVE_NO = R.RECEIVE_NO) AS FEE_AMT,
             RECEIVE.merge_master,
             (select max(b.FORM_FILE_A)
                from spm56 b
               where b.RECEIVE_NO = s56.RECEIVE_NO
                 and b.processor_no = s56.processor_no) FORM_FILE_A
        FROM receive
        join spt21 R
          On receive.receive_no = R.receive_no
        LEFT JOIN SPM75 T
          ON R.TYPE_NO = T.TYPE_NO
        LEFT JOIN SPM56 s56
          ON s56.receive_no = R.receive_no
         and s56.processor_no = R.processor_no
         and s56.issue_flag = '1'
        LEFT JOIN (SELECT row_number() over(partition by spt21.receive_no order by date_chinese desc) d,
                          spt21.control_date,
                          SPSB36.date_bc,
                          spt21.receive_no
                     FROM spt21
                     join ap.SPSB36
                       on SPSB36.date_bc <
                          to_number(substr(spt21.control_date, 1, 3)) + 1911 ||
                          substr(spt21.control_date, 4, 4)
                     JOIN receive
                       on spt21.receive_no = receive.receive_no
                    WHERE SPSB36.date_flag = 1
                      AND receive.processor_no IN
                          (SELECT PROCESSOR_NO
                             FROM SPM63
                            WHERE DEPT_NO = '70012'
                              AND QUIT_DATE IS NULL)) cdate
          on cdate.receive_no = receive.receive_no
       WHERE receive.step_code >= '2'
         AND receive.step_code < '8'
         AND R.process_result != '57001'
         AND cdate.d = 2
            --  AND  substr(to_char(to_number(receive.process_date) + 19110000),1,6)  = to_char(sysdate,'yyyyMM')
         AND to_char(sysdate, 'yyyyMMdd') between cdate.date_bc and
             to_number(substr(R.control_date, 1, 3)) + 1911 ||
             substr(R.control_date, 4, 4)
         AND step_code < '4'
         AND RECEIVE.PROCESSOR_NO = p_in_proccess_no;
    return;
  END if;

  if p_in_type = 'S_FOR_APPROVE' then
    -- 陳核中
    OPEN p_out_list FOR
      SELECT R.RECEIVE_DATE,
             R.RECEIVE_NO,
             R.APPL_NO,
             R.TYPE_NO || ' ' || T.TYPE_NAME AS TYPE_NAME,
             R.TRANS_NO,
             R.CONTROL_DATE,
             R.ATT_DOC_FLG,
             R.ACCEPT_DATE,
             RECEIVE.RETURN_NO,
             CASE
               WHEN RECEIVE.RETURN_NO = '0' THEN
                ''
               WHEN RECEIVE.RETURN_NO = '1' THEN
                '外包自動退文'
               WHEN RECEIVE.RETURN_NO = '2' THEN
                '查驗人員退領辦區'
               WHEN RECEIVE.RETURN_NO = '3' THEN
                '主管退辦'
               WHEN RECEIVE.RETURN_NO = '4' THEN
                '函稿作廢'
               WHEN RECEIVE.RETURN_NO = 'A' THEN
                '主管人工分辦'
               WHEN RECEIVE.RETURN_NO = 'B' THEN
                '查驗人員退人工分辦'
               WHEN RECEIVE.RETURN_NO = 'C' THEN
                '他科退辦'
               WHEN RECEIVE.RETURN_NO = 'D' THEN
                '一組二科紙本轉線上'
               WHEN RECEIVE.RETURN_NO = '5' THEN
                (select name_c from spm63 where processor_no = receive.object_id) ||
                ' 退承辦'
               WHEN RECEIVE.RETURN_NO = '6' THEN
                '函稿退辦'
               ELSE
                '其它原因'
             END return_reason,
             RECEIVE.PROCESS_DATE,
             CASE
               WHEN trim(post_reason) is null and IS_POSTPONE = '4' THEN
                '其它'
               WHEN IS_POSTPONE = '4' THEN
                post_reason --1:等來文、2:等規費、3:等圖檔 
               WHEN IS_POSTPONE = '1' THEN
                '等來文'
               WHEN IS_POSTPONE = '2' THEN
                '等規費'
               WHEN IS_POSTPONE = '3' THEN
                '等圖檔'
               ELSE
                post_reason
             END AS post_reason,
             (SELECT FEE_AMT
                FROM SPT13
               WHERE DATA_SEQ =
                     (SELECT MAX(DATA_SEQ)
                        FROM SPT13
                       WHERE SPT13.RECEIVE_NO = R.RECEIVE_NO)
                 AND SPT13.RECEIVE_NO = R.RECEIVE_NO) AS FEE_AMT,
             RECEIVE.merge_master,
             (select max(b.FORM_FILE_A)
                from spm56 b
               where b.RECEIVE_NO = s56.RECEIVE_NO
                 and b.processor_no = s56.processor_no) FORM_FILE_A
        FROM receive
        join spt21 R
          On receive.receive_no = R.receive_no
        LEFT JOIN SPM75 T
          ON R.TYPE_NO = T.TYPE_NO
        LEFT JOIN SPM56 s56
          ON s56.receive_no = R.receive_no
         and s56.processor_no = R.processor_no
         and s56.issue_flag = '1'
        LEFT JOIN (SELECT row_number() over(partition by spt21.receive_no order by date_chinese desc) d,
                          spt21.control_date,
                          SPSB36.date_bc,
                          spt21.receive_no
                     FROM spt21
                     join ap.SPSB36
                       on SPSB36.date_bc <
                          to_number(substr(spt21.control_date, 1, 3)) + 1911 ||
                          substr(spt21.control_date, 4, 4)
                     JOIN receive
                       on spt21.receive_no = receive.receive_no
                    WHERE SPSB36.date_flag = 1
                      AND receive.processor_no IN
                          (SELECT PROCESSOR_NO
                             FROM SPM63
                            WHERE DEPT_NO = '70012'
                              AND QUIT_DATE IS NULL)) cdate
          on cdate.receive_no = receive.receive_no
       WHERE receive.step_code >= '2'
         AND receive.step_code < '8'
         AND R.process_result != '57001'
         AND cdate.d = 2
            --  AND  substr(to_char(to_number(receive.process_date) + 19110000),1,6)  = to_char(sysdate,'yyyyMM')
         AND to_char(sysdate, 'yyyyMMdd') between cdate.date_bc and
             to_number(substr(R.control_date, 1, 3)) + 1911 ||
             substr(R.control_date, 4, 4)
         and step_code = '4'
         AND RECEIVE.PROCESSOR_NO = p_in_proccess_no;
    return;
  END if;

  if p_in_type = 'S_EXCEEDED' then
    -- 已逾期
    OPEN p_out_list FOR
      SELECT R.RECEIVE_DATE,
             R.RECEIVE_NO,
             R.APPL_NO,
             R.TYPE_NO || ' ' || T.TYPE_NAME AS TYPE_NAME,
             R.TRANS_NO,
             R.CONTROL_DATE,
             R.ATT_DOC_FLG,
             R.ACCEPT_DATE,
             RECEIVE.RETURN_NO,
             CASE
               WHEN RECEIVE.RETURN_NO = '0' THEN
                ''
               WHEN RECEIVE.RETURN_NO = '1' THEN
                '外包自動退文'
               WHEN RECEIVE.RETURN_NO = '2' THEN
                '查驗人員退領辦區'
               WHEN RECEIVE.RETURN_NO = '3' THEN
                '主管退辦'
               WHEN RECEIVE.RETURN_NO = '4' THEN
                '函稿作廢'
               WHEN RECEIVE.RETURN_NO = 'A' THEN
                '主管人工分辦'
               WHEN RECEIVE.RETURN_NO = 'B' THEN
                '查驗人員退人工分辦'
               WHEN RECEIVE.RETURN_NO = 'C' THEN
                '他科退辦'
               WHEN RECEIVE.RETURN_NO = 'D' THEN
                '一組二科紙本轉線上'
               WHEN RECEIVE.RETURN_NO = '5' THEN
                (select name_c from spm63 where processor_no = receive.object_id) ||
                ' 退承辦'
               WHEN RECEIVE.RETURN_NO = '6' THEN
                '函稿退辦'
               ELSE
                '其它原因'
             END return_reason,
             RECEIVE.PROCESS_DATE,
             CASE
              WHEN trim(post_reason) is null and IS_POSTPONE = '4' THEN
                '其它'
               WHEN IS_POSTPONE = '4' THEN
                post_reason --1:等來文、2:等規費、3:等圖檔 
               WHEN IS_POSTPONE = '1' THEN
                '等來文'
               WHEN IS_POSTPONE = '2' THEN
                '等規費'
               WHEN IS_POSTPONE = '3' THEN
                '等圖檔'
               ELSE
                post_reason
             END AS post_reason,
             (SELECT FEE_AMT
                FROM SPT13
               WHERE DATA_SEQ =
                     (SELECT MAX(DATA_SEQ)
                        FROM SPT13
                       WHERE SPT13.RECEIVE_NO = R.RECEIVE_NO)
                 AND SPT13.RECEIVE_NO = R.RECEIVE_NO) AS FEE_AMT,
             RECEIVE.merge_master,
             (select max(b.FORM_FILE_A)
                from spm56 b
               where b.RECEIVE_NO = s56.RECEIVE_NO
                 and b.processor_no = s56.processor_no) FORM_FILE_A
        FROM receive
        join spt21 R
          On receive.receive_no = R.receive_no
        LEFT JOIN SPM75 T
          ON R.TYPE_NO = T.TYPE_NO
        LEFT JOIN SPM56 s56
          ON s56.receive_no = R.receive_no
         and s56.processor_no = R.processor_no
         and s56.issue_flag = '1'
        LEFT JOIN (SELECT row_number() over(partition by spt21.receive_no order by date_chinese desc) d,
                          spt21.control_date,
                          SPSB36.date_bc,
                          spt21.receive_no
                     FROM spt21
                     join ap.SPSB36
                       on SPSB36.date_bc <
                          to_number(substr(spt21.control_date, 1, 3)) + 1911 ||
                          substr(spt21.control_date, 4, 4)
                     JOIN receive
                       on spt21.receive_no = receive.receive_no
                    WHERE SPSB36.date_flag = 1
                      AND receive.processor_no IN
                          (SELECT PROCESSOR_NO
                             FROM SPM63
                            WHERE DEPT_NO = '70012'
                              AND QUIT_DATE IS NULL)) cdate
          on cdate.receive_no = receive.receive_no
       WHERE receive.step_code >= '2'
         AND receive.step_code < '8'
         AND R.process_result != '57001'
         AND cdate.d = 2
            --  AND substr(to_char(to_number(receive.process_date) + 19110000),1,6)  = to_char(sysdate,'yyyyMM')
         AND to_char(sysdate, 'yyyyMMdd') >
             to_number(substr(R.control_date, 1, 3)) + 1911 ||
             substr(R.control_date, 4, 4)
         AND RECEIVE.PROCESSOR_NO = p_in_proccess_no;
    return;
  END if;

  if p_in_type = 'S_IMG_NOT_READY' then
    -- 逾期影像未到之線上公文
    OPEN p_out_list FOR
    
     SELECT spt21.receive_no,
             spt21.appl_no,
             spt21.receive_date,
             spt21.type_no || ' ' || spm75.type_name type_no ,
             spm63.name_c object_id,
             spt21.dept_no
        FROM spt21
        join ap.SPSB36
          on SPSB36.date_bc > to_number(substr(spt21.RECEIVE_DATE, 1, 3)) + 1911 ||
             substr(spt21.RECEIVE_DATE, 4, 4)
       left join spm75 on spm75.type_no = spt21.type_no
       left join spm63 on spm63.processor_no =  spt21.processor_no
       WHERE SPSB36.date_flag = 1
         and SPSB36.date_bc <= to_char(sysdate, 'yyyyMMdd')
         and spt21.online_flg = 'Y'
         and spt21.dept_no = '70012'
         and spt21.process_result != '57001'
         and exists (select 1
                from receive
               where receive.receive_no = spt21.receive_no
                 and doc_complete = '0'
                 and is_postpone = '0')
       group by spt21.receive_no,
                spt21.appl_no,
                spt21.receive_date,
                spt21.type_no || ' ' || spm75.type_name   ,
                spm63.name_c ,
                spt21.dept_no
      having count(1) > 7;
  
    return;
  END if;

  if p_in_type = 'S_NOT_SECTION' then
    -- 持有者都不是 70012/70014 之線上公文
    OPEN p_out_list FOR
      select spt21.receive_no,
             spt21.appl_no,
             spt21.receive_date,
            (select type_no || ' ' || type_name from spm75 where type_no = spt21.type_no) type_no ,
            (select name_c from spm63 where processor_no =  spt21.processor_no  )object_id,
            (select dept_no from spm63 where processor_no =  spt21.processor_no) dept_no
        from spt21
       where online_flg = 'Y'
         and spt21.process_result != '57001'
         and processor_no not in
             (select processor_no
                from spm63
               where dept_no in ('70012', '70014')
                 and quit_date is null)
         and processor_no not in ('70012', '70014');
    return;
  END if;

  raise_application_error(-20001,
                          'please check your p_in_type parameter, maybe not in LIST_VIEW procedure!');

end LIST_VIEW;

/
--------------------------------------------------------
--  DDL for Procedure PROCESSOR_TO_PROCESSOR
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."PROCESSOR_TO_PROCESSOR" (p_in_receive_no   in char,
                                               p_in_processor_no in char) is
begin
/*  
Modify: 2015/05/08
   科長退承辦:同案號之公文全部一起退
    將公文移出此批號,修改承辦人為指定承辦人, 公文狀態改為:待辦
     (1) update  step_code = 2 processor_no = ?
*/
  update receive
     Set processor_no = trim(p_in_processor_no), step_code = '2'
   Where  receive_no = p_in_receive_no;
   
    update spt21
     Set processor_no = trim(p_in_processor_no) 
    Where  receive_no = p_in_receive_no;
    

  

end PROCESSOR_TO_PROCESSOR;

/
--------------------------------------------------------
--  DDL for Procedure QUOTA_MAIN
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."QUOTA_MAIN" (p_in_year      in number,
                                       p_out_years    out sys_refcursor,
                                       p_out_workdays out sys_refcursor,
                                       p_out_list     out sys_refcursor) is
  g_year number(4);
begin

  --取得大於今年的工作天年份

  open p_out_years for
    SELECT YEAR FROM WORKDAYS WHERE YEAR >= EXTRACT(YEAR FROM SYSDATE);

  --  輸入年度若不在範圍內則使用最小年度(今年)

  SELECT CASE
           WHEN p_in_year BETWEEN MIN(YEAR) AND MAX(YEAR) THEN
            p_in_year
           ELSE
            MIN(YEAR)
         END
    INTO g_year
    FROM WORKDAYS
   WHERE YEAR >= EXTRACT(YEAR FROM SYSDATE);

  if g_year is null then
  
    raise_application_error(-20001,
                            'workdays can not be empty , please checkout SPMFF table!');
  end if;

  --  取得工作天

  open p_out_workdays for
    SELECT YEAR, JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC
      FROM WORKDAYS
     WHERE YEAR = g_year;

  -- preload

  insert into quota
    select processor_no, mm, factor, yyyy
      from spm63,
           (select g_year as yyyy,
                   trim(to_char(level, '00')) mm,
                   0 as factor
              from dual
            connect by level <= 12)
     where dept_no = '70012'
       and quit_date is null
       and yyyy = g_year
       and processor_no not in
           (select distinct processor_no from quota where yyyy = g_year);

  insert into quota_base
    select processor_no, 0, g_year as yyyy
      from spm63
     where dept_no = '70012'
       and quit_date is null
       and processor_no not in
           (select distinct processor_no from quota_base where yyyy = g_year);

  --應辦案件數           

  open p_out_list for
    SELECT PROCESSOR_NO,
           NAME_C,
           BASE,
           "JAN",
           "FEB",
           "MAR",
           "APR",
           "MAY",
           "JUN",
           "JUL",
           "AUG",
           "SEP",
           "OCT",
           "NOV",
           "DEC"
      FROM (SELECT S.PROCESSOR_NO, S.NAME_C, A.YYYY, A.MM, B.BASE, FACTOR
              FROM QUOTA A,
                   QUOTA_BASE B,
                   SPM63 S,
                   (SELECT SUBSTR(DATE_BC, 1, 4) AS YYYY,
                           SUBSTR(DATE_BC, 5, 2) AS MM,
                           SUM(DATE_FLAG) AS WORKDAY
                      FROM SPMFF
                     GROUP BY SUBSTR(DATE_BC, 1, 4), SUBSTR(DATE_BC, 5, 2)) W
             WHERE A.PROCESSOR_NO = B.PROCESSOR_NO
               AND A.YYYY = B.YYYY
               AND A.PROCESSOR_NO = S.PROCESSOR_NO
               AND A.YYYY = W.YYYY
               AND A.MM = W.MM
               AND A.YYYY = g_year) PIVOT(SUM(FACTOR) FOR MM IN('01' AS JAN,
                                                                '02' AS FEB,
                                                                '03' AS MAR,
                                                                '04' AS APR,
                                                                '05' AS MAY,
                                                                '06' AS JUN,
                                                                '07' AS JUL,
                                                                '08' AS AUG,
                                                                '09' AS SEP,
                                                                '10' AS OCT,
                                                                '11' AS NOV,
                                                                '12' AS DEC))
     ORDER BY PROCESSOR_NO;

end quota_main;

/
--------------------------------------------------------
--  DDL for Procedure QUOTA_SAVE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."QUOTA_SAVE" (p_in_value        in varchar2,
                                       p_in_processor_no in char,
                                       p_in_year         in varchar2,
                                       p_in_month        in varchar2) is

begin

  --儲存基數 
  if p_in_month = '00' then
    UPDATE QUOTA_BASE
       SET BASE = p_in_value
     WHERE PROCESSOR_NO = p_in_processor_no
       AND YYYY = p_in_year;
  else
    --儲存應辦案件數
    UPDATE QUOTA
       SET FACTOR = p_in_value
     WHERE PROCESSOR_NO = p_in_processor_no
       AND YYYY = p_in_year
       AND MM = p_in_month;
  end if;

end quota_save;

/
--------------------------------------------------------
--  DDL for Procedure RECEIVE_TRANSFER
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."RECEIVE_TRANSFER" (v_direct in char,v_receive_no in varchar,v_step_code in varchar) 
IS 
    l_cnt number;    
    l_badNo number;
    l_isPass  char;
    l_standard char;
BEGIN
/*--------------------------------
 For Test
----------------------------------*/
   IF v_direct = '1' THEN  -- paper to online
      update spt21 set online_flg = 'Y', online_cout = 'Y'  where receive_no = v_receive_no;
      Insert into receive
      Select spt21.receive_no,appl_no , trim(v_step_code),
        '0', '1', '1',null,null,0,0,0,
        case when trim(v_step_code) = '0' then null else processor_no end,
        object_id,null,null,NULL
      From SPT21
      Where receive_no = v_receive_no;
   END IF;
   
   IF v_direct = '2' THEN  --  online to paper 
      update spt21 set online_flg = 'N', online_cout = 'N'  where receive_no = v_receive_no;
      delete receive
           Where receive_no = v_receive_no;
   END IF;
  
    dbms_output.put_line('Finish');
EXCEPTION
  WHEN OTHERS THEN
  
    dbms_output.put_line('Error Code:' ||  SQLCODE || ' : ' || SQLERRM);   
     
END RECEIVE_TRANSFER;

/
--------------------------------------------------------
--  DDL for Procedure RECEIVE193
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."RECEIVE193" ( p_rec out int)
IS 
    l_cnt number;    
    l_badNo number;
    l_isPass  char;
    l_standard char;
    l_where varchar2(1000);
    l_out_msg    varchar2(100);
BEGIN
/*--------------------------------
 Modify Date : 2015/09/14
 Get Recive from 190
 (1) get receive data from spt21 where  online_flg = Y  and online_cout = 'N' and 090  picture file is ready
 (2) update online_cout =Y where  online_flg = Y  and online_cout = 'N' and   090 picture file is ready  
 (3) when 1,2 ready, get receive from 190 to 193
 (4) record receive transfer history
 (5) check_receive add parameter
 (6) 6/2  change receive_trans_log schema
 (7) 6/3  error reporting check
 (8) 6/24 add new project from spt31 to appl
 (9) 104/08/05  add condition  spt21.dept_no = '70012'
 (10) 104/08/07 cancel to check image has getted
 (11) 104/09/09 exclude the receives which process_result = 57001
 (12) 104/09/14 add to receive_log
----------------------------------*/
    -- check picture file is ready 
    -- get to 193
    select count(1) into p_rec
    FROM SPT21 LEFT JOIN RECEIVE on SPT21.receive_no = RECEIVE.receive_no
    WHERE online_flg = 'Y' and online_cout = 'N'
    AND dept_no = '70012'
    AND receive.receive_no is null
    AND spt21.appl_no is not null
    AND ( spt21.process_result != '57001' or spt21.process_result is null)
     ;
    
    
     INSERT into receive
    SELECT spt21.receive_no,
           spt21.appl_no , 
           '0' as step_code,
           '0' as is_postpone, 
           '1' as img_complete, 
           '1' as rec_complete,
           null as sign_date,
           null as merge_master,
           '0' as unusual,
           '0' as doc_complete,
           '0' as return_no,
           '70012' as processor_no, 
           '' object_id,
           null as process_result,
           null as receive_date ,
           null as ACCEPT_DATE
    FROM SPT21 LEFT JOIN RECEIVE on SPT21.receive_no = RECEIVE.receive_no
    WHERE online_flg = 'Y' and online_cout = 'N'
    AND dept_no = '70012'
    AND receive.receive_no is null
    AND spt21.appl_no is not null
    AND ( spt21.process_result != '57001' or spt21.process_result is null)
     ;
    
    dbms_output.put_line('total records:' || p_rec);   
  
    ---------------------
    -- record receive transfer history
    ---------------------
      INSERT INTO RECEIVE_TRANS_LOG
     SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = spt21.receive_no ),'1') seq , 
              spt21.receive_no, spt21.appl_no , '70012','0',sysdate,'190寫入193'
      from spt21
      WHERE online_flg = 'Y' and online_cout = 'N' AND dept_no = '70012'
      AND spt21.appl_no is not null
      AND ( spt21.process_result != '57001' or spt21.process_result is null)
    ;
    -----------------
    -- add to dblog
    ----------------
    /*
    l_where :=
      ' WHERE receive_no in ( select receive_no from spt21 where online_flg = ''Y'' and online_cout = ''N'' AND dept_no = ''70012'' ' ||
      ' AND spt21.appl_no is not null ' ||
      ' AND ( spt21.process_result != ''57001'' or spt21.process_result is null)) '
      ;
    DBLog_193('sys','I','receive',l_where);
    */
   
  dbms_output.put_line('write to log');
     --  must modify the condition when checking the file is ready
    UPDATE spt21 set online_cout = 'Y',processor_no = '70012' 
    WHERE online_flg = 'Y' and online_cout = 'N' AND dept_no = '70012'
    AND spt21.appl_no is not null
    AND ( spt21.process_result != '57001' or spt21.process_result is null)
     ;
     commit;
     dbms_output.put_line('update spt21 online_cout and processor_no');
  
    ----------------
    -- prepare for get receive
    ----------------
 --   CHECK_RECEIVE('1',l_out_msg);
--    dbms_output.put_line(l_out_msg);
  --  commit;

    ---------------------------------------
    -- add new project from spt31 to appl
    ----------------------------------------
   
     insert into appl(APPL_NO,STEP_CODE,DIVIDE_CODE,DIVIDE_REASON,FINISH_FLAG,
                       RETURN_NO,IS_OVERTIME,PROCESS_DATE,PROCESSOR_NO)
  select appl_no, '1','0',null,'0','0','0',null,sch_processor_no
  from spt31 
  where not exists (select 1 from appl where appl.appl_no = spt31.appl_no)
  ;
   /*
  update appl set processor_no = ( select sch_processor_no from spt31 s31 where s31.appl_no = appl.appl_no )
  where appl_no in (select appl_no from spt31 where spt31.appl_no = appl.appl_no and spt31.sch_processor_no != appl.processor_no)
  and appl.is_overtime = '0' and divide_code = '0';
  */
  commit;
 --  p_rec := SQL%RowCount;
   
EXCEPTION
  WHEN OTHERS THEN
  
    dbms_output.put_line('Error Code:' ||  SQLCODE || ' : ' || SQLERRM);   
     
END RECEIVE193;

/
--------------------------------------------------------
--  DDL for Procedure REQUEST_FOR_IMAGES
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."REQUEST_FOR_IMAGES" (p_in_receive_no   in char,
                                           p_in_processor_no in char,
                                           p_in_step_code    in char,                                           
                                           p_out_msg         out varchar2) is
  v_count      number;
begin
  /*
  SELECT COUNT(1)
    INTO v_count
    FROM RECEIVE
   WHERE step_code=p_in_step_code and PROCESS_DATE<to_char(to_char(add_months(sysdate,-6), 'yyyyMMdd') - 19110000);
   
  if v_count > 0 then
    --刪除超過半年影像檔請求
    delete from RECEIVE WHERE step_code=p_in_step_code and PROCESS_DATE<to_char(to_char(add_months(sysdate,-6), 'yyyyMMdd') - 19110000);
  end if;
  */
  --檢查 SPT21是否有相同收文文號
  SELECT COUNT(1)
    INTO v_count
    FROM SPT21
   WHERE RECEIVE_NO = p_in_receive_no;  
  
  if v_count = 0 then
      p_out_msg := '收文文號錯誤或不存在';
  else

    --檢查 RECEIVE是否有相同收文文號
    SELECT COUNT(1)
    INTO v_count
    FROM doc
    WHERE RECEIVE_NO = p_in_receive_no;

    if v_count > 0 then
      --有相同收文文號,結束
      p_out_msg := '影像檔已存在!若影像檔依然不存在，請聯絡管理員!';
      
      SYS.Dbms_Output.Put_Line(p_out_msg);
      return;
    end if;  
    
    
    --檢查 RECEIVE是否有相同收文文號
    SELECT COUNT(1)
    INTO v_count
    FROM RECEIVE
    WHERE RECEIVE_NO = p_in_receive_no;
       
    if v_count > 0 then
      --有相同收文文號,結束
      SELECT COUNT(1)
      INTO v_count
      FROM RECEIVE
      WHERE RECEIVE_NO = p_in_receive_no and doc_complete='1';
      
      if v_count > 0 then
        p_out_msg := '影像檔已到齊';
      else
        p_out_msg := '重複向申請案件管理系統調閱影像檔';
      end if;
      
    else
      --無相同收文文號，新增
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = SPT21.receive_no ),'1') seq , 
          SPT21.receive_no, SPT21.appl_no , SPT21.processor_no,trim(p_in_step_code),sysdate,'請求影像檔'
      from SPT21
      Where　RECEIVE_NO = p_in_receive_no;
  
      INSERT INTO RECEIVE(RECEIVE_NO,APPL_NO,STEP_CODE,PROCESSOR_NO,OBJECT_ID,PROCESS_DATE)
      SELECT RECEIVE_NO,
           APPL_NO,
           trim(p_in_step_code),--step_code
           trim(p_in_processor_no),
           OBJECT_ID,
           to_char(to_number(to_char(sysdate, 'yyyyMMdd')) - 19110000)--PROCESS_DATE
      FROM SPT21
      WHERE RECEIVE_NO = p_in_receive_no;
  
      p_out_msg := '由申請案件管理系統批次調閱文號[' || trim(p_in_receive_no) || ' ]影像檔!';  
      
    end if;
  
  end if;  

  SYS.Dbms_Output.Put_Line(p_out_msg);
  
end REQUEST_FOR_IMAGES;

/
--------------------------------------------------------
--  DDL for Procedure RESET_EARLY_APPLS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."RESET_EARLY_APPLS" (p_out_msg         out varchar2) is
  v_count      number;
begin

  select count(1) into v_count from appl_catg;
  if v_count > 0 then
    --resetSpt31a
    update spt31a set step_code='15'--,Ipc_Group_No='70014'
    where appl_no in (select appl_no from appl_catg);
    
    --reset Spt31b
    update spt31b set step_code='20'
    where appl_no in (select appl_no from appl_catg);
    
    --reset Appl_Trans
    delete Appl_Trans where appl_no in (select appl_no from appl_catg);
    
    --reset appl_catg
    delete appl_catg;
  end if;
  SYS.Dbms_Output.Put_Line('清除早期案件 '||v_count||' 筆!');
exception
  when others then  
  rollback;
  p_out_msg:='清除早期案件失敗!';
  SYS.Dbms_Output.Put_Line(p_out_msg);
end RESET_EARLY_APPLS;

/
--------------------------------------------------------
--  DDL for Procedure RESET_INFO_APPLS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."RESET_INFO_APPLS" (p_pre_date in varchar2,
                                                     p_out_msg         out varchar2) is
  v_count      number;
begin
  select count(1) into v_count from s193.ppr82 where PRE_DATE=p_pre_date;
  if v_count > 0 then
    --還原公開日期,公開號
    update spt82 set Notice_No_2='0', Notice_Date_2=null
    where appl_no in (select appl_no from ppr82 where PRE_DATE=p_pre_date);
    
    update spt81a set Notice_No_B=null,Notice_No_E=null
    where Notice_Date=to_char(to_char(add_months(to_date(p_pre_date+19110000,'YYYYMMDD'),3),'YYYYMMDD')-19110000);
    
    --刪除線上公開案件
    delete spt82 where appl_no in (select appl_no from s193.ppr82 where PRE_DATE=p_pre_date and s193.ppr82.online_flag='1');
    
    --還原公開階段別
    update spt31b set step_code='30' where step_code in ('50','60') and appl_no in (select appl_no from s193.ppr82 where PRE_DATE=p_pre_date and s193.ppr82.online_flag='1');
    update spt31b set step_code='50' where step_code='60' and appl_no in (select appl_no from s193.ppr82 where PRE_DATE=p_pre_date and s193.ppr82.online_flag='0');
    
    --刪除193公開案件
    delete s193.ppr82 where PRE_DATE=p_pre_date;
  end if;
  SYS.Dbms_Output.Put_Line('清除公開案件 '||v_count||' 筆!');
exception
  when others then  
  rollback;
  p_out_msg:='清除公開案件失敗!';
  SYS.Dbms_Output.Put_Line(p_out_msg);
end RESET_INFO_APPLS;

/
--------------------------------------------------------
--  DDL for Procedure SAVE_ANNEX
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SAVE_ANNEX" (
  p_in_appl_no in char,
  p_in_annex_code in char, 
  p_in_annex_desc in char
)
is
  v_options varchar2_tab;
begin
  v_options := get_revise_options(p_in_appl_no, 'Y');
  update appl set pre_exam_list = p_in_annex_code where appl_no = p_in_appl_no;
  delete appl50 where appl_no = p_in_appl_no;
  for l_idx in 1 .. v_options.count
  loop
    if substr(p_in_annex_code, l_idx, 1) = '1' and l_idx != 38 then
      insert into appl50 (appl_no, annex_desc, series_no) values (p_in_appl_no, substr(v_options(l_idx), 1, 50), l_idx);
    end if;
  end loop;
  if p_in_annex_desc is not null then
    insert into appl50 (appl_no, annex_desc, series_no) values (p_in_appl_no, substr(p_in_annex_desc, 1, 50), 38);
  end if;
end save_annex;

/
--------------------------------------------------------
--  DDL for Procedure SAVE_APPL_EXAM
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SAVE_APPL_EXAM" (
  p_in_appl_no in char,
  p_in_receive_no in char,
  p_in_process_result in char,
  p_in_appl_exam_flag in char,
  p_in_appl_priority_exam_flag in char)
is
  c_yes                constant char(1) := '1';
  v_material_appl_date spt31.material_appl_date%type;
  v_step_code          spt31a.step_code%type;
begin
  select material_appl_date
    into v_material_appl_date
    from spt31
   where appl_no = p_in_appl_no;
  select step_code
    into v_step_code
    from spt31a
   where appl_no = p_in_appl_no;
  if p_in_process_result in ('49259', '49245', '49255') then
    update spt31f
       set appl_flag = '2'
     where receive_no = p_in_receive_no;
  else
    if p_in_process_result = '49249' then
      update spt31f
         set appl_flag = '2'
       where spt31f.receive_no = p_in_receive_no;
    end if;
    if v_step_code < 29 then
      declare
        v_chk_flag       varchar2(2);
        v_material_code  varchar2(2);
        v_receive_date   spt21.receive_date%type;
        v_count_spt31b   number;
        v_count_spt31f   number;
        v_tmp_receive_no spt31f.receive_no%type;
      begin
        if p_in_appl_exam_flag = c_yes then 
          v_chk_flag := '10';
          v_material_code := '10';
        end if;
        if p_in_appl_priority_exam_flag = c_yes then 
          v_chk_flag := '01';
          v_material_code := '10';
        end if; 
        if p_in_appl_exam_flag = c_yes 
          and p_in_appl_priority_exam_flag = c_yes then 
          v_chk_flag := '11';
          v_material_code := '10';
        end if;
        if p_in_process_result in ('49247', '49249') then 
          v_material_code := '20';
        end if;
        select nvl(trim(postmark_date), receive_date)
          into v_receive_date
          from spt21
         where receive_no = p_in_receive_no;
        select count(1)
          into v_count_spt31b
          from spt31b
         where appl_no = p_in_appl_no;
        if v_count_spt31b = 0 then
         -- insert into spt31b (appl_no, step_code) values (p_in_appl_no, '10');
         SYS.Dbms_Output.Put_Line('wait');
        end if;
        select count(1)
          into v_count_spt31f
          from spt31f
         where appl_no = p_in_appl_no
           and receive_no = p_in_receive_no;
        if v_count_spt31f > 0 then
          if v_chk_flag is not null then
            update spt31f
               set appl_flag = ''
             where appl_no = p_in_appl_no
               and receive_no != p_in_receive_no;
          end if;
          case v_chk_flag
            when '10' then
              update spt31f 
                 set appl_flag = '1'  
               where receive_no = p_in_receive_no;
              update spt31b 
                 set data_date = v_receive_date,
                     material_code = v_material_code,
                     priority_code = ''
               where appl_no = p_in_appl_no;
            when '01' then
              update spt31f
                 set appl_flag = '1'
               where receive_no = p_in_receive_no;
              update spt31b
                 set data_date = v_receive_date,
                     priority_code = '10',
                     material_code = v_material_code
               where appl_no = p_in_appl_no;
            when '11' then
              update spt31f
                 set appl_flag = '1' 
               where receive_no = p_in_receive_no;
              update spt31b
                set data_date = v_receive_date,
                    priority_code = '10',
                    material_code = v_material_code
              where appl_no = p_in_appl_no;
            else
              select count(1)
                into v_count_spt31f
                from spt31f
               where appl_no = p_in_appl_no
                 and receive_no != p_in_receive_no
                 and appl_flag = '1';
              if v_count_spt31f = 0 then
                update spt31f
                   set appl_flag = '' 
                 where receive_no = p_in_receive_no;
                update spt31b 
                   set material_code = v_material_code,
                       priority_code = ''
                 where appl_no = p_in_appl_no;
                update spt31
                   set material_appl_date = ''
                 where appl_no = p_in_appl_no;
              elsif v_count_spt31f >= 1 then
                select trim(max(receive_no))
                  into v_tmp_receive_no
                  from spt31f
                 where appl_no = p_in_appl_no
                   and appl_flag = '1';
                update spt31f
                   set appl_flag = ''
                 where appl_no = p_in_appl_no
                   and receive_no != v_tmp_receive_no;
                select nvl(trim(postmark_date), receive_date)
                  into v_receive_date
                  from spt21
                 where receive_no = v_tmp_receive_no;
                if nvl(v_material_appl_date, '_') <> nvl(v_receive_date, '_') then
                  update spt31
                     set material_appl_date = v_receive_date
                   where appl_no = p_in_appl_no;
                end if;
              --elsif v_count_spt31f > 1 then
                --null;--不實作
              end if;
          end case;
        end if;
      end;
    end if;
  end if;
exception
  when no_data_found then null;--不處理
end save_appl_exam;

/
--------------------------------------------------------
--  DDL for Procedure SAVE_BIOMATERIAL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SAVE_BIOMATERIAL" (
  p_in_appl_no in char,
  p_in_biomaterial_array in biomaterial_tab
)
is
  v_tmp_biomaterial biomaterial_obj;
begin
  delete spt33 where appl_no = p_in_appl_no;
  if p_in_biomaterial_array is null
      or p_in_biomaterial_array.count = 0 then
    return;
  end if;
  for l_idx in p_in_biomaterial_array.first .. p_in_biomaterial_array.last
  loop
    v_tmp_biomaterial := p_in_biomaterial_array(l_idx);
    if v_tmp_biomaterial.appl_no is null or v_tmp_biomaterial.data_seq is null then
      continue;
    end if;
    insert into spt33
    (
      appl_no,
      data_seq,
      microbe_date,
      microbe_org_id,
      microbe_appl_no,
      national_id,
      microbe_org_name
    ) values (
      v_tmp_biomaterial.appl_no,
      v_tmp_biomaterial.data_seq,
      v_tmp_biomaterial.microbe_date,
      v_tmp_biomaterial.microbe_org_id,
      v_tmp_biomaterial.microbe_appl_no,
      v_tmp_biomaterial.national_id,
      v_tmp_biomaterial.microbe_org_name
    );
  end loop;
end save_biomaterial;

/
--------------------------------------------------------
--  DDL for Procedure SAVE_DIRECT_PAGE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SAVE_DIRECT_PAGE" (
  p_in_processor_no in char,
  p_in_draft_flag in number,
  p_in_direct_info_map in pair_tab,
  p_in_priority_right_array in priority_right_tab,
  p_in_biomaterial_array in biomaterial_tab,
  p_in_grace_period_array in grace_period_tab,
  p_out_warn_message_array out varchar2_tab,
  p_out_error_message_array out pair_tab,
  p_out_draft_message_array out pair_tab)
is
  --常數
  c_yes                     constant char(1) := '1';
  c_no                      constant char(1) := '0';
  --原始資料
  g_origin_spt31            spt31%rowtype;
  --變數
  g_appl_no                 spt31.appl_no%type;
  g_appl_date               spt31.appl_date%type;
  g_twis_flag               spt31.twis_flag%type;
  g_foreign_language        spt31.foreign_language%type;
  g_process_result          spt21.process_result%type;
  g_annex_desc              spt50.annex_desc%type;
  g_annex_code              spt50a.annex_code%type;
  g_appl_exam_flag          varchar2(1);
  g_appl_priority_exam_flag varchar2(1);
  g_spt31f_receive_no       spt31f.receive_no%type;
  g_spec_total_count        number;
  g_tw_sysdate              char(7);
  g_step_code               spt31a.step_code%type;
  
  procedure add_warn_message(p_message in varchar2)
  --================--
  --新增警告回傳訊息--
  --================--
  is
  begin
    p_out_warn_message_array.extend;
    p_out_warn_message_array(p_out_warn_message_array.last) := p_message;
  end add_warn_message;
  
  procedure add_error_message(p_key in varchar2, p_message in varchar2)
  --================--
  --新增錯誤回傳訊息--
  --================--
  is
  begin
    p_out_error_message_array.extend;
    p_out_error_message_array(p_out_error_message_array.last) := pair_obj(p_key, p_message);
  end add_error_message;
  
  procedure add_error_message(p_message in varchar2)
  --================--
  --新增錯誤回傳訊息--
  --================--
  is
  begin
    add_error_message('', p_message);
  end add_error_message;
  
  procedure init
  --==============--
  --初始化相關處理--
  --==============--
  is
    type key_value_map is table of varchar2(1000) index by varchar2(100);
    v_map key_value_map;
    v_pair pair_obj;
  begin
    p_out_warn_message_array := varchar2_tab();
    p_out_error_message_array := pair_tab();
    for l_idx in p_in_direct_info_map.first .. p_in_direct_info_map.last
    loop
      v_pair := p_in_direct_info_map(l_idx);
      v_map(v_pair.key) := v_pair.value;
    end loop;
    g_appl_no := v_map('APPL_NO');
    g_appl_date := v_map('APPL_DATE');
    g_twis_flag := nvl(v_map('TWIS_FLAG'), c_no);
    g_foreign_language := v_map('FOREIGN_LANGUAGE');
    g_process_result := v_map('PROCESS_RESULT');
    g_annex_desc := v_map('ANNEX_DESC');
    g_annex_code := v_map('ANNEX_CODE');
    g_appl_exam_flag := nvl(v_map('APPL_EXAM_FLAG'), c_no);
    g_appl_priority_exam_flag := nvl(v_map('APPL_PRIORITY_EXAM_FLAG'), c_no);
    g_spt31f_receive_no := v_map('SPT31F_RECEIVE_NO');
    g_spec_total_count := v_map('SPEC_TOTAL_COUNT');
    g_tw_sysdate := to_char(sysdate, 'yyyymmdd') - 19110000;
    select *
      into g_origin_spt31
      from spt31
     where appl_no = g_appl_no;
    select step_code
      into g_step_code
      from spt31a
     where appl_no = g_appl_no;
  end init;
  
  procedure check_direct_info
  --====================--
  --簡易案件基本資料檢核--
  --====================--
  is
  begin
    if g_appl_date is null then
      add_error_message('APPL_DATE', '申請日期未輸入');
    elsif not valid_tw_date(g_appl_date) then
      add_error_message('APPL_DATE', '申請日期非正確民國日期格式');
    end if;
    if trim(g_process_result) is not null then
      declare
        v_tmp_num number(4);
      begin
        select count(1)
          into v_tmp_num
          from spm75
         where type_no = g_process_result
           and type_no > '40000';
        if v_tmp_num = 0 then
          add_error_message('PROCESS_RESULT', '辦理結果格式錯誤');
        else
          p_out_error_message_array := 
              p_out_error_message_array multiset union wf_check(
                          g_appl_no,
                          g_appl_date,
                          g_process_result,
                          g_appl_exam_flag,
                          g_appl_priority_exam_flag,
                          null,
                          null);
          if g_process_result in ('49213', '43191', '43199', '43001', '49217', '43015', '49215', '43009') 
              and substr(g_appl_no, 4, 1) = '2' then
            if g_origin_spt31.first_day >= '0991011' then
              declare
                v_status spt21c.status%type;
              begin
                select status
                  into v_status
                  from spt21c
                 where appl_no = g_appl_no;
                if trim(v_status) != '9' then
                  add_error_message('PROCESS_RESULT', '首次中文說明書(圖說)尚未完成人工整檔,不可進行文件齊備通知作業!');
                end if;
              exception
                when no_data_found then
                  add_error_message('PROCESS_RESULT', '首次中文說明書(圖說)尚未完成確認,不可進行文件齊備通知作業!');
              end;
            end if;
          end if;
        end if;
      end;
    end if;
    if g_process_result in ('49259', '49245', '49255', '49249') or g_step_code < 29 then
      if g_spt31f_receive_no is null then
        add_error_message('欲註記之文號未選擇');
      end if;
    end if;
  end check_direct_info;
  
  procedure save_direct_info
  --================--
  --儲存案件基本資料--
  --================--
  is
  begin
    update spt31  
       set appl_date = g_appl_date,
		       patent_status = '3',
			--     sch_processor_no = p_in_processor_no, --> 取消回寫  mark by susan 
			--     phy_processor_no = p_in_processor_no, --  > 原本就不用回寫 mark by susan 
           twis_flag = g_twis_flag
     where appl_no = g_appl_no;
     -- update appl.processor_no  add by susan 
     update appl
     set processor_no = p_in_processor_no
      where appl_no = g_appl_no;
    /*if g_process_result in ('43001', '43003', '43007') then
      update spt31
         set f_adt_date = g_tw_sysdate,   
             pre_exam_check = '1' 
       where appl_no = g_appl_no;
    end if;*/
    
    save_annex(g_appl_no, g_annex_code, g_annex_desc);
    save_appl_exam(g_appl_no, g_spt31f_receive_no, g_process_result, g_appl_exam_flag, g_appl_priority_exam_flag);
    save_material_appl_date(g_appl_no, g_spt31f_receive_no, g_appl_exam_flag, g_appl_priority_exam_flag);
  end save_direct_info;
  
  procedure draft_check
  --========--
  --製稿檢查--
  --========--
  is
  begin
    p_out_draft_message_array := pair_tab();
    declare
      v_count number;
    begin
     if  g_process_result = '49213'  and substr(g_appl_no,4,1)= '1' then -- add by susan 104/07/16
      select count(1)
        into v_count
        from spm56 
       where form_id = 'P03-1'
         and issue_flag = '2'
         and appl_no = g_appl_no;
      if v_count > 0   then
        p_out_draft_message_array.extend;
        p_out_draft_message_array(p_out_draft_message_array.last) :=
          pair_obj('', '已製過P03-1稿且已發文!');
      end if;
     end if; 
    end;
    if substr(g_appl_no, 4, 1) = '1' and g_process_result in ('49213', '43191', '43199', '43001', '49217', '43015', '49215', '43009', '49243') then
      declare
        v_tmp_count number;
      begin
        select count(1)
          into v_tmp_count
          from appl
         where appl_no = g_appl_no
           and doc_complete = '1';
        if v_tmp_count = 0 then
          p_out_draft_message_array.extend;
          p_out_draft_message_array(p_out_draft_message_array.last) := pair_obj('DOC_COMPLETE', '尚未整卷，不可辦理齊備');
        end if;
      end;
    end if;
  end draft_check;
  
begin
  
  init;
  
  check_direct_info;
  validate_priority_right(
    g_process_result,
    g_appl_date,
    p_in_priority_right_array,
    p_out_error_message_array);
  if substr(g_appl_no, 4, 1) not in ('2', '3') then
    validate_biomaterial(
      g_process_result,
      p_in_biomaterial_array,
      p_out_error_message_array);
  end if;
  validate_grace_period(
    g_process_result,
    p_in_grace_period_array,
    p_out_error_message_array);
  
  --檢核沒錯誤才可以儲存
  if p_out_error_message_array.count = 0 then
    save_direct_info;
    save_priority_right(
      g_appl_no,
      g_process_result,
      p_in_priority_right_array,
      p_out_warn_message_array,
      p_out_error_message_array);
    if substr(g_appl_no, 4, 1) not in ('2', '3') then
      save_biomaterial(
        g_appl_no,
        p_in_biomaterial_array);
    end if;
    save_grace_period(
      g_appl_no,
      p_in_grace_period_array);
    
    save_spt31b_pre_date(g_appl_no, p_out_error_message_array);
    
    if p_in_draft_flag = 1 then
      draft_check;
    end if;
  end if;
  
end save_direct_page;

/
--------------------------------------------------------
--  DDL for Procedure SAVE_GRACE_PERIOD
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SAVE_GRACE_PERIOD" (
  p_in_appl_no in char,
  p_in_grace_period_array in grace_period_tab
)
is
  v_tmp_grace_period grace_period_obj;
begin
  delete spt31l where appl_no = p_in_appl_no;
  if p_in_grace_period_array is null
      or p_in_grace_period_array.count = 0 then
    return;
  end if;
  for l_idx in p_in_grace_period_array.first .. p_in_grace_period_array.last
  loop
    v_tmp_grace_period := p_in_grace_period_array(l_idx);
    if v_tmp_grace_period.appl_no is null or v_tmp_grace_period.data_seq is null then
      continue;
    end if;
    insert into spt31l
    (
      appl_no, 
      data_seq, 
      sort_id,
      novel_flag,
      novel_item,
      novel_date
    ) values (
      v_tmp_grace_period.appl_no,
      v_tmp_grace_period.data_seq,
      v_tmp_grace_period.data_seq,
      v_tmp_grace_period.novel_flag,
      v_tmp_grace_period.novel_item,
      v_tmp_grace_period.novel_date
    );
  end loop;
end save_grace_period;

/
--------------------------------------------------------
--  DDL for Procedure SAVE_MATERIAL_APPL_DATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SAVE_MATERIAL_APPL_DATE" (
  p_in_appl_no in char,
  p_in_receive_no in char,
  p_in_appl_exam_flag in char,
  p_in_appl_priority_exam_flag in char
)
is
  c_yes                       constant char(1) := '1';
  v_count_spt31f              number;
  v_tmp_receive_no            spt31f.receive_no%type;
  v_tmp_receive_date          spt21.receive_date%type;
  v_origin_material_appl_date spt31.material_appl_date%type;
begin
  if p_in_appl_exam_flag = c_yes or p_in_appl_priority_exam_flag = c_yes then
    select count('')
      into v_count_spt31f
      from spt31f
     where receive_no = p_in_receive_no
       and appl_no = p_in_appl_no
       and appl_flag  = '1';
    if v_count_spt31f > 0 then
      v_tmp_receive_no := p_in_receive_no;
    else
      begin
        select distinct receive_no
          into v_tmp_receive_no
          from spt31f
         where appl_no = p_in_appl_no
           and appl_flag = '1';
      exception
        when no_data_found then null;--不處理
      end;
    end if;
    select material_appl_date
      into v_origin_material_appl_date
      from spt31
     where appl_no = p_in_appl_no;
    if nvl(v_tmp_receive_no, '_') != nvl(v_origin_material_appl_date, '_') then
      if v_tmp_receive_no is not null then
        begin
          select nvl(trim(postmark_date), receive_date)
            into v_tmp_receive_date
            from spt21
           where receive_no = v_tmp_receive_no;
        exception
          when no_data_found then null;--不處理
        end;
      end if;
      update spt31
         set material_appl_date = v_tmp_receive_date
       where appl_no = p_in_appl_no;
    end if;
  end if;
end save_material_appl_date;

/
--------------------------------------------------------
--  DDL for Procedure SAVE_MERGE_RECEIVE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SAVE_MERGE_RECEIVE" (
  p_in_processor_no in char,
  p_in_receive_no in char,
  p_in_merge_master in char,
  p_in_merge in char
)
is
  v_processor_no spt21.processor_no%type;
  v_sc_flag      spt31.sc_flag%type;
begin
  select a.processor_no, b.sc_flag
    into v_processor_no, v_sc_flag
    from spt21 a, spt31 b
   where a.receive_no = p_in_receive_no
     and a.appl_no = b.appl_no;
  if p_in_processor_no = v_processor_no and nvl(v_sc_flag, '0') != '1' then
    if p_in_merge = 'Y' then
      update spt21
         set process_result = '40307'
       where receive_no = p_in_receive_no;
      update receive
         set merge_master = p_in_merge_master,
             step_code = (select step_code from receive where receive_no = p_in_merge_master)
       where receive_no = p_in_receive_no;
    else
      update spt21
         set process_result = ''
       where receive_no = p_in_receive_no;
      update receive
         set merge_master = '',
             step_code = '2'
       where receive_no = p_in_receive_no;
    end if;
  end if;
end save_merge_receive;

/
--------------------------------------------------------
--  DDL for Procedure SAVE_PRIORITY_RIGHT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SAVE_PRIORITY_RIGHT" (
  p_in_appl_no in char,
  p_in_process_result in char,
  p_in_priority_right_array in priority_right_tab,
  p_io_warn_message_array in out nocopy varchar2_tab,
  p_io_error_message_array in out nocopy pair_tab
)
is
  v_tmp_priority_right priority_right_obj;
  
  procedure add_error_message(p_message in varchar2)
  is
  begin
    p_io_error_message_array.extend;
    p_io_error_message_array(p_io_error_message_array.last) := pair_obj('', p_message);
  end add_error_message;
  
  procedure add_warn_message(p_message in varchar2)
  is
  begin
    p_io_warn_message_array.extend;
    p_io_warn_message_array(p_io_warn_message_array.last) := p_message;
  end add_warn_message;
begin
  delete spt32 where appl_no = p_in_appl_no;
  if p_in_priority_right_array is null
      or p_in_priority_right_array.count = 0 then
    return;
  end if;
  for l_idx in p_in_priority_right_array.first .. p_in_priority_right_array.last
  loop
    v_tmp_priority_right := p_in_priority_right_array(l_idx);
    if v_tmp_priority_right.appl_no is null or v_tmp_priority_right.data_seq is null then
      continue;
    end if;
      
    if p_in_process_result in (
        '43001', '43003', '43007', '43009', '43011', '43015', '43023', '43025', '43191', '43199',
        '49207', '49209', '49211', '49243', '49247', '49265', '49267', '49213', '49215', '49217',
        '49269', '49271', '49201') and v_tmp_priority_right.priority_nation_id = 'TW' then
      declare
        l_step_code      spt31b.step_code%type;
        l_step_code1     spt31a.step_code1%type;
        l_back_code      spt31.back_code%type;
        l_count          number;
        l_re_appl_date   spt31.re_appl_date%type;
        l_f_apl_exm_rslt spt31.f_apl_exm_rslt%type;
        l_r_apl_exm_rslt spt31.r_apl_exm_rslt%type;
        l_ipc_group_no   spt31a.ipc_group_no%type;
        l_material_code  spt31b.material_code%type;
      begin
      
        select step_code 
          into l_step_code 
          from spt31b
         where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
        select back_code 
          into l_back_code 
          from spt31 
         where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
         
         
        if v_tmp_priority_right.priority_flag = '1' and nvl(trim(l_back_code), '1') = '1' then
          update spt31
             set back_code = '2'
           where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
          if l_step_code in ('10', '20', '30', '40', '50', 'AA', 'BB', 'CC', 'DD', 'EE') then
            l_step_code := '70';
            update spt31b 
               set step_code = l_step_code 
             where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
          end if;
          
          select step_code 
            into l_step_code1
            from spt31a
           where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
           -- add_warn_message('l_step_code1 =' ||l_step_code1 );
          if l_step_code1 <> '99' then
            select count(issue_type) 
              into l_count 
              from spt41 
             where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no)
               and issue_type in ('56001', '56003', '56005', '56007', '56097', '56099')
               and nvl(file_d_flag, '_') <> '9';
            if l_count = 0 then
              update spt31a 
                 set step_code = '99',
                     step_code1 = l_step_code1
               where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
            end if;
          end if;
        elsif v_tmp_priority_right.priority_flag = '2' then
          if nvl(trim(l_back_code), '2') = '2' then
          
            select count(1) 
              into l_count
              from spt32  
             where trim(priority_appl_no) = trim(v_tmp_priority_right.priority_appl_no)
               and appl_no <> p_in_appl_no
               and priority_nation_id = 'TW'
               and priority_flag = '1';
              --  add_warn_message('l_count =' ||l_count );
            if l_count = 0 then
              update spt31 
                 set back_code = ''
               where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
              if l_step_code in ('AA', 'BB', 'CC', 'DD', 'EE' ,'FF') then
                update spt31b 
                   set step_code = case l_step_code 
                                     when 'AA' then '10' 
                                     when 'BB' then '20'
                                     when 'CC' then '30'
                                     when 'DD' then '40'
                                     when 'EE' then '50'
                                     when 'FF' then '60'
                                     else step_code
                                    end
                 where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
              end if;
              select count(1) 
                into l_count
                from spt32  
               where trim(priority_appl_no) = trim(v_tmp_priority_right.priority_appl_no)
                 and priority_flag = '1';
                --  add_warn_message('l_count='|| l_count);
              if l_count <= 1 then
                select step_code1 
                  into l_step_code
                  from spt31a
                 where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
                -- add_warn_message('l_step_code='|| l_step_code);
                l_step_code := trim(l_step_code);
                if l_step_code is not null then
                  update spt31a
                     set step_code = l_step_code,
                         step_code1 = ''
                   where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
                else
                  select trim(re_appl_date), trim(f_apl_exm_rslt), trim(r_apl_exm_rslt)
                    into l_re_appl_date , l_f_apl_exm_rslt , l_r_apl_exm_rslt
                    from spt31  
                   where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
                  select ipc_group_no  
                    into l_ipc_group_no
                    from spt31a  
                   where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
                  select material_code  
                    into l_material_code  
                    from spt31b  
                   where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
                  if l_ipc_group_no = '70012' then
                    if l_re_appl_date is not null then
                      if length(trim(v_tmp_priority_right.priority_appl_no)) = 10 and l_r_apl_exm_rslt is not null then
                        l_step_code := '49';
                      else
                        if l_material_code is not null then
                          l_step_code := '36';
                        else
                          l_step_code := '30';
                        end if;
                      end if;
                    else
                      if length(trim(v_tmp_priority_right.priority_appl_no)) = 10 and l_f_apl_exm_rslt is not null then
                         l_step_code := '29';
                      else
                        if l_material_code is not null then
                          l_step_code := '16';
                        else
                          l_step_code := '10';
                        end if;
                      end if;
                    end if;
                  elsif l_ipc_group_no in ('70013', '70014', '70015', '70016', '70021', '70022', '70023', '70024', '70025', '70026', '70027') then
                    if length(trim(v_tmp_priority_right.priority_appl_no)) = 10 and l_f_apl_exm_rslt is not null then
                      l_step_code := '29';
                    else
                      l_step_code := '20';
                    end if;
                  elsif l_ipc_group_no in ('70031', '70032', '70033', '70034', '70035') then
                    if length(trim(v_tmp_priority_right.priority_appl_no)) = 10 and l_r_apl_exm_rslt is not null then
                      l_step_code := '49';
                    else
                      l_step_code := '40';
                    end if;
                  elsif l_ipc_group_no = '70019' then
                    l_step_code := '15';
                  elsif l_ipc_group_no = '60037' then
                    l_step_code := '10';
                  end if;
                  if l_step_code is not null then
                    update spt31a  
                       set step_code = l_step_code,
                           step_code1 = ''
                     where trim(appl_no) = trim(v_tmp_priority_right.priority_appl_no);
                  else
                    add_warn_message('更新被主張優先權申請案號' || v_tmp_priority_right.priority_appl_no || '之階段別有誤(階段別為空值)，請聯絡資訊室協助處理!');
                  end if;
                end if;
              end if;
            end if;
          else
            case l_back_code
              when '1' then add_warn_message('被主張優先權申請案號' || v_tmp_priority_right.priority_appl_no || '已申請撤回，案件階段別未回復為審查中，請確認!');
              when '3' then add_warn_message('被主張優先權申請案號' || v_tmp_priority_right.priority_appl_no || '為申請案視為撤回，案件階段別未回復為審查中，請確認!');
              when '4' then add_warn_message('被主張優先權申請案號' || v_tmp_priority_right.priority_appl_no || '為改請案視為撤回，案件階段別未回復為審查中，請確認!');
              when '5' then add_warn_message('被主張優先權申請案號' || v_tmp_priority_right.priority_appl_no || '為分割案視為撤回，案件階段別未回復為審查中，請確認!');
              when '6' then add_warn_message('被主張優先權申請案號' || v_tmp_priority_right.priority_appl_no || '為15個月後申請撤回，案件階段別未回復為審查中，請確認!');
              when '8' then add_warn_message('被主張優先權申請案號' || v_tmp_priority_right.priority_appl_no || '為申請案不受理，案件階段別未回復為審查中，請確認!');
              when '9' then add_warn_message('被主張優先權申請案號' || v_tmp_priority_right.priority_appl_no || '已逾三年未申請實體審查(視為撤回)，案件階段別未回復為審查中，請確認!');
            end case;
          end if;
        end if;
      exception
        when no_data_found then null;--不處理
      end;
    end if;
      
    insert into spt32
    (
      appl_no,
      data_seq,
      priority_date,
      priority_nation_id,
      priority_appl_no,
      priority_flag,
      priority_revive,
      priority_doc_flag,
      access_code,
      ip_type
    ) values (
      v_tmp_priority_right.appl_no,
      v_tmp_priority_right.data_seq,
      v_tmp_priority_right.priority_date,
      v_tmp_priority_right.priority_nation_id,
      v_tmp_priority_right.priority_appl_no,
      v_tmp_priority_right.priority_flag,
      v_tmp_priority_right.priority_revive,
      v_tmp_priority_right.priority_doc_flag,
      v_tmp_priority_right.access_code,
      v_tmp_priority_right.ip_type
    );
  end loop;
end save_priority_right;

/
--------------------------------------------------------
--  DDL for Procedure SAVE_PROCCESS_PAGE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SAVE_PROCCESS_PAGE" (
  p_in_processor_no in char,
  p_in_draft_flag in number,
  p_in_proccess_info in proccess_info_obj,
  p_in_priority_right_array in priority_right_tab,
  p_in_biomaterial_array in biomaterial_tab,
  p_in_grace_period_array in grace_period_tab,
  p_in_merge_receive_no_array in varchar2_tab,
  p_in_set_first in number,
  p_out_warn_message_array out varchar2_tab,
  p_out_error_message_array out pair_tab,
  p_out_draft_message_array out pair_tab)
is
  --常數
  c_yes        constant char(1) := '1';
  c_no         constant char(1) := '0';

  g_tw_sysdate    char(7);
  g_appl_no       spt21.appl_no%type;
  g_receive_no    spt21.receive_no%type;
  g_origin_spt21  spt21%rowtype;
  g_origin_spt31  spt31%rowtype;
  g_step_code     spt31a.step_code%type; --案件階段別
/*
-- 104/09/18 : update appl.online_flg
*/
  procedure add_error_message(p_key in varchar2, p_message in varchar2)
  --================--
  --新增錯誤回傳訊息--
  --================--
  is
  begin
    p_out_error_message_array.extend;
    p_out_error_message_array(p_out_error_message_array.last) := pair_obj(p_key, p_message);
  end add_error_message;

  procedure add_error_message(p_message in varchar2)
  --================--
  --新增錯誤回傳訊息--
  --================--
  is
  begin
    add_error_message('', p_message);
  end add_error_message;

  procedure init
  is
  begin
    p_out_warn_message_array := varchar2_tab();
    p_out_error_message_array := pair_tab();
    g_tw_sysdate := to_char(sysdate, 'yyyymmdd') - 19110000;
    select *
      into g_origin_spt21
      from spt21
     where receive_no = rpad(p_in_proccess_info.receive_no, 12, ' ');
    g_appl_no := g_origin_spt21.appl_no;
    g_receive_no := g_origin_spt21.receive_no;
    select *
      into g_origin_spt31
      from spt31
     where appl_no = g_appl_no;
    select step_code
      into g_step_code
      from spt31a
     where appl_no = g_appl_no;
  end init;

  function check_spt21c
  return number
  is
  begin
    if g_origin_spt31.first_day >= '0991011' then
      declare
        v_status spt21c.status%type;
      begin
        select status
          into v_status
          from spt21c
         where appl_no = g_appl_no;
        if trim(v_status) != '9' then
          return 1;
        end if;
        return 0;
      exception
        when no_data_found then
          return 2;
      end;
    end if;
  end check_spt21c;

  procedure check_proccess_info
  --====================--
  --簡易案件基本資料檢核--
  --====================--
  is
  begin
    if p_in_proccess_info is null then
      add_error_message('伺服器無法取得案件基本資料');
      return;
    end if;
    if p_in_proccess_info.appl_date is null then
      add_error_message('APPL_DATE', '申請日期未輸入');
    elsif not valid_tw_date(p_in_proccess_info.appl_date) then
      add_error_message('APPL_DATE', '申請日期非正確民國日期格式');
    end if;
    if p_in_proccess_info.process_result is not null then
      declare
        v_tmp_num number(4);
      begin
        select count(1)
          into v_tmp_num
          from spm75
         where type_no = p_in_proccess_info.process_result
           and type_no > '40000';
        if v_tmp_num = 0 then
          add_error_message('PROCESS_RESULT', '辦理結果格式錯誤');
        else
          p_out_error_message_array :=
              p_out_error_message_array multiset union wf_check(g_receive_no,
                          p_in_proccess_info.appl_date,
                          p_in_proccess_info.process_result,
                          p_in_proccess_info.appl_exam_flag,
                          p_in_proccess_info.appl_priority_exam_flag,
                          p_in_proccess_info.pre_exam_date,
                          p_in_proccess_info.pre_exam_qty);
          if g_origin_spt21.type_no = '13000' then
            if p_in_proccess_info.re_appl_date is not null and not valid_tw_date(p_in_proccess_info.re_appl_date) then
              add_error_message('RE_APPL_DATE', '再審申請日格式不正確');
            end if;
          end if;
          if g_origin_spt21.type_no in ('10000', '24704', '24706', '21000', '21002', '24002', '11000', '11002', '11004', '11008', '11092', '12000')
              and substr(g_appl_no, 1, 3) >= '099'
              and substr(g_appl_no, 4, 1) = '1'
              and (p_in_proccess_info.appl_exam_flag = c_yes
                or p_in_proccess_info.appl_priority_exam_flag = c_yes
                or trim(g_origin_spt31.material_appl_date) is not null)
              and (p_in_proccess_info.exam_fee_scope_items is null
                or p_in_proccess_info.exam_fee_scope_items = 0)then
            add_error_message('EXAM_FEE_SCOPE_ITEMS', '項數為 0,請重新輸入!!');
          end if;
          if p_in_proccess_info.process_result in ('49213', '43191', '43199', '43001', '49217', '43015', '49215', '43009')
              and substr(g_appl_no, 4, 1) = '2' then
            if p_in_set_first = 0 then
              add_error_message('PROCESS_RESULT', '未指定首次中文說明書(圖說),不可進行文件齊備通知作業!');
               /* Mark by Susan 
                  104/08/31 因指定中文本改以每日批次和090進行同步,spt21c 註記改以用來視別是否已和090同步
                  故不再於案件審查時檢查*/
             -------------------------------------*/
           -- else
            --  case check_spt21c
           --     when 1 then add_error_message('PROCESS_RESULT', '首次中文說明書(圖說)尚未完成人工整檔,不可進行文件齊備通知作業!');
           --     when 2 then add_error_message('PROCESS_RESULT', '首次中文說明書(圖說)尚未完成確認,不可進行文件齊備通知作業!');
          --      else null;
         --     end case;
            end if;
          end if;
        end if;
      end;
    end if;
   if substr(g_appl_no, 4, 1) = '3' and g_origin_spt21.type_no = '10007' then
      declare
        v_notice_date spmf1.notice_date%type;
        v_appl_date   spt31.appl_date%type;
      begin
        select notice_date
          into v_notice_date
          from spmf1
         where appl_no = g_appl_no;
         select appl_date into v_appl_date
         from spt31 where appl_no = g_appl_no;
        if  v_appl_date > p_in_proccess_info.appl_date  then 
              add_error_message('申請衍生設計專利，其申請日不得早於原設計之申請日！');
        end if;
        if trim(v_notice_date) is not null then
          add_error_message('原設計專利已公告,不得申請衍生設計專利!');
        end if;
      exception
        when no_data_found then null;--不處理
      end;
    end if;
  end check_proccess_info;

  procedure save_proccess_info
  --================--
  --儲存案件基本資料--
  --================--
  is
  begin
   
    update spt21
       set process_result = p_in_proccess_info.process_result,
           pre_exam_date = p_in_proccess_info.pre_exam_date,
           pre_exam_qty = p_in_proccess_info.pre_exam_qty,
           complete_date = g_tw_sysdate
     where receive_no = g_receive_no;
    update spt31
       set appl_date = p_in_proccess_info.appl_date,
           twis_flag = p_in_proccess_info.twis_flag,
           patent_status = '3'
     where appl_no = g_appl_no;
     ----------------------------------
     -- add by susan  104/09/02 
     -- for meeting decision 
     /*
     -- move the code to procedure  get_receive 
     update spt31
      set sch_processor_no= p_in_processor_no, phy_processor_no = p_in_processor_no
      where appl_no in
      (
        select appl_no from spt31a 
        where appl_no = g_appl_no
        and ((step_code between '10' and '19'  and step_code != '15')
              or step_code = '30'
              or step_code = '29'
              or step_code = '49'
              or ( exists (select 1 from spt21 where appl_no = spt31.appl_no and  type_no in ('16000','16002','22210')))
            )
      and substr(appl_no,10,1) != 'N');
      */
     -- end
     ------------------------------------
    if g_origin_spt21.type_no = '13000' and valid_tw_date(p_in_proccess_info.re_appl_date) then
      update spt31
         set re_appl_date = p_in_proccess_info.re_appl_date
       where appl_no = g_appl_no;
      if g_step_code < '30' then
        update spt31a
           set step_code = '30',
               type_no = g_origin_spt21.type_no,
               data_date = g_origin_spt21.receive_date,
               ipc_group_no = '70012'
         where appl_no = g_appl_no;
      end if;
    end if;
    if p_in_proccess_info.process_result = '43199' then
      update spt31
         set f_adt_date = g_tw_sysdate,
             pre_exam_check  = '1'
       where appl_no = g_appl_no;
    end if;
    if p_in_proccess_info.process_result = '41001' and g_origin_spt21.process_result = '43199' then
      update spt31
         set f_adt_date = '',
             pre_exam_check = ''
       where appl_no = g_appl_no;
    end if;
    if p_in_proccess_info.process_result = '43191' then
      update spt31
         set f_adt_date = g_tw_sysdate,
             pre_exam_check  = '1'
       where appl_no = g_appl_no;
      update spt31a
         set step_code = '15',
             ipc_group_no = '70019'
       where appl_no = g_appl_no;
    end if;
    if p_in_proccess_info.process_result = '41001' and g_origin_spt21.process_result = '43191' then
      update spt31
         set f_adt_date = '',
             pre_exam_check = ''
       where appl_no = g_appl_no;
      update spt31a
         set step_code = '10',
             ipc_group_no = '60037'
       where appl_no = g_appl_no;
    end if;
    
    /*
     ----
    -- write to dblog 104/9/14
    ----
    DBLOG_193(p_in_processor_no,'U','RECEIVE',' where receive_no =  '|| '''' || g_receive_no ||'''');
    --------------
    -- write to dblog end
    ----------------
    */
    update receive
       set unusual = p_in_proccess_info.unusual,
           step_code = decode(p_in_proccess_info.process_result, null, '2', '3')
     where receive_no = g_receive_no;
    --[審查費計算]儲存 開始
   
    declare
      v_count_spt31n       number;
    begin
      if g_origin_spt21.type_no in (
          '10000', '24704', '24706', '21000', '21002',
          '24002', '11000', '11002', '11004', '11008',
          '11092', '12000', '13000', '24100')
        and substr(g_appl_no, 4, 1) = '1'
        and substr(g_appl_no, 1, 3) >= '099'
        and (
             p_in_proccess_info.appl_exam_flag = c_yes
             or p_in_proccess_info.appl_priority_exam_flag = c_yes
             or trim(g_origin_spt31.material_appl_date) is not null
             or p_in_proccess_info.type_no in ('13000', '24100')
            )
        and p_in_proccess_info.exam_fee_scope_items > 0 then
        select count(1)
          into v_count_spt31n
          from spt31n
         where receive_no = g_receive_no
           and appl_no = g_appl_no;
        if v_count_spt31n > 0 then
          update spt31n
             set scope_items = p_in_proccess_info.exam_fee_scope_items,
                 exam_pay = p_in_proccess_info.exam_fee_exam_pay,
                 tax_amount = p_in_proccess_info.exam_fee_tax_amount,
                 e_flag = p_in_proccess_info.exam_fee_e_flag,
                 f_flag = p_in_proccess_info.exam_fee_f_flag
           where receive_no = g_receive_no
             and appl_no = g_appl_no;
        else
          insert into spt31n
          (
            receive_no,
            appl_no,
            scope_items,
            exam_pay,
            tax_amount,
            e_flag,
            f_flag
          ) values (
            g_receive_no,
            g_appl_no,
            p_in_proccess_info.exam_fee_scope_items,
            p_in_proccess_info.exam_fee_exam_pay,
            p_in_proccess_info.exam_fee_tax_amount,
            p_in_proccess_info.exam_fee_e_flag,
            p_in_proccess_info.exam_fee_f_flag
          );
        end if;
        update spt31
           set page_cnt = p_in_proccess_info.exam_fee_page_cnt,
               scope_items = p_in_proccess_info.exam_fee_scope_items
         where appl_no = g_appl_no ;
      end if;
    end;
    
    --[審查費計算]儲存 結束
    --[申請實體審查與申請實體審查與優先審查]儲存 開始
    save_appl_exam(
      g_appl_no,
      g_receive_no,
      p_in_proccess_info.process_result,
      p_in_proccess_info.appl_exam_flag,
      p_in_proccess_info.appl_priority_exam_flag);
    --[申請實體審查與申請實體審查與優先審查]儲存 結束
    --[補正選項]儲存 開始
    save_annex(g_appl_no, p_in_proccess_info.revise_value, p_in_proccess_info.annex_desc);
    --[補正選項]儲存 結束
    --[代為更正]儲存 開始
    
    declare
      v_count_spmfi number;
    begin
      select count(1)
        into v_count_spmfi
        from ap.spmfi
       where appl_no = g_appl_no;
      if trim(p_in_proccess_info.spmfi_coment) is not null then
        if v_count_spmfi > 0 then
          update ap.spmfi
             set coment = trim(p_in_proccess_info.spmfi_coment)
           where appl_no = g_appl_no;
        else
          insert into ap.spmfi
          (
            appl_no,
            coment
          ) values (
            g_appl_no,
            trim(p_in_proccess_info.spmfi_coment)
          );
        end if;
      else
        if v_count_spmfi > 0 then
          delete ap.spmfi where appl_no = g_appl_no;
        end if;
      end if;
    end;
     
    --[代為更正]儲存 結束
    --[wf_material_appl_date] 儲存 開始
    save_material_appl_date(
      g_appl_no,
      g_receive_no,
      p_in_proccess_info.appl_exam_flag,
      p_in_proccess_info.appl_priority_exam_flag);
    --[wf_material_appl_date] 儲存 結束
    --[併辦]儲存 開始
    declare
      v_after_receive_tab   after_receive_tab;
      v_count               number;
      v_after_receive       after_receive_obj;
    begin
    
      v_after_receive_tab := get_after_receives(g_receive_no);
     if v_after_receive_tab.last is not null then  -- add by Susan 104/07/03
      
        for l_idx in v_after_receive_tab.first .. v_after_receive_tab.last
        loop
          v_after_receive := v_after_receive_tab(l_idx);
      
          select count(1)
            into v_count
            from table(p_in_merge_receive_no_array)
           where trim(column_value) = trim(v_after_receive.receive_no);
          
          if v_count != 0 then
            save_merge_receive(p_in_processor_no, v_after_receive.receive_no, g_receive_no, 'Y');
          else
            if v_after_receive.merge_master is not null then
              save_merge_receive(p_in_processor_no, v_after_receive.receive_no, v_after_receive.merge_master, 'N');
            end if;
          end if;
        end loop;
      end if;
    end;
    
    --[併辦]儲存 結束
  end save_proccess_info;

  procedure draft_check
  --========--
  --製稿檢查--
  --========--
  is
  begin
    p_out_draft_message_array := pair_tab();
    declare
      v_form_file_a spt41.form_file_a%type;
    begin
          
       select form_file_a into v_form_file_a
       from 
       (
        select form_file_a
        from spt41 a
        where a.check_datetime is null
        and a.processor_no =  p_in_processor_no
        and a.receive_no =  g_receive_no
        and a.form_file_a = (select max(b.form_file_a) from spt41 b where b.receive_no = a.receive_no)
        union all         
        select form_file_a
        from spm56  a
        where processor_no =  p_in_processor_no
         and receive_no = g_receive_no
         and form_file_a =  (select max(form_file_a) from spm56 b where b.receive_no = a.receive_no and b.processor_no =  a.processor_no)
         and issue_flag = '1'
         and online_sign = '1'
         and exists (select 1 from ap.sptd02 where form_file_a = a.form_file_a and node_status >= '400' and node_status < '900')
         )
         ;
      p_out_draft_message_array.extend;
      p_out_draft_message_array(p_out_draft_message_array.last) :=
        pair_obj('ISSUE_NO', '本案尚有待發文的函稿[稿號' || v_form_file_a ||'],請確認是否發文!');
    exception
      when no_data_found then null;
    end;
    declare
      v_count number;
    begin
    if  p_in_proccess_info.process_result = '49213' and substr(g_appl_no,4,1)= '1' then
      select count(1)
        into v_count
        from spm56 
       where form_id = 'P03-1'
         and issue_flag = '2'
         and appl_no = g_appl_no;
      if v_count > 0 then
        p_out_draft_message_array.extend;
        p_out_draft_message_array(p_out_draft_message_array.last) :=
          pair_obj('', '已製過P03-1稿且已發文!');
      end if;
    end if;
    end;
    /* Mark by Susan 
      104/08/31 因指定中文本改以每日批次和090進行同步,spt21c 註記改以用來視別是否已和090同步
      故不再於案件審查時檢查*/
    /*-------------------------------------
    if p_in_proccess_info.process_result in (
        '49213', '49215', '49217', '49269', '49271', '49207', '49209', '49211', '49221', '49223',
        '49225', '49265', '49267', '49269', '49271', '49273', '49275', '43191', '43199', '43001') then
      case check_spt21c
        when 1 then
          p_out_draft_message_array.extend;
          p_out_draft_message_array(p_out_draft_message_array.last) :=
            pair_obj('', '首次中文說明書(圖說)尚未完成人工整檔,不可進行文件齊備通知作業!');
        when 2 then
          p_out_draft_message_array.extend;
          p_out_draft_message_array(p_out_draft_message_array.last) :=
            pair_obj('', '首次中文說明書(圖說)尚未完成確認,不可進行文件齊備通知作業!');
        else
          null;
      end case;
    end if;
    */
    if g_origin_spt21.type_no = '24100' then
      if trim(g_origin_spt31.re_appl_date) is null then
        p_out_draft_message_array.extend;
        p_out_draft_message_array(p_out_draft_message_array.last) := pair_obj('', '此案無再審申請日期,無法製稿');
      end if;
    end if;
    if substr(g_appl_no, 4, 1) = '1' and p_in_proccess_info.process_result in ('49213', '43191', '43199', '43001', '49217', '43015', '49215', '43009', '49243') then
      declare
        v_tmp_count number;
      begin
        select count(1)
          into v_tmp_count
          from appl
         where appl_no = g_appl_no
           and doc_complete = '1';
        if v_tmp_count = 0 then
          p_out_draft_message_array.extend;
          p_out_draft_message_array(p_out_draft_message_array.last) := pair_obj('DOC_COMPLETE', '尚未整卷，不可辦理齊備');
        end if;
      end;
    end if;
    -----------------------------
    -- 線上審查註記
    -- add by susan tseng 104.09.18
    -----------------------------
    update appl set appl.online_flg = '1' 
    where exists (select 1 from receive where receive.appl_no = appl.appl_no)
    and (appl.online_flg = '0' or appl.online_flg is null)
    ;
  end draft_check;

begin

  init;

  check_proccess_info;
  validate_priority_right(
    p_in_proccess_info.process_result,
    p_in_proccess_info.appl_date,
    p_in_priority_right_array,
    p_out_error_message_array);
  if substr(g_appl_no, 4, 1) not in ('2', '3') then
    validate_biomaterial(
      p_in_proccess_info.process_result,
      p_in_biomaterial_array,
      p_out_error_message_array);
  end if;
  validate_grace_period(
    p_in_proccess_info.process_result,
    p_in_grace_period_array,
    p_out_error_message_array);

  --檢核沒錯誤才可以儲存
  if p_out_error_message_array.count = 0 then
    
    save_proccess_info;
    save_priority_right(
      g_appl_no,
      p_in_proccess_info.process_result,
      p_in_priority_right_array,
      p_out_warn_message_array,
      p_out_error_message_array);
    if substr(g_appl_no, 4, 1) not in ('2', '3') then
      save_biomaterial(
        g_appl_no,
        p_in_biomaterial_array);
    end if;
    save_grace_period(
      g_appl_no,
      p_in_grace_period_array);
    
     save_spt31b_pre_date(g_appl_no, p_out_error_message_array);
    
    if p_in_draft_flag = 1 then
      draft_check;
    end if;

  end if;

exception
  when others then
    rollback;
end save_proccess_page;

/
--------------------------------------------------------
--  DDL for Procedure SAVE_SPT31B_PRE_DATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SAVE_SPT31B_PRE_DATE" (
  p_in_appl_no in char,
  p_io_error_message_array in out nocopy pair_tab)
is
  not_a_valid_date exception;
  pragma exception_init(not_a_valid_date, -20001);

  v_priority_date varchar2(8);
  v_appl_date     spt31.appl_date%type;
  v_pre_date      spt31b.pre_date%type;
  
  function to__date(
    p_char_literal in varchar2,
    p_date_format  in varchar2)
  return date 
  is
  begin
    return to_date(p_char_literal, p_date_format);
  exception
    when others then
      raise_application_error(-20001, 'Not a valid date');
  end to__date;
  
  function tw_to_ad(p_tw in varchar2)
  return varchar2
  is
  begin
    return substr(p_tw, 1, 3) + 1911 || substr(p_tw, 4);
  end tw_to_ad;
  
  function ad_to_tw(p_ad in varchar2)
  return varchar2
  is
  begin
    return lpad(p_ad - '19110000', 7, '0');
  end ad_to_tw;
begin
  select appl_date
    into v_appl_date
    from spt31
   where appl_no = p_in_appl_no;
  select nvl(min(priority_date),'29991231')
    into v_priority_date
    from (
      select priority_date 
        from spt32 
       where appl_no = p_in_appl_no 
         and nvl(trim(priority_flag), '1') = '1' 
       order by priority_date
    )
 --  where rownum <= 1;
 ;
  if v_priority_date is not null then
    v_pre_date := ad_to_tw(to_char(
        least(
          to__date(v_priority_date, 'yyyymmdd') + 1, 
          to_date(tw_to_ad(v_appl_date), 'yyyymmdd') + 1
        )
      , 'yyyymmdd'));
  else
    v_pre_date := ad_to_tw(to_char(
        to_date(tw_to_ad(v_appl_date), 'yyyymmdd') + 1
      , 'yyyymmdd'));
  end if;
--  SYS.Dbms_Output.Put_Line('v_pre_date=' || v_pre_date);
  update spt31b 
     set pre_date = v_pre_date
   where appl_no = p_in_appl_no;
exception
  when not_a_valid_date then
    p_io_error_message_array.extend;
    p_io_error_message_array(p_io_error_message_array.last) := pair_obj('', '更新公開準備起始日發生錯誤:' || v_priority_date || ' 不是正確日期');
    raise_application_error(-20010, v_priority_date || 'Not a valid date');
  when no_data_found then null;--不處理
end save_spt31b_pre_date;

/
--------------------------------------------------------
--  DDL for Procedure SEND_APPL_TO_EARLY_PUBLICATION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SEND_APPL_TO_EARLY_PUBLICATION" (
  p_PROCESSOR_NO VARCHAR2, --[in ]承辦人代碼
  p_APPL_NO VARCHAR2,      --[in ]申請案號
  p_FUNC_CODE VARCHAR2,    --[in ]功能代碼 0:程序已撤回該案 1:程序回覆成功 2:程序退辦它科(早期)
  p_PROCESS_RESULT VARCHAR2,       --[in ]退辦程序理由
  P_OUT_MSG OUT NUMBER) --[out]成功(>0)/失敗(else)
AS

----------------------------------------
--程序回覆成功 早期處理邏輯
----------------------------------------
PROCEDURE appl_trans_success
as
begin
	  insert into appl_trans
	  select APPL_TRANS_ID_SEQ.nextval ID,
           appl_no, 
	         p_FUNC_CODE trans_no,
		       step_code step_code_prv,
          '26' step_code, 
		       p_PROCESSOR_NO object_from,
		       PROCESSOR_NO object_to,
		       p_PROCESSOR_NO PROCESSOR_NO,
           sysdate TRANS_DATE,
           sysdate ACCEPT_DATE,
		       '程序回覆:'||p_PROCESS_RESULT remark
    from appl_catg
	  where trim(appl_no)=trim(p_APPL_NO) and step_code='25';
	
	  --更新狀態
    update appl_catg set step_code=26,send_date=sysdate /*重新列入本月*/
    where trim(appl_no)=trim(p_APPL_NO) 
      and step_code='25';
end;
----------------------------------------
--程序回覆撤回 早期處理邏輯
----------------------------------------
PROCEDURE appl_trans_reject
as
begin
	  insert into appl_trans
	  select APPL_TRANS_ID_SEQ.nextval ID,
           appl_no, 
	         p_FUNC_CODE trans_no,
           step_code step_code_prv,
		       '20' step_code, 
		       PROCESSOR_NO object_from,
		       null object_to,
		       p_PROCESSOR_NO PROCESSOR_NO,
           sysdate TRANS_DATE,
           sysdate ACCEPT_DATE,
		       '程序撤回:'||p_PROCESS_RESULT remark
    from appl_catg
	  where trim(appl_no)=trim(p_APPL_NO) and step_code='25';
	
	  --更新狀態
    update appl_catg set step_code=20
                       --,processor_no=null,supervisor_no=null,SEND_BACK_CNT=0, SEND_DATE=null,ACCEPT_DATE=null,ASSIGN_DATE=null
    where trim(appl_no)=trim(p_APPL_NO) 
      and step_code='25';
end;
----------------------------------------
--程序退辦給70014 早期處理邏輯
----------------------------------------
PROCEDURE appl_trans_send
as
l_APPL_NO	CHAR(15):=null;
l_PROCESSOR_NO	CHAR(5):=null;
l_STEP_CODE	CHAR(2):=null;
begin
	  --更新狀態
    begin
    select appl_no, PROCESSOR_NO,STEP_CODE
    into l_appl_no, l_PROCESSOR_NO,l_STEP_CODE
    from appl_catg 
    where trim(appl_no)=trim(p_APPL_NO);
    exception  
      WHEN OTHERS THEN
        dbms_output.put_line(l_appl_no);
        l_appl_no := null;
    end ;
 
	  insert into appl_trans
	  select APPL_TRANS_ID_SEQ.nextval ID,
           appl_no, 
	         p_FUNC_CODE trans_no,
		       step_code step_code_prv,
          case when l_STEP_CODE='25' then '26' 
               when l_step_code>'20' and l_step_code<'30' then l_step_code 
               else '21' end step_code,  ---?
		       null object_from,
		       '70014' object_to,
		       trim(p_PROCESSOR_NO) PROCESSOR_NO,
           sysdate TRANS_DATE,
           sysdate ACCEPT_DATE,
		       '程序移它科:'||p_PROCESS_RESULT remark
    from appl
	  where trim(appl_no)=trim(p_APPL_NO);
	
    
    if(l_appl_no is null) then /*人工分派*/
         INSERT into appl_catg (
            APPL_NO,PROCESSOR_NO,ASSIGN_DATE,STEP_CODE,SEND_BACK_CNT,
            PROCESSOR_NO_PRV,PROCESSOR_NO_PRV_2
            )
		      VALUES (
            p_APPL_NO,'70014',sysdate,'21',3, 
            p_PROCESSOR_NO,'70012'
            );
    else 
      if (l_STEP_CODE='25') then /*程序回覆*/
            update appl_catg set step_code='26', send_date=sysdate /*重新列入本月*/
            where trim(appl_no)=trim(p_APPL_NO);
      else 
        if (l_step_code<='20' or l_step_code>='30') then /*非早期公開階段*/
              UPDATE appl_catg 
              SET step_code='21',
                  send_back_cnt=3,
                  ASSIGN_DATE=sysdate,
                  processor_no='70014',
                  supervisor_no=null,
                  processor_no_prv=l_processor_no,
                  PROCESSOR_NO_PRV_2='70012'
              where trim(appl_no)=trim(p_APPL_NO);
        end if;
      end if;
    end if;
end;
----------------------------------------
--程序回覆 主程式
----------------------------------------
BEGIN
  if p_FUNC_CODE = '1' then --程序回覆成功
    appl_trans_success;
  else --程序已撤回
    if p_FUNC_CODE = '2' then --程序退辦
      appl_trans_send;
    else
      appl_trans_reject;
    end if;
  end if;
  --回傳更新筆數
  P_OUT_MSG := sql%rowcount;
END SEND_APPL_TO_EARLY_PUBLICATION;

/
--------------------------------------------------------
--  DDL for Procedure SEND_APPL_TO_PROCEDURE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SEND_APPL_TO_PROCEDURE" (
  p_PROCESSOR_NO VARCHAR2, --[in ]承辦人代碼
  p_APPL_NO VARCHAR2,      --[in ]申請案號
  p_REMARK VARCHAR2,       --[in ]退辦程序理由
  P_OUT_MSG OUT NUMBER) --[out]成功(>0)/失敗(else)
AS

  ----------------------------------------
  --退辦程序 新增或更新程序案件
  -- update 104/09/17 它科退辦時,若最後一位P03-1承辦人為 外包或離職人員 ,則進行輪辦
  ----------------------------------------
  procedure insert_proc_appl
  as
   l_processor_no char(5);
   l_cnt number;
   begin
      select  (select processor_no from spm63 where processor_no =  spm56.processor_no and dept_no = '70012'  and quit_date is null) 
          into l_processor_no
                from spm56 
                where trim(appl_no) = trim(p_APPL_NO)
                 and form_file_a = (select max(form_file_a) from spm56 s56 where spm56.appl_no = s56.appl_no)
                 and form_id = 'P03-1'
                 ;
        
        select count(1) into l_cnt from appl where trim(appl_no) =  trim(p_APPL_NO);
        
      --新增
      if l_cnt = 0 then
      insert into appl(APPL_NO,STEP_CODE,DIVIDE_CODE,DIVIDE_REASON,FINISH_FLAG,
                       RETURN_NO,IS_OVERTIME,PROCESS_DATE,PROCESSOR_NO)
        select appl_catg.APPL_NO,
               spt31a.step_code STEP_CODE,
               '3' DIVIDE_CODE,
               p_REMARK DIVIDE_REASON,
               '0' FINISH_FLAG,
               '0' RETURN_NO,
               '0' IS_OVERTIME,
               TO_CHAR(TO_NUMBER(TO_CHAR(SYSDATE, 'YYYYMMDD')) - 19110000) PROCESS_DATE,
               case when l_processor_no  is null or substr(l_processor_no,1,1) = 'P' then
                ( select processor_no   from skill where auto_shift = '1'
                                  and processor_no > ( select trim(para_no)  from appl_para where sys = 'OVERTIME' and subsys = 'TAKETURN')
                                  and rownum =1 ) 
                   else l_processor_no
                  
               end
               PROCESSOR_NO -- last P03-1 maker or take turn processor_no
          from appl_catg,spt31a
         where appl_catg.appl_no=spt31a.appl_no(+) 
           and trim(appl_catg.appl_no)=trim(p_APPL_NO)
           and appl_catg.step_code in ('22','24','26','27','28','29');   
       else
          update appl set DIVIDE_CODE='3',
                        DIVIDE_REASON=p_REMARK,
                        PROCESS_DATE=TO_CHAR(TO_NUMBER(TO_CHAR(SYSDATE, 'YYYYMMDD')) - 19110000)  ,
                        processor_no =  case when l_processor_no   is null or substr(l_processor_no,1,1) = 'P' then
                                ( select processor_no   from skill where auto_shift = '1'
                                  and processor_no > ( select trim(para_no)  from appl_para where sys = 'OVERTIME' and subsys = 'TAKETURN')
                                  and rownum =1 ) 
                          else
                             l_processor_no
                       end
         where trim(appl_no)=trim(p_APPL_NO);
       end if;
         --- 
         -- 重新設定輪辦
         -------
           IF l_processor_no is null or substr(l_processor_no,1,1) = 'P' THEN
               update appl_para 
               set para_no = ( select processor_no   from skill where auto_shift = '1'
                                  and processor_no > ( select trim(para_no)  from appl_para where sys = 'OVERTIME' and subsys = 'TAKETURN')
                                  and rownum =1 ) 
               where sys = 'OVERTIME' and subsys = 'TAKETURN'
               ;
           END IF;

  
        
  end;
  ----------------------------------------
  --退辦程序 更新早期狀態
  ----------------------------------------
  procedure update_early_status
  as
  begin

    insert into appl_trans
      select APPL_TRANS_ID_SEQ.nextval ID,
             appl_no, 
             '1' trans_no,
             step_code step_code_prv,
            '25' step_code, 
             PROCESSOR_NO object_from,
             '70012' object_to,
             p_PROCESSOR_NO PROCESSOR_NO,
             sysdate TRANS_DATE,
             sysdate ACCEPT_DATE,
             '退辦程序:'||p_REMARK remark
        from appl_catg
        where trim(appl_no)=trim(p_APPL_NO);
        
    update appl_catg set step_code='25',send_date=null /*不列入當月*/
      where trim(appl_no)=trim(p_APPL_NO);

  end;
  
----------------------------------------
--退辦程序 主程式
----------------------------------------
BEGIN
  
  --新增或更新程序案件
  insert_proc_appl;

  --更新早期狀態
  update_early_status;

/*
  if SQL%ROWCOUNT>0 then
    --更新早期狀態
    update_early_status;
  end if;
*/  
  --回傳更新筆數
  P_OUT_MSG:=1;
  
  exception
    WHEN OTHERS THEN
      P_OUT_MSG:=0;
END SEND_APPL_TO_PROCEDURE;

/
--------------------------------------------------------
--  DDL for Procedure SKILL_LIST
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SKILL_LIST" (p_out_list out sys_refcursor) is
begin
  --輪辦清單
  open p_out_list for
    SELECT SPM63.NAME_C,
           SPM63.PROCESSOR_NO,
           INVENTION,
           UTILITY,
           DESIGN,
           DERIVATIVE,
           IMPEACHMENT,
           REMEDY,
           PETITION,
           DIVIDING,
           CONVERTING,
           DIVIDING_AMEND,
           CONVERTING_AMEND,
           MISC_AMEND,
           AUTO_SHIFT
      FROM SPM63, SKILL
     WHERE SPM63.PROCESSOR_NO = SKILL.PROCESSOR_NO
       AND SPM63.DEPT_NO = '70012'
       AND SPM63.QUIT_DATE IS NULL
     ORDER BY SPM63.PROCESSOR_NO;

end SKILL_LIST;

/
--------------------------------------------------------
--  DDL for Procedure SKILL_PRELOAD
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SKILL_PRELOAD" is
  --預載輪辦清單
begin

  INSERT INTO SKILL
    (PROCESSOR_NO)
    SELECT SPM63.PROCESSOR_NO
      FROM SPM63, SKILL
     WHERE SPM63.PROCESSOR_NO = SKILL.PROCESSOR_NO(+)
       AND SPM63.DEPT_NO = '70012'
       AND SPM63.QUIT_DATE IS NULL
       AND SKILL.PROCESSOR_NO IS NULL;

end SKILL_PRELOAD;

/
--------------------------------------------------------
--  DDL for Procedure SKILL_UPDATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SKILL_UPDATE" (p_in_processor_no in varchar2,
                                         p_in_item         in varchar2,
                                         p_in_value        in varchar2) is
  --儲存輪辦清單
begin
  execute immediate 'UPDATE SKILL SET ' || p_in_item ||
                    ' = :1 WHERE PROCESSOR_NO=:2'
    using p_in_value, p_in_processor_no;

end SKILL_UPDATE;

/
--------------------------------------------------------
--  DDL for Procedure UPDATE_EARLY_STATUS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."UPDATE_EARLY_STATUS" AS 

BEGIN

      INSERT INTO appl_trans (ID, APPL_NO, TRANS_NO, STEP_CODE_PRV, STEP_CODE, OBJECT_FROM, OBJECT_TO, PROCESSOR_NO, ACCEPT_DATE, REMARK) 
			select APPL_TRANS_ID_SEQ.nextval, a.appl_no, null, a.step_code, '33', null, a.processor_no, a.processor_no, sysdate, 's193執行完成公開前審查'
      from appl_catg a,spt41 b,spt31b c
      where a.appl_no=b.appl_no and a.process_result=b.issue_type
      and a.process_result in ('49221','49223','49225','49273','49275')
      and FILE_D_FLAG='*' and a.step_code='27'
      and a.appl_no=c.appl_no and c.step_code ='60';
     
			update appl_catg set step_code='33',complete_date=sysdate
			where appl_no in (select a.appl_no
      from appl_catg a,spt41 b,spt31b c
      where a.appl_no=b.appl_no and a.process_result=b.issue_type
      and a.process_result in ('49221','49223','49225','49273','49275')
      and FILE_D_FLAG='*' and a.step_code='27'
      and a.appl_no=c.appl_no and c.step_code ='60' );
 

      INSERT INTO appl_trans (ID, APPL_NO, TRANS_NO, STEP_CODE_PRV, STEP_CODE, OBJECT_FROM, OBJECT_TO, PROCESSOR_NO, ACCEPT_DATE, REMARK) 
			select APPL_TRANS_ID_SEQ.nextval, a.appl_no, null, a.step_code, '70', null, a.processor_no, a.processor_no, sysdate, 's193執行不予公開'
      from appl_catg a,spt41 b,spt31b c
      where a.appl_no=b.appl_no and a.process_result=b.issue_type
      and a.process_result in ('49221','49223','49225','49273','49275')
      and FILE_D_FLAG='*' and a.step_code='27'
      and a.appl_no=c.appl_no and c.step_code ='70';
     
			update appl_catg set step_code='70',complete_date=sysdate
			where appl_no in (select a.appl_no
      from appl_catg a,spt41 b,spt31b c
      where a.appl_no=b.appl_no and a.process_result=b.issue_type
      and a.process_result in ('49221','49223','49225','49273','49275')
      and FILE_D_FLAG='*' and a.step_code='27'
      and a.appl_no=c.appl_no and c.step_code ='70' );


      /*
        ModifyDate:104/10/09
        --如果spt31b.step_code=70 AND appl_catg.step_code<70,則將appl_catg.step_code更變為70
      */
      /*
      INSERT INTO appl_trans (ID, APPL_NO, TRANS_NO, STEP_CODE_PRV, STEP_CODE, OBJECT_FROM, OBJECT_TO, PROCESSOR_NO, ACCEPT_DATE, REMARK) 
			select APPL_TRANS_ID_SEQ.nextval, a.appl_no, null, a.step_code, '70', null, a.processor_no, a.processor_no, null, 's193執行有不予公開'
      from appl_catg a, spt31b b
			where a.appl_no=b.appl_no 
			and b.step_code ='70' and a.step_code<'70';
     
      update appl_catg set step_code='70'
			where appl_no in (select a.appl_no
			from appl_catg a, spt31b b
			where a.appl_no=b.appl_no 
			and b.step_code ='70' and a.step_code<'70');
      */
      /*
        ModifyDate:104/10/09
        --如果spt31b.step_code=60 AND appl_catg.step_code='27' AND appl_catg.FILE_D_FLAG='*'
        ,則將appl_catg.step_code更變為33
      */
      /*
      INSERT INTO appl_trans (ID, APPL_NO, TRANS_NO, STEP_CODE_PRV, STEP_CODE, OBJECT_FROM, OBJECT_TO, PROCESSOR_NO, ACCEPT_DATE, REMARK) 
			select APPL_TRANS_ID_SEQ.nextval, a.appl_no, null, a.step_code, '33', null, a.processor_no, a.processor_no, null, 's193執行完成公開前審查'
      from appl_catg a,spt41 b,spt31b c
      where a.appl_no=b.appl_no and a.process_result=b.issue_type
      and a.process_result in ('49221','49223','49225','49273','49275')
      and FILE_D_FLAG='*' and a.step_code='27'
      and c.step_code ='60';
     
			update appl_catg set step_code='33'
			where appl_no in (select a.appl_no
      from appl_catg a,spt41 b,spt31b c
      where a.appl_no=b.appl_no and a.process_result=b.issue_type
      and a.process_result in ('49221','49223','49225','49273','49275')
      and FILE_D_FLAG='*' and a.step_code='27'
      and c.step_code ='60' );
      */
      /*
        ModifyDate:104/10/09
        --如果spt31b.step_code>=10 AND spt31b.step_code<=50 AND appl_catg.step_code='27' AND appl_catg.FILE_D_FLAG='*'
        ,則將appl_catg.step_code更變為70
      */
      /*
      INSERT INTO appl_trans (ID, APPL_NO, TRANS_NO, STEP_CODE_PRV, STEP_CODE, OBJECT_FROM, OBJECT_TO, PROCESSOR_NO, ACCEPT_DATE, REMARK) 
			select APPL_TRANS_ID_SEQ.nextval, a.appl_no, null, a.step_code, '70', null, a.processor_no, a.processor_no, null, 's193執行有不予公開'
      from appl_catg a,spt41 b,spt31b c
      where a.appl_no=b.appl_no and a.process_result=b.issue_type
      and a.process_result in ('49221','49223','49225','49273','49275')
      and FILE_D_FLAG='*' and a.step_code='27'
      and c.step_code>='10' and c.step_code<='50';
      
      update appl_catg set step_code='70',complete_date=sysdate
			where appl_no in (select a.appl_no
			from appl_catg a,spt41 b,spt31b c
			where a.appl_no=b.appl_no and a.process_result=b.issue_type
			and a.process_result in ('49221','49223','49225','49273','49275')
			and FILE_D_FLAG='*' and a.step_code='27'
			and c.step_code>='10' and c.step_code<='50');
      
      update spt31b set step_code='70'
			where appl_no in (select a.appl_no
			from appl_catg a,spt41 b,spt31b c
			where a.appl_no=b.appl_no and a.process_result=b.issue_type
			and a.process_result in ('49221','49223','49225','49273','49275')
			and FILE_D_FLAG='*' and a.step_code='27'
			and c.step_code>='10' and c.step_code<='50');
      */
END UPDATE_EARLY_STATUS;

/
--------------------------------------------------------
--  DDL for Procedure USER_TO_190
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."USER_TO_190" (p_in_emp in char,
                                        p_in_190 out varchar2) is
  -- 轉換e網通帳號成190帳號

begin

  SELECT PROCESSOR_NO
    into p_in_190
    FROM SPM63A
   WHERE EMP_CODE = p_in_emp
     AND SORT_ID = '1';

end user_to_190;

/
--------------------------------------------------------
--  DDL for Procedure VALIDATE_BIOMATERIAL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."VALIDATE_BIOMATERIAL" (
  p_in_process_result in char,
  p_in_biomaterial_array in biomaterial_tab,
  p_io_error_message_array in out nocopy pair_tab
)
is
  v_tmp_biomaterial biomaterial_obj;
  v_is_complete boolean := p_in_process_result in (
    '49213', '49215', '49217', '49269', '49271', '49207', '49209', '49211', '49221', '49223',
    '49225', '49265', '49267', '49269', '49271', '49273', '49275', '43191', '43199', '43001'
  );
  
  procedure add_error_message(p_message in varchar2)
  is
  begin
    p_io_error_message_array.extend;
    p_io_error_message_array(p_io_error_message_array.last) := pair_obj('', p_message);
  end add_error_message;
  
begin
  if p_in_biomaterial_array is null
      or p_in_biomaterial_array.count = 0 then
    return;
  end if;
  for l_idx in p_in_biomaterial_array.first .. p_in_biomaterial_array.last
  loop
    v_tmp_biomaterial := p_in_biomaterial_array(l_idx);
    if v_tmp_biomaterial.appl_no is null or v_tmp_biomaterial.data_seq is null then
      continue;
    end if;
    if trim(v_tmp_biomaterial.microbe_date) is null
      and trim(v_tmp_biomaterial.microbe_org_id) is null
      and trim(v_tmp_biomaterial.microbe_org_name) is null 
      and trim(v_tmp_biomaterial.microbe_appl_no) is null 
      and trim(v_tmp_biomaterial.national_id) is null then
      add_error_message('生物材料資訊(' || l_idx || ') 未輸入任何資料。');
      continue;
    end if;
    if v_tmp_biomaterial.microbe_date is not null 
      and not valid_date(v_tmp_biomaterial.microbe_date) then
      add_error_message('生物材料資訊(' || l_idx || ') 生物材料寄存日非正確西元日期格式。');
    end if;
    if trim(v_tmp_biomaterial.microbe_date) is null and v_is_complete then
      add_error_message('生物材料資訊(' || l_idx || ') 生物材料寄存日期為必填。');
    end if;
    if trim(v_tmp_biomaterial.microbe_org_id) is null and v_is_complete then
      add_error_message('生物材料資訊(' || l_idx || ') 寄存機關ID為必填。');
    end if;
    if trim(v_tmp_biomaterial.microbe_org_name) is null and v_is_complete then
      add_error_message('生物材料資訊(' || l_idx || ') 寄存機關為必填。');
    end if;
    if trim(v_tmp_biomaterial.microbe_appl_no) is null and v_is_complete then
      add_error_message('生物材料資訊(' || l_idx || ') 寄存申請案號為必填。');
    end if;
    if trim(v_tmp_biomaterial.national_id) is null and v_is_complete then
      add_error_message('生物材料資訊(' || l_idx || ') 寄存國家為必填。');
    end if;
  end loop;
end validate_biomaterial;

/
--------------------------------------------------------
--  DDL for Procedure VALIDATE_GRACE_PERIOD
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."VALIDATE_GRACE_PERIOD" (
  p_in_process_result in char,
  p_in_grace_period_array in grace_period_tab,
  p_io_error_message_array in out nocopy pair_tab)
is
  v_tmp_grace_period grace_period_obj;
  v_is_complete boolean := p_in_process_result in (
    '49213', '49215', '49217', '49269', '49271', '49207', '49209', '49211', '49221', '49223',
    '49225', '49265', '49267', '49269', '49271', '49273', '49275', '43191', '43199', '43001'
  );
  
  procedure add_error_message(p_message in varchar2)
  is
  begin
    p_io_error_message_array.extend;
    p_io_error_message_array(p_io_error_message_array.last) := pair_obj('', p_message);
  end add_error_message;
  
begin
  if p_in_grace_period_array is null
      or p_in_grace_period_array.count = 0 then
    return;
  end if;
  for l_idx in p_in_grace_period_array.first .. p_in_grace_period_array.last
  loop
    v_tmp_grace_period := p_in_grace_period_array(l_idx);
    if v_tmp_grace_period.appl_no is null or v_tmp_grace_period.data_seq is null then
      continue;
    end if;
    if trim(v_tmp_grace_period.novel_flag) is null
      and trim(v_tmp_grace_period.novel_item) is null
      and trim(v_tmp_grace_period.novel_date) is null then
      add_error_message('優惠期資訊(' || l_idx || ') 未輸入任何資料');
      continue;
    end if;
    if trim(v_tmp_grace_period.novel_item) is null and v_is_complete then
      add_error_message('優惠期資訊(' || l_idx || ') 主張款項為必填。');
    end if;
    if v_tmp_grace_period.novel_date is not null 
      and not valid_tw_date(v_tmp_grace_period.novel_date) then
      add_error_message('優惠期資訊(' || l_idx || ') 優惠日期非正確民國日期格式。');
    end if;
    if trim(v_tmp_grace_period.novel_date) is null and v_is_complete then
      add_error_message('優惠期資訊(' || l_idx || ') 優惠日期為必填。');
    end if;
  end loop;
end validate_grace_period;

/
--------------------------------------------------------
--  DDL for Procedure VALIDATE_PRIORITY_RIGHT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."VALIDATE_PRIORITY_RIGHT" (
  p_in_process_result in char,
  p_in_appl_date in char,
  p_in_priority_right_array in priority_right_tab,
  p_io_error_message_array in out nocopy pair_tab
)
is
  v_tmp_priority_right priority_right_obj;
  v_tmp_num number(4);

  procedure add_error_message(p_key in varchar2, p_message in varchar2)
  is
  begin
    p_io_error_message_array.extend;
    p_io_error_message_array(p_io_error_message_array.last) := pair_obj(p_key, p_message);
  end add_error_message;

  procedure add_error_message(p_message in varchar2)
  is
  begin
    add_error_message('', p_message);
  end add_error_message;

begin
  if p_in_priority_right_array is null
    or p_in_priority_right_array.count = 0 then
    return;
  end if;
  for l_idx in p_in_priority_right_array.first .. p_in_priority_right_array.last
  loop
    v_tmp_priority_right := p_in_priority_right_array(l_idx);
    if v_tmp_priority_right.appl_no is null or v_tmp_priority_right.data_seq is null then
      continue;
    end if;
    if trim(v_tmp_priority_right.priority_flag) is null then
      add_error_message('國內外優先權資料(' || l_idx || ') 不受理註記未輸入');
    end if;
    if v_tmp_priority_right.priority_date is not null
      and not valid_date(v_tmp_priority_right.priority_date) then
      add_error_message('國內外優先權資料(' || l_idx || ') 優先權日期非正確西元日期格式');
    end if;
    if v_tmp_priority_right.priority_flag = 1 then
      if trim(v_tmp_priority_right.priority_nation_id) is null then
        if p_in_process_result in (
            '49213', '43191', '43199', '43001', '49217', '43015', '49215', '43009', '49243') then
          add_error_message('PROCESS_RESULT', '國內外優先權資料(' || l_idx || ') 國家名稱不可空白，請確認!');
        end if;
      end if;
      if trim(v_tmp_priority_right.priority_date) is null then
        if p_in_process_result in (
            '49213', '43191', '43199', '43001', '49217', '43015', '49215', '43009', '49243') then
          add_error_message('PROCESS_RESULT', '國內外優先權資料(' || l_idx || ') 優先權日期資料不可空白，請確認!');
        end if;
      else
        if valid_tw_date(p_in_appl_date)
          and v_tmp_priority_right.priority_date >= p_in_appl_date + 19110000
          and p_in_process_result in (
            '49213', '43191', '43199', '43001', '49217', '43015', '49215', '43009', '49243') then
          add_error_message('PROCESS_RESULT', '國內外優先權資料(' || l_idx || ') 晚於或等於申請日，請確認!');
        end if;
      end if;
    end if;
    if v_tmp_priority_right.priority_revive = '1' and nvl(v_tmp_priority_right.priority_flag, 'X') != '1' then
      add_error_message('國內外優先權資料(' || l_idx || ') 優先權復權只能選擇優先權受理，請重新輸入!');
    end if;
    if trim(v_tmp_priority_right.access_code) is not null
      or trim(v_tmp_priority_right.ip_type) is not null then
      select count(1)
        into v_tmp_num
        from spmz9
       where sys_id ='03'
         and class_id ='ACC'
         and trim(code_id) = trim(v_tmp_priority_right.priority_nation_id);
      if v_tmp_num = 0 then
        add_error_message('國內外優先權資料(' || v_tmp_priority_right.data_seq || ') 非開放優先權交換國家，不可填寫存取碼及專利類型');
      end if;
    end if;
    if p_in_process_result in ('49213', '49215', '49217', '49269', '49271', '43191', '43199', '43001', '43009', '43015')
      and v_tmp_priority_right.priority_flag in ('1', '3') then
      if nvl(v_tmp_priority_right.priority_doc_flag, 'N') != 'Y' and trim(v_tmp_priority_right.access_code) is null then
        add_error_message('PROCESS_RESULT', '國內外優先權資料(' || l_idx || ') 辦理齊備：該案有主張優先權且無不受理或撤回之註記，其「存取碼」或「已送優先權證明文件」二個欄位，必須二者其中有資料，才容許製稿或存檔!');
      end if;
      if trim(v_tmp_priority_right.access_code) is not null and trim(v_tmp_priority_right.ip_type) is null then
        add_error_message('PROCESS_RESULT', '國內外優先權資料(' || l_idx || ') 辦理齊備：該案有「存取碼」必須有專利類型，才容許製稿或存檔。');
      end if;
    end if;
  end loop;
end validate_priority_right;

/
