--------------------------------------------------------
--  DDL for Procedure SKILL_LIST
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SKILL_LIST" (p_out_list out sys_refcursor) is
begin
  --½ü¿ì²M³æ
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
