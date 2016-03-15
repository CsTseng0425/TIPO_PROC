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
  105/03/05 : 他科退辦 分辦事由改顯示欄位 divide_reason
*/

  open p_out_list for
    select p.APPL_NO, -- 案號
           S11.NAME_C as APPLIER_ID, -- 申請人
           appl.assign_date as ASSIGN_DATE, -- 分辦日期
           s41.FILE_LIM_DATE as FILE_LIM_DATE, -- 檔管日期
          ( select name_c from spm63 where processor_no = appl.processor_no ) as processor_no,
          case when  appl.divide_code in ('1','2')  then   appl.DIVIDE_REASON
              when   appl.divide_code = '3' then nvl(appl.DIVIDE_REASON, N'他科退辦')
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
