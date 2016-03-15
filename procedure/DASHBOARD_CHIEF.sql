--------------------------------------------------------
--  DDL for Procedure DASHBOARD_CHIEF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."DASHBOARD_CHIEF" (P_IN_OBJECT_ID    in varchar2,
                                            S_NEW             out varchar2, -- ���� �u�W �s�ӽ� 
                                            S_NEW_P           out varchar2, -- ���� �ȥ� �s�ӽ�
                                            S_APPEND          out varchar2, -- ���� �u�W �����
                                            S_APPEND_P        out varchar2, -- ���� �ȥ� �����
                                            NEW_A             out varchar2, -- �i�� �u�W �s�ӽ� 
                                            NEW_P             out varchar2, --�i�� �ȥ� �s�ӽ� 
                                            APPEND_A          out varchar2, -- �i�� �u�W ����� 
                                            APPEND_P          out varchar2, -- �i�� �ȥ� �����
                                            S_TODO            out varchar2, -- �u�W ����
                                            S_DONE            out varchar2, -- �u�W �w�P��
                                            S_REJECTED        out varchar2, -- �u�W �D�ްh��
                                            S_TODO_P          out varchar2, -- �ȥ� ����
                                            S_DONE_P          out varchar2, -- �ȥ� �w�P��
                                            S_REJECTED_P      out varchar2, -- �ȥ� �D�ްh��
                                            S_UNSIGN_NEW      out varchar2, -- �ȥ� �w�⥼ñ �s�רӤ�
                                            S_UNSIGN_APPEND   out varchar2, -- �ȥ� �w�⥼ñ ����Ӥ�
                                            S_DIVIDE_R        out varchar2, -- �H�u���� ��
                                            S_THISMON_TODO    out varchar2, -- �������
                                            S_THISMON_DONE    out varchar2, -- ���쵲
                                            S_LASTMON_ACC     out varchar2, -- �W��֭p
                                            S_ALL_ACC         out varchar2, -- �����֭p
                                            S_PERSONAL_EXCEED out varchar2, -- �ӤH�O��
                                            S_AUTO_SHIFT      out varchar2, -- �۰ʿ��
                                            S_OTHER_REJECTED  out varchar2, -- �L��h��
                                            S_CHIEF_DISPATCH  out varchar2, -- �������
                                            S_TO_EXCEED       out varchar2, -- �N�O��
                                            S_FOR_APPROVE     out varchar2, -- ���֤�
                                            S_EXCEEDED        out varchar2, -- �w�O��
                                            S_IMG_NOT_READY   out varchar2, -- �O���v�����줧�u�W����
                                            S_NOT_SECTION     out varchar2, -- �����̳����O 70012/70014 ���u�W����
                                            S_TO_APPROVE      out varchar2) -- �ݮ֤���
 is
begin
  /*
    �ݮ֤���: receiver list waiting for approved
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
            WHERE nvl(spm56.issue_flag, '0') = '1' -- �w�s�Z
              AND nvl(ONLINE_SIGN, '0') != '1' --�ȥ�
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
