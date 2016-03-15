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
  ModifyDate : 104/10/08
  Desc: Department Major Assign Project:
        �������
  6/30: ����h���,�D�ޤ���,�N�X����"�L��h��'
  104/09/16 : show the project processor_no form 193 table ,not 190 spt31
   */

  SELECT COUNT(1) INTO v_count FROM APPL WHERE APPL_NO = p_in_appl_no;
  
   

  if v_count = 0 then
    p_out_msg := '�׸� ' || p_in_appl_no || ' ���s�b';
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
      p_out_msg := '�ץ� ' || p_in_appl_no || ' ���O�줺����';
    return;
  end if;
  */

  SELECT COUNT(1)
    INTO v_count
    FROM SPT21
   WHERE SPT21.APPL_NO = p_in_appl_no
     AND PROCESS_RESULT IS NULL;

  if v_count > 0 then
    p_out_msg := '�ץ� ' || p_in_appl_no || ' �ݿ줤,���i����';
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
  
    p_out_msg := '���ץ�w���ӿ�H'|| processor_name || '�A�O�_�n�j�����?';
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
  p_out_msg := '�׸� ' || p_in_appl_no || '���즨�\';
  return;

end case_divide;

/
