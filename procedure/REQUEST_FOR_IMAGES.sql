--------------------------------------------------------
--  DDL for Procedure REQUEST_FOR_IMAGES
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."REQUEST_FOR_IMAGES" (p_in_receive_no   in char,
                                           p_in_processor_no in char,
                                           p_in_step_code    in char,                                           
                                           p_out_msg         out varchar2) is
  v_count      number;
begin
  /*
  SELECT COUNT(1)
    INTO v_count
    FROM RECEIVE
   WHERE step_code=p_in_step_code and PROCESS_DATE<to_char(to_char(add_months(sysdate,-6), 'yyyyMMdd') - 19110000);
   
  if v_count > 0 then
    --刪除超過半年影像檔請求
    delete from RECEIVE WHERE step_code=p_in_step_code and PROCESS_DATE<to_char(to_char(add_months(sysdate,-6), 'yyyyMMdd') - 19110000);
  end if;
  */
  --檢查 SPT21是否有相同收文文號
  SELECT COUNT(1)
    INTO v_count
    FROM SPT21
   WHERE RECEIVE_NO = p_in_receive_no;  
  
  if v_count = 0 then
      p_out_msg := '收文文號錯誤或不存在';
  else

    --檢查 RECEIVE是否有相同收文文號
    SELECT COUNT(1)
    INTO v_count
    FROM doc
    WHERE RECEIVE_NO = p_in_receive_no;

    if v_count > 0 then
      --有相同收文文號,結束
      p_out_msg := '影像檔已存在!若影像檔依然不存在，請聯絡管理員!';
      
      SYS.Dbms_Output.Put_Line(p_out_msg);
      return;
    end if;  
    
    
    --檢查 RECEIVE是否有相同收文文號
    SELECT COUNT(1)
    INTO v_count
    FROM RECEIVE
    WHERE RECEIVE_NO = p_in_receive_no;
       
    if v_count > 0 then
      --有相同收文文號,結束
      SELECT COUNT(1)
      INTO v_count
      FROM RECEIVE
      WHERE RECEIVE_NO = p_in_receive_no and doc_complete='1';
      
      if v_count > 0 then
        p_out_msg := '影像檔已到齊';
      else
        p_out_msg := '重複向申請案件管理系統調閱影像檔';
      end if;
      
    else
      --無相同收文文號，新增
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = SPT21.receive_no ),'1') seq , 
          SPT21.receive_no, SPT21.appl_no , SPT21.processor_no,trim(p_in_step_code),sysdate,'請求影像檔'
      from SPT21
      Where　RECEIVE_NO = p_in_receive_no;
  
      INSERT INTO RECEIVE(RECEIVE_NO,APPL_NO,STEP_CODE,PROCESSOR_NO,OBJECT_ID,PROCESS_DATE)
      SELECT RECEIVE_NO,
           APPL_NO,
           trim(p_in_step_code),--step_code
           trim(p_in_processor_no),
           OBJECT_ID,
           to_char(to_number(to_char(sysdate, 'yyyyMMdd')) - 19110000)--PROCESS_DATE
      FROM SPT21
      WHERE RECEIVE_NO = p_in_receive_no;
  
      p_out_msg := '由申請案件管理系統批次調閱文號[' || trim(p_in_receive_no) || ' ]影像檔!';  
      
    end if;
  
  end if;  

  SYS.Dbms_Output.Put_Line(p_out_msg);
  
end REQUEST_FOR_IMAGES;

/
