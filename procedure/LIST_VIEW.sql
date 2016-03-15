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
   ModifyDate: 105/01/09
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
   104/11/20: 紙本個人持有不用排除已監印
   104/12/14: 紙本個人持有仍要參考spt23
   104/12/21: 紙本持有不用再判斷912
   104/12/23: 個人線上辦結條件再加判斷階段別
   105/01/07: update  S_NEW_P, S_APPEND_P
   105/01/08: add condition for paper receive:  spt21.accept_date >= '1050101'
   105/02/03: 增加紙本已領未簽
   105/02/16: 人工分辦加條件AND  doc_complete = '1'
  */

  if p_in_type in ('TODO', 'DONE', 'REJECTED') then
    -- 線上 公文 已銷號 主管退辦
    OPEN p_out_list FOR
      SELECT R.RECEIVE_DATE,
             R.RECEIVE_NO,
             RECEIVE.APPL_NO,
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
                 and s56.record_date > receive.process_date) FORM_FILE_A
        FROM SPT21 R
        LEFT JOIN SPM75 T
          ON R.TYPE_NO = T.TYPE_NO
        JOIN RECEIVE
          ON R.RECEIVE_NO = RECEIVE.RECEIVE_NO
      --    AND R.APPL_NO = RECEIVE.APPL_NO
        LEFT JOIN SPM56 s56
          ON s56.receive_no = R.receive_no
         and s56.processor_no = R.processor_no
         and s56.record_date >= RECEIVE.process_date
        LEFT JOIN ap.sptd02 sd02
          ON s56.form_file_a = sd02.form_file_a
       WHERE R.PROCESSOR_NO = p_in_proccess_no
         AND case
               when R.PROCESS_RESULT is null AND RECEIVE.RECEIVE_NO is not null then
                '2'
               when receive.step_code = '5' AND R.process_result != '57001' and
                    substr(RECEIVE.processor_no, 1, 1) != 'P' then
                '5'
               when R.PROCESS_RESULT is not null AND receive.step_code < '5' AND
                    R.process_result != '57001' AND
                    return_no not in ('4', 'A', 'B', 'C', 'D') then
                '3'
             end = p_in_code
         AND RECEIVE.step_code > '0'
         AND RECEIVE.step_code < '8'
         AND (s56.form_file_a is null or
             s56.form_file_a =
             (select max(form_file_a)
                 from spm56
                where s56.receive_no = spm56.receive_no
                  and s56.processor_no = spm56.processor_no));
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
        JOIN SPT23
          ON R.receive_no = SPT23.receive_no
         AND R.OBJECT_ID = Spt23.OBJECT_TO
         and R.trans_seq = spt23.data_seq
        LEFT JOIN SPM75 T
          ON R.TYPE_NO = T.TYPE_NO
       WHERE R.ACCEPT_DATE >= '1050101'
         AND PROCESS_RESULT IS NULL
         AND R.object_id = p_in_proccess_no
      --  AND R.trans_no = '912'  -- mark by susan 104/12/21
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
        JOIN SPT23
          ON SPT21.receive_no = SPT23.receive_no
         and SPT21.OBJECT_ID = Spt23.OBJECT_TO
         and spt21.trans_seq = spt23.data_seq
        LEFT JOIN SPM75
          on SPT21.TYPE_NO = SPM75.TYPE_NO
       WHERE PROCESS_RESULT IS NOT NULL
         and SPT21.object_id = p_in_proccess_no
            --     and SPT21.trans_no = '912'   -- mark by susan 104/12/21
         and process_result != '57001'
         and SPT21.ACCEPT_DATE >= '1050101';
    return;
  end if;

  if p_in_type in ('REJECTED_P') then
    -- 紙本 主管退辦 無值
    return;
    /*   
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
         */
  
  end if;

  if p_in_type in ('NEW', 'APPEND') then
    -- 線上 新申請 後續文
    OPEN p_out_list FOR
      SELECT R.RECEIVE_DATE,
             R.RECEIVE_NO,
             RECEIVE.APPL_NO,
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
         AND (R.process_result is null or R.process_result != '57001')
         AND doc_complete = '1'
         AND RETURN_NO not in ('4', 'A', 'B', 'C', 'D') -- 人工分辦
         AND SUBSTR(RECEIVE.RECEIVE_NO, 4, 1) = p_in_code;
    return;
  end if;

  if p_in_type = 'S_NEW' then
    -- 線上 新申請 後續文
    OPEN p_out_list FOR
      SELECT R.RECEIVE_DATE,
             R.RECEIVE_NO,
             RECEIVE.APPL_NO,
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
         AND doc_complete = '1'
         AND not exists (select 1
                from spt21
               where spt21.process_result = '57001'
                 and spt21.receive_no = receive.receive_no)
         AND SUBSTR(RECEIVE.RECEIVE_NO, 4, 1) = '2'
         AND R.online_flg = 'Y';
    return;
  end if;

  if p_in_type = 'S_APPEND' then
    -- 線上 新申請 後續文
    OPEN p_out_list FOR
      SELECT R.RECEIVE_DATE,
             R.RECEIVE_NO,
             RECEIVE.APPL_NO,
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
         AND doc_complete = '1'
         AND not exists (select 1
                from spt21
               where spt21.process_result = '57001'
                 and spt21.receive_no = receive.receive_no)
         AND SUBSTR(RECEIVE.RECEIVE_NO, 4, 1) = '3'
         AND R.online_flg = 'Y'
         ;
    return;
  end if;

  if p_in_type in ('NEW_P', 'APPEND_P') then
    --match for dashboard_sesion /DASHBOARD_PERSONAL   NEW_P, APPEND_P
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
         AND PROCESS_RESULT IS NULL
         AND (R.object_id = '70012' or R.object_id = '60037')
         AND R.accept_date >= '1050101';
    return;
  end if;

  if p_in_type = 'S_NEW_P' then
    -- match for dashboard_sesion  S_NEW_P
    -- 紙本全部 新申請 後續文
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
        JOIN spt23
          ON R.receive_no = spt23.receive_no
         AND R.trans_seq = spt23.data_seq
       WHERE (R.object_id = '70012' or R.object_id = '60037')
         AND R.accept_date >= '1050101'
         AND (R.process_result != '57001' or R.process_result is null)
         AND SUBSTR(R.RECEIVE_NO, 4, 1) = '2';
    return;
  end if;

  if p_in_type = 'S_APPEND_P' then
    -- match for dashboard_sesion   S_APPEND_P
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
        JOIN spt23
          ON R.receive_no = spt23.receive_no
         AND R.trans_seq = spt23.data_seq
       WHERE (R.object_id = '70012' or R.object_id = '60037')
         AND R.accept_date >= '1050101'
         AND (R.process_result != '57001' or R.process_result is null)
         AND SUBSTR(R.RECEIVE_NO, 4, 1) = '3';
    return;
  end if;

  if p_in_type in ('S_DIVIDE_R') then
    -- 人工分辦數
    OPEN p_out_list FOR
      SELECT R.RECEIVE_DATE,
             R.RECEIVE_NO,
             RECEIVE.APPL_NO,
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
      --   AND R.APPL_NO = RECEIVE.APPL_NO
       WHERE return_no in ('4', 'A', 'B', 'C', 'D')
         AND (R.process_result is null or R.process_result != '57001')
         AND step_code = '0'
         AND  doc_complete = '1'
         AND RECEIVE.PROCESSOR_NO IN
             (SELECT PROCESSOR_NO
                FROM SPM63
               WHERE DEPT_NO = '70012'
                 AND QUIT_DATE IS NULL
                  OR (PROCESSOR_NO = '70012'));
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
             RECEIVE.APPL_NO,
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
      --   AND R.APPL_NO = RECEIVE.APPL_NO
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
             RECEIVE.APPL_NO,
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
                          spmff.date_bc,
                          spt21.receive_no
                     FROM spt21
                     join ap.spmff
                       on spmff.date_bc <
                          to_number(substr(spt21.control_date, 1, 3)) + 1911 ||
                          substr(spt21.control_date, 4, 4)
                     JOIN receive
                       on spt21.receive_no = receive.receive_no
                    WHERE spmff.date_flag = 1
                      AND receive.processor_no IN
                          (SELECT PROCESSOR_NO
                             FROM SPM63
                            WHERE DEPT_NO = '70012'
                              AND QUIT_DATE IS NULL)) cdate
          on cdate.receive_no = receive.receive_no
       WHERE receive.step_code >= '2'
         AND receive.step_code < '8'
         AND (R.process_result != '57001' or R.process_result is null)
         AND cdate.d = 2
            --     AND  substr(to_char(to_number(receive.process_date) + 19110000),1,6)  = to_char(sysdate,'yyyyMM')
         AND to_char(sysdate, 'yyyyMMdd') between cdate.date_bc and
             to_number(substr(R.control_date, 1, 3)) + 1911 ||
             substr(R.control_date, 4, 4)
         AND step_code < '4'
         AND R.PROCESSOR_NO = p_in_proccess_no;
    return;
  END if;

  if p_in_type = 'S_FOR_APPROVE' then
    -- 陳核中
    OPEN p_out_list FOR
      SELECT R.RECEIVE_DATE,
             R.RECEIVE_NO,
             RECEIVE.APPL_NO,
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
                          spmff.date_bc,
                          spt21.receive_no
                     FROM spt21
                     join ap.spmff
                       on spmff.date_bc <
                          to_number(substr(spt21.control_date, 1, 3)) + 1911 ||
                          substr(spt21.control_date, 4, 4)
                     JOIN receive
                       on spt21.receive_no = receive.receive_no
                    WHERE spmff.date_flag = 1
                      AND receive.processor_no IN
                          (SELECT PROCESSOR_NO
                             FROM SPM63
                            WHERE DEPT_NO = '70012'
                              AND QUIT_DATE IS NULL)) cdate
          on cdate.receive_no = receive.receive_no
       WHERE receive.step_code >= '2'
         AND receive.step_code < '8'
         AND (R.process_result != '57001' or R.process_result is null)
         AND cdate.d = 2
            --    AND  substr(to_char(to_number(receive.process_date) + 19110000),1,6)  = to_char(sysdate,'yyyyMM')
         AND to_char(sysdate, 'yyyyMMdd') between cdate.date_bc and
             to_number(substr(R.control_date, 1, 3)) + 1911 ||
             substr(R.control_date, 4, 4)
         and step_code = '4'
         AND R.PROCESSOR_NO = p_in_proccess_no;
    return;
  END if;

  if p_in_type = 'S_EXCEEDED' then
    -- 已逾期
    OPEN p_out_list FOR
      SELECT R.RECEIVE_DATE,
             R.RECEIVE_NO,
             RECEIVE.APPL_NO,
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
                          spmff.date_bc,
                          spt21.receive_no
                     FROM spt21
                     join ap.spmff
                       on spmff.date_bc <
                          to_number(substr(spt21.control_date, 1, 3)) + 1911 ||
                          substr(spt21.control_date, 4, 4)
                     JOIN receive
                       on spt21.receive_no = receive.receive_no
                    WHERE spmff.date_flag = 1
                      AND receive.processor_no IN
                          (SELECT PROCESSOR_NO
                             FROM SPM63
                            WHERE DEPT_NO = '70012'
                              AND QUIT_DATE IS NULL)) cdate
          on cdate.receive_no = receive.receive_no
       WHERE receive.step_code >= '2'
         AND receive.step_code < '8'
         AND (R.process_result != '57001' or R.process_result is null)
         AND cdate.d = 2
            --  AND substr(to_char(to_number(receive.process_date) + 19110000),1,6)  = to_char(sysdate,'yyyyMM')
         AND to_char(sysdate, 'yyyyMMdd') >
             to_number(substr(R.control_date, 1, 3)) + 1911 ||
             substr(R.control_date, 4, 4)
         AND R.PROCESSOR_NO = p_in_proccess_no;
    return;
  END if;

  if p_in_type = 'S_IMG_NOT_READY' then
    -- 逾期影像未到之線上公文
    OPEN p_out_list FOR
    
      SELECT spt21.receive_no,
             spt21.appl_no,
             spt21.receive_date,
             spt21.type_no || ' ' || spm75.type_name type_no,
             spm63.name_c object_id,
             spt21.dept_no
        FROM spt21
        join ap.spmff
          on spmff.date_bc > to_number(substr(spt21.RECEIVE_DATE, 1, 3)) + 1911 ||
             substr(spt21.RECEIVE_DATE, 4, 4)
        left join spm75
          on spm75.type_no = spt21.type_no
        left join spm63
          on spm63.processor_no = spt21.processor_no
       WHERE spmff.date_flag = 1
         and spmff.date_bc <= to_char(sysdate, 'yyyyMMdd')
         and spt21.online_flg = 'Y'
         and spt21.dept_no = '70012'
         and (spt21.process_result != '57001' or
             spt21.process_result is null)
         and exists (select 1
                from receive
               where receive.receive_no = spt21.receive_no
                 and doc_complete = '0'
                 and is_postpone = '0')
       group by spt21.receive_no,
                spt21.appl_no,
                spt21.receive_date,
                spt21.type_no || ' ' || spm75.type_name,
                spm63.name_c,
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
             (select type_no || ' ' || type_name
                from spm75
               where type_no = spt21.type_no) type_no,
             (select name_c
                from spm63
               where processor_no = spt21.processor_no) object_id,
             (select dept_no
                from spm63
               where processor_no = spt21.processor_no) dept_no
        from spt21
       where online_flg = 'Y'
         and (spt21.process_result != '57001' or
             spt21.process_result is null)
         and processor_no not in
             (select processor_no
                from spm63
               where dept_no in ('70012', '70014')
                 and quit_date is null)
         and processor_no not in ('70012', '70014');
    return;
  END if;

  -- 紙本已領未簽
  if p_in_type in ('UNSIGN_NEW_P', 'UNSIGN_APPEND_P') then
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
        JOIN spt23
          ON R.receive_no = spt23.receive_no
         AND R.trans_seq = spt23.data_seq
        LEFT JOIN SPM75 T
          ON R.TYPE_NO = T.TYPE_NO
       WHERE spt23.TRANS_NO = '912'
         AND spt23.ACCEPT_DATE IS NULL
         AND spt23.OBJECT_TO = p_in_proccess_no
         AND (R.process_result = '57001' or R.process_result is null)
         AND SUBSTR(R.RECEIVE_NO, 4, 1) = p_in_code;
    return;
  end if;

  raise_application_error(-20001,
                          'please check your p_in_type parameter, maybe not in LIST_VIEW procedure!');

end LIST_VIEW;

/
