--------------------------------------------------------
--  DDL for Procedure CHIEF_TO_PROCESSOR
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CHIEF_TO_PROCESSOR" (p_in_receive_no   in char,
                                                         p_in_processor_no  in char,
                                                         p_from_processor_no   in char,
                                                         p_out_msg         out varchar2) is
      l_count number;
begin
  /*  
  Modify: 105/02/18
     癶ㄤウ┯快
      盢そゅ簿у腹,э┯快﹚┯快, そゅ篈э:快
       (1) update  step_code = 2 processor_no = ?
       (2)change receive_trans_log schema
       (3)  return_no = '0'
       (4) update process_date
      104/07/08: add parameter for return from who:  p_from_processor_no 
      104/07/14: update return_no for dispalying on return mark
      104/09/11: update spt31.sch_processor_no
      104/11/30:ン┯快糶appl.processor_no
      105/02/18: update tmp_get_receive, call check_receive
  */
  
  ---------------------
    -- record receive transfer history
    ---------------------
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no , p_in_processor_no,'2',sysdate, p_from_processor_no ||' 癶ㄤウ┯快'
      from receive
       Where receive_no = p_in_receive_no;
       

  update receive
     Set processor_no = trim(p_in_processor_no), step_code = '2' , return_no = '5', process_date = to_char(to_number(to_char(sysdate,'yyyyMMdd'))-19110000)
      , object_id = trim(p_from_processor_no)
   Where receive_no = p_in_receive_no;
    --砆ㄖそゅ癬癶
   update receive
     set step_code = '0' ,RETURN_NO = 'A' , processor_no = '70012', merge_master = null 
   where merge_master = p_in_receive_no;

  update spt21
     Set processor_no = trim(p_in_processor_no) , process_result = null , pre_exam_date = null , pre_exam_qty = null
   Where receive_no = p_in_receive_no;
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
    
  p_out_msg := trim(p_in_receive_no) || ' 癶┯快Θ';

end CHIEF_TO_PROCESSOR;

/
