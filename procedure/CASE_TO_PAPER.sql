--------------------------------------------------------
--  DDL for Procedure CASE_TO_PAPER
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CASE_TO_PAPER" (p_in_receive_no   in char,
                                          p_in_processor_no in char,
                                          p_out_msg         out varchar2) is
  v_count      number;
  v_validation varchar2(100);
  v_out_msg    varchar2(100); 
  v_appl_no    spt21.appl_no%type;
begin
/*
  ModifyDate : 104/12/25
  Desc: transfer receive from online to paper mode
  change receive_trans_log schema
 104/12/25 : update appl.online_flg
*/

  SELECT COUNT(1)
    INTO v_count
    FROM SPT21
   WHERE ONLINE_FLG = 'N'
     AND RECEIVE_NO = p_in_receive_no;
     
    SELECT APPL_NO
    INTO v_appl_no
    FROM RECEIVE
   WHERE  RECEIVE_NO = p_in_receive_no;

  if v_count > 0 then
    p_out_msg := '已為紙本文件';
    return;
  end if;

  v_validation := case_valid_convert(p_in_receive_no, p_in_processor_no);

  if v_validation is not null then
    p_out_msg := v_validation;
    return;
  end if;
  
  -------------------------------
  --  104/12/25
  -- not exists appl.onlne_flg != 0 and other online receive, don't update 
  -------------------------------
    SELECT COUNT(1)
    INTO v_count
    FROM receive join appl on appl.appl_no = receive.appl_no
   WHERE receive.appl_no = v_appl_no
     AND receive.RECEIVE_NO != p_in_receive_no
     AND appl.online_flg != '0'
     ;
  
  if v_count =0 then 
      update appl set online_flg = '0' where appl_no = v_appl_no;
      SEND_APPL_TO_EARLY_PUBLICATION(p_in_processor_no,v_appl_no,'0','程序已撤回該案',v_out_msg);
  end if;
  ------------------------end  104/12/25
  
   ---------------------
    -- record receive transfer history
    ---------------------
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),1) seq , 
              receive.receive_no, receive.appl_no , receive.processor_no,null,sysdate,'線上轉紙本'
      from receive
       Where receive_no = p_in_receive_no;

  UPDATE SPT21
     SET ONLINE_COUT = 'N', ONLINE_FLG = 'N'
   WHERE RECEIVE_NO = p_in_receive_no;

  DELETE RECEIVE WHERE RECEIVE_NO = p_in_receive_no;
  DELETE tmp_get_receive  WHERE RECEIVE_NO = p_in_receive_no; 
  commit;
  
  
      p_out_msg := '轉換 ' || trim(p_in_receive_no) || ' 成功';
 SYS.Dbms_Output.Put_Line(p_out_msg);
   
--  p_out_msg := '轉換 ' || p_in_receive_no || ' 成功';

end case_to_paper;

/
