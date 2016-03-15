--------------------------------------------------------
--  DDL for Procedure PROCESSOR_TO_PROCESSOR
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."PROCESSOR_TO_PROCESSOR" (p_in_receive_no   in char,
                                               p_in_processor_no in char) is
begin
/*  
Modify: 104/12/01
     ┯快癶┯快:腹ぇそゅ场癬癶
    盢そゅ簿у腹,э┯快﹚┯快, そゅ篈э:快
     (1) update  step_code = 2 processor_no = ?
      104/12/01: update spt31.sch_processor_no
      104/12/01:ン┯快糶appl.processor_no
*/
  
   
  update receive
     Set processor_no = trim(p_in_processor_no), step_code = '2'
   Where  receive_no = p_in_receive_no;
   
    update spt21
     Set processor_no = trim(p_in_processor_no) 
    Where  receive_no = p_in_receive_no;
     --砆ㄖそゅ癬癶
   update spt21
     set processor_no = '70012', process_result = null , pre_exam_date = null , pre_exam_qty = null , complete_date = null
   where receive_no = (select receive_no from  receive where merge_master =   p_in_receive_no);
   
      update spt31
      set sch_processor_no= p_in_processor_no, phy_processor_no = p_in_processor_no
      where appl_no in
      (
        select appl_no from spt31a 
        where appl_no = (select appl_no from receive where receive_no = p_in_receive_no )
        and ((step_code between '10' and '19'  and step_code != '15')
              or step_code = '30'
              or step_code = '29'
              or step_code = '49'
              or ( exists (select 1 from spt21 where appl_no = spt31.appl_no and  type_no in ('16000','16002','22210')))
            )
      and substr(appl_no,10,1) != 'N');
      
    update appl
    set processor_no = p_in_processor_no
    where appl_no = ( select appl_no from receive  Where receive_no = p_in_receive_no)
    ;
     update tmp_get_receive set skill = p_in_processor_no
    where pre_no = p_in_receive_no
    ;

end PROCESSOR_TO_PROCESSOR;

/
