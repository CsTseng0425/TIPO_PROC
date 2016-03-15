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
    --�R���W�L�b�~�v���ɽШD
    delete from RECEIVE WHERE step_code=p_in_step_code and PROCESS_DATE<to_char(to_char(add_months(sysdate,-6), 'yyyyMMdd') - 19110000);
  end if;
  */
  --�ˬd SPT21�O�_���ۦP����帹
  SELECT COUNT(1)
    INTO v_count
    FROM SPT21
   WHERE RECEIVE_NO = p_in_receive_no;  
  
  if v_count = 0 then
      p_out_msg := '����帹���~�Τ��s�b';
  else

    --�ˬd RECEIVE�O�_���ۦP����帹
    SELECT COUNT(1)
    INTO v_count
    FROM doc
    WHERE RECEIVE_NO = p_in_receive_no;

    if v_count > 0 then
      --���ۦP����帹,����
      p_out_msg := '�v���ɤw�s�b!�Y�v���ɨ̵M���s�b�A���p���޲z��!';
      
      SYS.Dbms_Output.Put_Line(p_out_msg);
      return;
    end if;  
    
    
    --�ˬd RECEIVE�O�_���ۦP����帹
    SELECT COUNT(1)
    INTO v_count
    FROM RECEIVE
    WHERE RECEIVE_NO = p_in_receive_no;
       
    if v_count > 0 then
      --���ۦP����帹,����
      SELECT COUNT(1)
      INTO v_count
      FROM RECEIVE
      WHERE RECEIVE_NO = p_in_receive_no and doc_complete='1';
      
      if v_count > 0 then
        p_out_msg := '�v���ɤw���';
      else
        p_out_msg := '���ƦV�ӽЮץ�޲z�t�νվ\�v����';
      end if;
      
    else
      --�L�ۦP����帹�A�s�W
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = SPT21.receive_no ),'1') seq , 
          SPT21.receive_no, SPT21.appl_no , SPT21.processor_no,trim(p_in_step_code),sysdate,'�ШD�v����'
      from SPT21
      Where�@RECEIVE_NO = p_in_receive_no;
  
      INSERT INTO RECEIVE(RECEIVE_NO,APPL_NO,STEP_CODE,PROCESSOR_NO,OBJECT_ID,PROCESS_DATE)
      SELECT RECEIVE_NO,
           APPL_NO,
           trim(p_in_step_code),--step_code
           trim(p_in_processor_no),
           OBJECT_ID,
           to_char(to_number(to_char(sysdate, 'yyyyMMdd')) - 19110000)--PROCESS_DATE
      FROM SPT21
      WHERE RECEIVE_NO = p_in_receive_no;
  
      p_out_msg := '�ѥӽЮץ�޲z�t�Χ妸�վ\�帹[' || trim(p_in_receive_no) || ' ]�v����!';  
      
    end if;
  
  end if;  

  SYS.Dbms_Output.Put_Line(p_out_msg);
  
end REQUEST_FOR_IMAGES;

/
