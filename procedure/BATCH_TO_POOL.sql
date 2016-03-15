--------------------------------------------------------
--  DDL for Procedure BATCH_TO_POOL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_TO_POOL" (p_in_batch_no   in varchar2,
                                          p_in_batch_seq  in number,
                                          p_in_receive_no in char) is
      l_has_append char(1);
      l_appl_no char(15);
      l_out_msg varchar2(100);
      l_rec_cnt number;
begin
/*
Modify: 104/09/07
退領辦區,辦理結果清空;不由批號中移除,只改變狀態為1 (退辦)
(1) update receive set step_code=0 return_no =2 processor_no = 70012 process_result=null
(2) return all receive with the same project
(3) update batch_detail set is_rejected=1
(4) call check_receive
(5) exists merge receive, then clear the merge relation
1040907: 清除併辦狀態
*/
l_rec_cnt:=0;
  select appl_no into l_appl_no
                      from batch_detail
                     where batch_seq = p_in_batch_seq
                       and batch_no = p_in_batch_no
                       and receive_no = p_in_receive_no
                       ;
   l_has_append := batch_has_append(l_appl_no);
   
      delete tmp_get_receive  
      where receive_no in 
      (select receive_no from receive where appl_no = (select appl_no from receive
        where receive_no = p_in_receive_no)
      );
 ---------------------
    -- record receive transfer history
    ---------------------
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no , '70012','0',
              sysdate,'查驗退領辦區'
      from receive
      Where appl_no = l_appl_no;
            
   
      l_rec_cnt := l_rec_cnt +  SQL%RowCount;
   update receive
     set step_code = '0' ,RETURN_NO = '2' , processor_no = '70012' , merge_master = null
   where appl_no =l_appl_no;
   l_rec_cnt := l_rec_cnt +  SQL%RowCount;
         
                       
   update spt21
     set processor_no = '70012', process_result = null ,  pre_exam_date = null , pre_exam_qty = null
   where receive_no in (select receive_no
                      from receive
                     where appl_no = l_appl_no); 
                       
  update batch_detail 
  set IS_REJECTED = '1'
     , reason = case when  l_has_append = '1'
                     then '另有後續文' 
                     else ''
                      end 
  where batch_seq = p_in_batch_seq
                       and batch_no = p_in_batch_no
                       and receive_no = p_in_receive_no
  ;
  commit;
   CHECK_RECEIVE('0',l_rec_cnt,l_out_msg);
   dbms_output.put_line('finish');
 
end BATCH_TO_POOL;

/
