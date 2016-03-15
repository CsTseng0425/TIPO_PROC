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
        だ
  6/30: ウ癶快,恨だ,絏ご"癶快'
  104/09/16 : show the project processor_no form 193 table ,not 190 spt31
   */

  SELECT COUNT(1) INTO v_count FROM APPL WHERE APPL_NO = p_in_appl_no;
  
   

  if v_count = 0 then
    p_out_msg := '腹 ' || p_in_appl_no || ' ぃ';
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
      p_out_msg := 'ン ' || p_in_appl_no || ' ぃ琌ずΤ';
    return;
  end if;
  */

  SELECT COUNT(1)
    INTO v_count
    FROM SPT21
   WHERE SPT21.APPL_NO = p_in_appl_no
     AND PROCESS_RESULT IS NULL;

  if v_count > 0 then
    p_out_msg := 'ン ' || p_in_appl_no || ' 快い,ぃだ';
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
  
    p_out_msg := 'ンΤ┯快'|| processor_name || '琌璶眏だ?';
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
  p_out_msg := '腹 ' || p_in_appl_no || 'だ快Θ';
  return;

end case_divide;

/
