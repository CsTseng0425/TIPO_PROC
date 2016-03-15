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
    ModlfyDate : 104/12/21
    104/07/22 :  add conditin sptd02.flow_step = '02'
    104/08/02 : remove the condition from paper form status
    105/02/03 : add condition  sptd02.sign_user = get_loginuser
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
             AND sptd02.sign_user = get_loginuser
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
             AND sptd02.sign_user = get_loginuser
             AND substr(R.processor_no, 1, 1) != 'P');

end dashboard_chief;

/
