--------------------------------------------------------
--  DDL for Procedure DASHBOARD_SECTION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."DASHBOARD_SECTION" (P_IN_OBJECT_ID    in varchar2,
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
                                              S_NOT_SECTION     out varchar2) -- �����̳����O 70012/70014 ���u�W����
 is
   min_date receive.process_date%type;
begin
  /*
   Desc: Dashboard of manager
   ModifyDate : 105/01/08
   (1) update S_THISMON_TODO (�w��׼�) judge by  step_code
   (2) S_TO_EXCEED,S_FOR_APPROVE,S_EXCEEDED ���Ʋέp
    104/6/26: Modify �w��׼�
    104/07/09 : change the condition for calcuate close receive (S_THISMON_DONE) by sign_date (close date of form)
    104/07/30 : turning �ȥ��w�⥼ñ , select spt23 ,not spt21
    104/07/31: update the condition for accept date
    104/08/10: add S_IMG_NOT_READY and S_NOT_SECTION
    104/09/09: exclude the receives which process_result = 57001
    104/09/24: tune the performance for return-paper-recieve
    104/10/07: �վ�w�q=> ���� �u�W �s�ӽ� �����: �u�W�i��+�H�u����
    104/11/13: �վ�έp����: �����̳����O 70012/70014 ���u�W����,�P�M�����
    104/11/20: �ȥ��ӤH�������αư��w�ʦL
    104/12/14: �ȥ��ӤH�������n�Ѧ�spt23
    104/12/21: �ȥ��������ΦA�P�_912
    104/12/23: �ӤH�u�W�쵲����A�[�P�_���q�O
    105/01/08: add condition for paper receive:  spt21.accept_date >= '1050101'
               SPSB36 => spmff
    105/01/28: �ȥ����P���W�[���� �P�_ spt23
    105/02/16: �H�u����[����AND  doc_complete = '1'
  */
  --  �u�W�i�� �s�ӽ� �����     
  SELECT COUNT(CASE
                 WHEN SUBSTR(RECEIVE.RECEIVE_NO, 4, 1) in ('1', '2') THEN
                  1
                 ELSE
                  null
               END),
         COUNT(CASE
                 WHEN SUBSTR(RECEIVE.RECEIVE_NO, 4, 1) = '3' THEN
                  1
                 ELSE
                  null
               END)
    INTO NEW_A, APPEND_A
    FROM RECEIVE
    JOIN SPT21 s21 ON s21.RECEIVE_NO = RECEIVE.RECEIVE_NO 
     WHERE  STEP_CODE ='0'
     AND  doc_complete = '1'
     AND return_no not in ('4','A','B','C','D')
     AND not exists (select 1 from spt21 where spt21.process_result = '57001' and spt21.receive_no = receive.receive_no)
     AND s21.online_flg = 'Y'
     ;

  --  �ȥ��i�� �s�ӽ� �����
  SELECT COUNT(CASE
                 WHEN SUBSTR(spt21.RECEIVE_NO, 4, 1) = '2' THEN
                  1
                 ELSE
                  NULL
               END),
         COUNT(CASE
                 WHEN SUBSTR(spt21.RECEIVE_NO, 4, 1) = '3' THEN
                  1
                 ELSE
                  NULL
               END)
    INTO NEW_P, APPEND_P
   from spt21 join spt23
   ON SPT21.receive_no = SPT23.receive_no
   and SPT21.object_id = Spt23.OBJECT_TO
   and spt21.trans_seq = spt23.data_seq
   WHERE PROCESS_RESULT IS NULL
     AND ( spt21.object_id  = '70012' or spt21.object_id  = '60037' )
     AND  spt21.accept_date >= '1050101'
    ;

  -- ���� �u�W �s�ӽ� �����: �u�W�i��+�H�u����
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
     WHERE  STEP_CODE ='0'
     AND  doc_complete = '1'
     AND not exists (select 1 from spt21 where spt21.process_result = '57001' and spt21.receive_no = receive.receive_no)
     AND SPT21.online_flg = 'Y'
       ;

  --  �ȥ����� �s�ӽ� �����
  select COUNT(CASE  WHEN SUBSTR(spt21.RECEIVE_NO, 4, 1) = '2' THEN    1
                 ELSE    NULL        END),
         COUNT(CASE  WHEN SUBSTR(spt21.RECEIVE_NO, 4, 1) = '3' THEN    1
                 ELSE    NULL        END)
    INTO S_NEW_P, S_APPEND_P
  from spt21 join spt23
   ON SPT21.receive_no = SPT23.receive_no
   and spt21.trans_seq = spt23.data_seq
  where ( spt21.object_id  = '70012' or spt21.object_id  = '60037' )
  and (spt21.process_result !='57001' or spt21.process_result is null)
  and  spt21.accept_date >= '1050101'
  ;

  -- �u�W ���� �w�P�� �D�ްh��
  SELECT COUNT(CASE WHEN s21.PROCESS_RESULT is null  AND RECEIVE.RECEIVE_NO is not null THEN 1 ELSE NULL END) AS TODO,
          COUNT(CASE WHEN s21.PROCESS_RESULT is not null AND RECEIVE.step_code < '5'  AND s21.process_result != '57001'  AND return_no not in ('4','A','B','C','D')  THEN 1 ELSE NULL END) AS DONE,
          COUNT(CASE WHEN RECEIVE.step_code = '5' AND s21.process_result != '57001' and substr(SPM63.processor_no,1,1) != 'P' 
               THEN 1 ELSE NULL END) AS REJECTED
    INTO S_TODO, S_DONE, S_REJECTED
     FROM SPM63 LEFT JOIN RECEIVE  ON   SPM63.PROCESSOR_NO = RECEIVE.PROCESSOR_NO 
      JOIN SPT21 s21 ON s21.RECEIVE_NO = RECEIVE.RECEIVE_NO 
      WHERE SPM63.DEPT_NO='70012' AND SPM63.QUIT_DATE IS NULL    
      AND RECEIVE.step_code > '0'
      AND RECEIVE.step_code < '8'
      ;

  -- �ȥ� ����
  SELECT COUNT(1)
    INTO S_TODO_P
    FROM SPT21
    JOIN SPT23
      ON SPT21.receive_no = SPT23.receive_no
     AND SPT21.object_id = Spt23.OBJECT_TO
     and spt21.trans_seq = spt23.data_seq
   WHERE  spt21.trans_seq = spt23.data_seq
     AND PROCESS_RESULT IS NULL
     AND SPT21.object_id IN (SELECT PROCESSOR_NO
                         FROM SPM63
                        WHERE DEPT_NO = '70012'
                          AND QUIT_DATE IS NULL)
     AND  spt21.accept_date >= '1050101'                          
  --   AND SPT21.trans_no = '912'  -- mark by susan 104/12/21
    ;

  -- �ȥ� �w�P��
  SELECT COUNT(1)
    INTO S_DONE_P
    FROM SPT21
     JOIN SPT23
       ON SPT21.receive_no = SPT23.receive_no    and SPT21.OBJECT_ID = Spt23.OBJECT_TO  and spt21.trans_seq = spt23.data_seq
    WHERE  PROCESS_RESULT IS NOT NULL
     AND  PROCESS_RESULT != '57001'
     AND  spt21.accept_date >= '1050101'
 --    AND NOT EXISTS (SELECT RECEIVE_NO FROM SPT41 WHERE RECEIVE_NO = SPT21.RECEIVE_NO and processor_no = SPT21.processor_no and check_datetime is not null)
     AND object_id IN (SELECT PROCESSOR_NO
                         FROM SPM63
                        WHERE DEPT_NO = '70012'
                          AND QUIT_DATE IS NULL)
  --  AND SPT21.trans_no = '912'  -- mark by susan 104/12/21
    ;

  -- �ȥ��D�ްh��
  /*
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
     AND a.OBJECT_FROM in ( select processor_no from spm63 where substr(dept_no,1,3) = '700' and title  in ('���','�M���e��','���')  
         and processor_no = B.processor_no
        and spm63.quit_date is not null
      )
     AND B.TRANS_NO = '913'
     AND B.OBJECT_TO = SPT21.object_id
     AND A.DATA_SEQ = B.DATA_SEQ + 1
     AND SPT21.PROCESSOR_NO IS NOT NULL;
     */
     -- �ȥ��D�ްh��
     -- doesnot need to calculate
       SELECT ''
    INTO S_REJECTED_P
    from dual;

  -- �ȥ��w�⥼ñ �s�רӤ� ����Ӥ�
     SELECT COUNT(CASE WHEN SUBSTR(spt21.RECEIVE_NO,4,1) = '2' THEN 1 ELSE NULL END),
           COUNT(CASE WHEN SUBSTR(spt21.RECEIVE_NO,4,1) = '3' THEN 1 ELSE NULL END)
    INTO S_UNSIGN_NEW, S_UNSIGN_APPEND
    FROM SPT21
    JOIN spt23
    ON spt21.receive_no = spt23.receive_no   AND spt21.trans_seq = spt23.data_seq 
    WHERE  spt23.TRANS_NO = '912'
     AND spt23.ACCEPT_DATE IS NULL
     AND spt23.OBJECT_TO  IN (SELECT PROCESSOR_NO
                         FROM SPM63
                        WHERE DEPT_NO = '70012'
                          AND QUIT_DATE IS NULL)
     AND  (spt21.process_result = '57001'  or spt21.process_result  is null)
     ;

  -- �H�u����
  -- SELECT COUNT(1) INTO S_DIVIDE_C FROM APPL WHERE DIVIDE_CODE = '4'; -- ��
  SELECT COUNT(1)
    INTO S_DIVIDE_R
    FROM RECEIVE
   WHERE RETURN_NO in ('4', 'A', 'B', 'C','D')
     AND STEP_CODE = '0'
     AND  doc_complete = '1'
     AND not exists ( select 1 from spt21 where spt21.receive_no = RECEIVE.receive_no and spt21.process_result = '57001') 
     ; -- ��

  -- ������� 

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

  

  --- ���쵲
  select nvl(sum(1), 0)
    into S_THISMON_DONE
    from receive
   where step_code = '8'
     AND substr(to_char(to_number(sign_date) + 19110000), 1, 6) =
         to_char(sysdate, 'yyyyMM')
     AND not exists ( select 1 from spt21 where spt21.receive_no = RECEIVE.receive_no and spt21.process_result = '57001')     
         ;
         
  
  select min(yyyy||mm) into min_date from quota;
  
   SELECT  c.s -r.d  into S_LASTMON_ACC -- �W��֭p
      FROM (
           SELECT  sum(nvl(b.base, 0) * nvl(mday.days, 0) + nvl(a.factor, 0)) d
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
            and a.yyyy || a.mm >=  min_date
            and a.yyyy || a.mm  <=  to_char(add_months(sysdate,-1),'yyyyMM')
            ) r
          left join 
          (
        select nvl(sum(1),0) s
        from receive
        where step_code = '8'
         AND substr(to_char(to_number(sign_date) + 19110000),1,6) >=  min_date
        AND substr(to_char(to_number(sign_date) + 19110000),1,6) <= to_char(add_months(sysdate,-1),'yyyyMM')
       AND not exists ( select 1 from spt21 where spt21.receive_no = RECEIVE.receive_no and spt21.process_result = '57001') 
          )  c  on 1=1
            ;
   
  
  SELECT  c.s -  r.d    into S_ALL_ACC -- �����֭p
      FROM (
           SELECT  sum(nvl(b.base, 0) * nvl(mday.days, 0) + nvl(a.factor, 0)) d
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
            and a.yyyy || a.mm >=  min_date
            and a.yyyy || a.mm <= to_char(sysdate,'yyyyMM')
            ) r
          left join 
          (
        select nvl(sum(1),0) s
        from receive
        where step_code = '8'
         AND substr(to_char(to_number(sign_date) + 19110000),1,6) >=  min_date
         AND substr(to_char(to_number(sign_date) + 19110000),1,6)  <= to_char(sysdate,'yyyyMM')
        AND not exists ( select 1 from spt21 where spt21.receive_no = RECEIVE.receive_no and spt21.process_result = '57001') 
          )  c  on 1=1
            ;

  -- �ӤH�N�O��, �w�O��
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
     AND (spt21.process_result != '57001' or spt21.process_result is null)
     AND receive.processor_no IN
         (SELECT PROCESSOR_NO
            FROM SPM63
           WHERE DEPT_NO = '70012'
             AND QUIT_DATE IS NULL)
     AND cdate.d = 2;
     
     --- �ץ�O��
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

  -- �O���v�����줧�u�W����
  select count(1) into S_IMG_NOT_READY
  from (
      SELECT spt21.receive_no,
                    spt21.appl_no,
                    spt21.receive_date,
                    spt21.type_no,
                    spt21.processor_no,
                    spt21.dept_no
            FROM spt21
            join ap.spmff
              on spmff.date_bc > to_number(substr(spt21.RECEIVE_DATE, 1, 3)) + 1911 ||
                 substr(spt21.RECEIVE_DATE, 4, 4)
           WHERE spmff.date_flag = 1
             and  ( spt21.process_result !='57001' or spt21.process_result is null)
             and spmff.date_bc <= to_char(sysdate, 'yyyyMMdd')
             and spt21.online_flg = 'Y'
             and spt21.dept_no = '70012'
             and exists (select 1
                    from receive
                   where receive.receive_no = spt21.receive_no
                     and doc_complete = '0'
                     and is_postpone = '0')
           -- and not exists ( select 1 from doc where trim(receive_no) = trim(spt21.receive_no))
           group by spt21.receive_no,
                    spt21.appl_no,
                    spt21.receive_date,
                    spt21.type_no,
                    spt21.processor_no,
                    spt21.dept_no
          having count(1) > 7 );

  -- �����̳����O 70012/70014 ���u�W����

      select count(1) into S_NOT_SECTION
            from spt21
           where online_flg = 'Y'
         and (spt21.process_result != '57001' or spt21.process_result  is null)
         and processor_no not in
             (select processor_no
                from spm63
               where dept_no in ('70012', '70014')
                 and quit_date is null)
         and processor_no not in ('70012', '70014')
     ;
end dashboard_section;

/
