--------------------------------------------------------
--  DDL for Procedure CASE_DISPATCH
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CASE_DISPATCH" (p_in_receive_no   in char,
                                          p_in_processor_no in char,
                                          p_in_force        in char,
                                          p_out_msg         out varchar2) is
  v_count number;
begin
/*
Latest ModifyDate : 104/06/02
Desc : assign by department manager
104/06/02: RECEIVE_TRANS_LOG schema change

*/

 --- get update record 
  SELECT COUNT(1)
    INTO v_count
    FROM RECEIVE
   WHERE STEP_CODE = '2'
     AND RECEIVE_NO = p_in_receive_no;
   
  if v_count > 0 and p_in_force != 'Y' then
    p_out_msg := 'ゅ砆烩快,ゼ砆綪腹,琌璶眏だ快?';
    return;
  end if;

  SELECT COUNT(1)
    INTO v_count
    FROM RECEIVE
   WHERE STEP_CODE > '2'
     AND RECEIVE_NO = p_in_receive_no;

  if v_count > 0 then
    p_out_msg := 'ゅ綪腹,ぃだ快!';
    return;
  end if;
  
  ---------------------
    -- record receive transfer history
    ---------------------
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = RECEIVE.receive_no ),'1') seq , 
              RECEIVE.receive_no, RECEIVE.appl_no , p_in_processor_no,'2',sysdate,'だ快'
      from RECEIVE
       Where receive_no = p_in_receive_no;


  
  UPDATE RECEIVE
     SET PROCESSOR_NO = p_in_processor_no,
         STEP_CODE    = '2',
         process_date = to_char(to_number(to_char(sysdate, 'yyyyMMdd')) -
                                19110000)
   WHERE RECEIVE_NO = p_in_receive_no;

  update spt21
     set processor_no = p_in_processor_no
   where receive_no = p_in_receive_no;

  p_out_msg := 'ゅ腹 ' || p_in_receive_no || 'だ快Θ';
  return;

end case_dispatch;

/
