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
