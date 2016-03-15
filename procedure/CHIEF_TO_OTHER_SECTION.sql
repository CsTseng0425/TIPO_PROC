--------------------------------------------------------
--  DDL for Procedure CHIEF_TO_OTHER_SECTION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CHIEF_TO_OTHER_SECTION" (p_in_receive_no   in char,
                                                   p_in_processor_no in char,
                                                   p_out_msg         out varchar2) is
  l_receive_no    char(15);
  l_process_result    char(5);
  l_OUT_RESULT number;
begin
  /*----------------
  -- ModifyDate: 104/10/08
  -- 科長退他科
  -- Modify Items: (1) 5/20 : add to receive_trans_log
                   (2) 5/21 : change step_code from 1 to 8
                   (3) change receive_trans_log schema
                   (4)  return_no = '0'
                
 */ 
   ---------------------
    -- record receive transfer history
    ---------------------
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no , '70014','B',sysdate,'他科待辦'
      from receive
       Where receive_no = p_in_receive_no;
  
  select receive.receive_no  , spt21.process_result
    into l_receive_no, l_process_result
    from receive join spt21 on receive.receive_no = spt21.receive_no
   where receive.receive_no = p_in_receive_no;
   
   
   
  update receive
     set processor_no = '70014', step_code = 'B' , return_no = '0'
   Where receive_no = p_in_receive_no;
   
   update spt21
     set processor_no = '70014', process_result = null
   Where receive_no = p_in_receive_no;

 
  p_out_msg := p_in_receive_no || ' 退他科成功';

end CHIEF_TO_OTHER_SECTION;

/
