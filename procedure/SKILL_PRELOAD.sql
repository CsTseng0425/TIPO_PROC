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
