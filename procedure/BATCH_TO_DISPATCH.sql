--------------------------------------------------------
--  DDL for Procedure BATCH_TO_DISPATCH
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_TO_DISPATCH" (p_in_batch_no   in varchar2,
                                              p_in_batch_seq  in number,
                                              p_in_receive_no in char) is
      l_has_append char(1);
      l_appl_no char(15);                                              
begin
/*
Modify: 104/09/07
 退人工分辦; 退文註記改為: 4:退人工分辦; 收文狀態改為:待領;清空辦理結果
 原則:同案全退
 (1) update return_no = 4 step_code = 0 processor_no=70012 process_result = null
 (2) return all receive with the same project
 (3) update batch_detail set is_rejected=1
 (4) clear merge relation 
 1040706: update return_no = 'B' where return_no = '4'
 1040907: 清除併辦狀態
*/
 select appl_no into l_appl_no
                      from batch_detail
                     where batch_seq = p_in_batch_seq
                       and batch_no = p_in_batch_no
                       and receive_no = p_in_receive_no
                       ;
   l_has_append := batch_has_append(l_appl_no);
   ---------------------
    -- record receive transfer history
    ---------------------
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no , '70012','0',
              sysdate,'查驗人工分辦'
      from receive
      Where appl_no = (select appl_no
                      from batch_detail
                     where batch_seq = p_in_batch_seq
                       and batch_no = p_in_batch_no
                       and receive_no = p_in_receive_no);


   
    Update receive
    Set return_no = 'B', step_code = '0' , processor_no = '70012', merge_master = null 
    Where appl_no = l_appl_no;
                       
    update batch_detail 
    set IS_REJECTED = '1'
     , reason = case when l_has_append = '1'
                     then '另有後續文' 
                     else ''
                      end 
    where batch_seq = p_in_batch_seq
                       and batch_no = p_in_batch_no
                       and receive_no = p_in_receive_no
   ;
                     
    update spt21
    set processor_no = '70012', process_result = null ,  pre_exam_date = null , pre_exam_qty = null
    where  appl_no = l_appl_no; 

end BATCH_TO_DISPATCH;

/
