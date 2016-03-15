--------------------------------------------------------
--  DDL for Procedure CHIEF_TO_DISPATCH
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CHIEF_TO_DISPATCH" (p_in_receive_no in char,
                                              p_out_msg       out varchar2) is
begin
  /* 
  Modify: 104/10/08
  ��� �h�H�u����; �h����O�אּ: 5:�h�H�u����; ���媬�A�אּ:�ݻ�
   (1) update return_no = 4 step_code = 0 processor_no=70012 process_result = null
   (2) return all receive with the same project
   (3) update spt21.processor_no = 70012
   (4) change receive_trans_log schema
 
  */
  
    ---------------------
    -- record receive transfer history
    ---------------------
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no , '70012','0',sysdate,'�h�H�u����'
      from receive
       Where receive_no = p_in_receive_no;
       
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no , '70012','0',sysdate,'�Q�֤���h�H�u����'
      from receive
       Where merge_master = p_in_receive_no;



  
   Update receive
     Set  step_code = '0', return_no = 'A', processor_no = '70012'
   Where receive_no = p_in_receive_no;
    --�Q�֤���@�_�h
   update receive
     set step_code = '0' ,RETURN_NO = 'A' , processor_no = '70012', merge_master = null 
   where merge_master = p_in_receive_no;
 
   update spt21
     set process_result = null , pre_exam_date = null , pre_exam_qty = null, processor_no = '70012'
   where receive_no = p_in_receive_no;
   
   update spt21
     set processor_no = '70012', process_result = null , pre_exam_date = null , pre_exam_qty = null , complete_date = null
   where receive_no = (select receive_no from  receive where merge_master =   p_in_receive_no);
  
  commit;

  p_out_msg := p_in_receive_no || ' �h�H�u���즨�\';

end CHIEF_TO_DISPATCH;

/
