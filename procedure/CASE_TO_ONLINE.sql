--------------------------------------------------------
--  DDL for Procedure CASE_TO_ONLINE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CASE_TO_ONLINE" (p_in_receive_no   in char,
                                           p_in_processor_no in char,
                                           p_in_step_code    in char,
                                           p_out_msg         out varchar2) is
  v_count      number;
  v_validation varchar2(100);
  v_appl_no    spt21.appl_no%type;
begin
/*
  ModifyDate : 105/02/17
  Desc: transfer receive from paper to online mode
   change receive_trans_log schema
  ModifyItem:
  104/07/09: step code is wrong in log 
  104/08/26: update spt21.dept_no ='70012'
  104/08/27: when doc exists the receive_no then doc_complete = 1
  104/09/09: exclude the receives which process_result= 57001
  105/02/17: add delete receive where step_code = 9
*/
  SELECT COUNT(1)
    INTO v_count
    FROM SPT21
   WHERE ONLINE_FLG = 'Y'
     AND RECEIVE_NO = p_in_receive_no
     ;
  if v_count > 0 then
    p_out_msg := '已為線上文件';
    return;
  end if;


  v_validation := case_valid_convert(p_in_receive_no, p_in_processor_no);

  if v_validation is not null then
    p_out_msg := v_validation;
    return;
  end if;

   delete receive where receive_no = p_in_receive_no and step_code = '9';
  ---------------------
    -- record receive transfer history
    ---------------------
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = SPT21.receive_no ),'1') seq , 
              SPT21.receive_no, SPT21.appl_no , SPT21.processor_no,trim(p_in_step_code),sysdate,'紙本轉線上'
      from SPT21
       Where receive_no = p_in_receive_no
      ;

  UPDATE SPT21
     SET ONLINE_COUT = 'Y', ONLINE_FLG = 'Y' ,DEPT_NO='70012' , processor_no = p_in_processor_no
   WHERE RECEIVE_NO = p_in_receive_no
   ;

  INSERT INTO RECEIVE
    SELECT RECEIVE_NO,
           APPL_NO,
           trim(p_in_step_code),
           '0',
           '1',
           '1',
           NULL,
           NULL,
           0,
           case when exists (select 1 from doc where trim(receive_no) = trim(p_in_receive_no)) then 1 else  0 end as doc_complete,
           case when trim(p_in_processor_no) = '70012' then 'D' else '0' end as return_no,
           trim(p_in_processor_no),
           object_id,
           to_char(to_number(to_char(sysdate, 'yyyyMMdd')) - 19110000),
           NULL,
           null
      FROM SPT21
     WHERE RECEIVE_NO = p_in_receive_no
     ;
 
   CHECK_RECEIVE('0',v_count,p_out_msg);
 
  p_out_msg := '轉換 ' || trim(p_in_receive_no) || ' 成功';
 SYS.Dbms_Output.Put_Line(p_out_msg);

end case_to_online;

/
