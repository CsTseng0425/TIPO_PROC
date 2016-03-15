--------------------------------------------------------
--  DDL for Procedure CHIEF_TO_POOL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CHIEF_TO_POOL" (p_in_receive_no in char,
                                          p_out_msg       out varchar2) is
 l_out_msg varchar2(100);
 l_rec_cnt number;
begin

  /*
  Modify: 104/10/08
  科長退領辦區,辦理結果清空;若為外包不由批號中移除,只改變狀態為1 (退辦)
  (1) update receive set step_code=0 return_no =3 processor_no = 70012 process_result=null
  (2) return all receive with the same project
  (3) call check_receive
  (4) change receive_trans_log schema
 
  */
  l_rec_cnt :=0;
  
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
              receive.receive_no, receive.appl_no , '70012','0',sysdate,'退領辦區'
      from receive
       Where receive_no = p_in_receive_no;
        INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no , '70012','0',sysdate,'被併公文退領辦區'
      from receive
       Where merge_master = p_in_receive_no;

   

   update receive
     set step_code = '0', RETURN_NO = '3', processor_no = '70012'
   where receive_no = p_in_receive_no;
   l_rec_cnt := l_rec_cnt +  SQL%RowCount;
   --被併公文一起退
   update receive
     set step_code = '0' ,RETURN_NO = '3' , processor_no = '70012', merge_master = null 
   where merge_master = p_in_receive_no;
   l_rec_cnt := l_rec_cnt +  SQL%RowCount;
   update spt21
     set processor_no = '70012', process_result = null , pre_exam_date = null , pre_exam_qty = null , complete_date = null
   where receive_no = p_in_receive_no;
   update spt21
     set processor_no = '70012', process_result = null , pre_exam_date = null , pre_exam_qty = null , complete_date = null
   where receive_no = (select receive_no from  receive where merge_master =   p_in_receive_no);
    commit;
    CHECK_RECEIVE('0',l_rec_cnt,l_out_msg);
  dbms_output.put_line('finish');

  p_out_msg := p_in_receive_no || ' 退領辦區成功';

end CHIEF_TO_POOL;

/
