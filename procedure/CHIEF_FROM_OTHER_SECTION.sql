--------------------------------------------------------
--  DDL for Procedure CHIEF_FROM_OTHER_SECTION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CHIEF_FROM_OTHER_SECTION" (p_in_receive_no   in char,
                                                     p_out_msg         out varchar2) is
  l_receive_no    char(15);
  l_process_result    char(5);
  l_OUT_RESULT number;
begin
  /*----------------
     �L��h�줽��
     ModifyDate: 104/10/08
     parameter : p_in_receive_no : ����帹
                 p_out_msg: null :���榨�\ , error_message :���楢�ѰT��
 
 */ 
   ---------------------
    -- record receive transfer history
    ---------------------
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no , '70012','0',sysdate,'�L��h�줽��'
      from receive
       Where receive_no = p_in_receive_no;
  
  select receive.receive_no  , spt21.process_result
    into l_receive_no, l_process_result
    from receive join spt21 on receive.receive_no = spt21.receive_no
   where receive.receive_no = p_in_receive_no;
   
  
  update receive
     set processor_no = '70012', step_code = '0' , return_no = 'C' --�H�u����
   Where receive_no = p_in_receive_no;
   
   update spt21
     set processor_no = '70012'
   Where receive_no = p_in_receive_no;

 
  p_out_msg := p_in_receive_no || ' �L��h�줽�妨�\';

end CHIEF_FROM_OTHER_SECTION;

/
