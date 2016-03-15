--------------------------------------------------------
--  DDL for Procedure RECEIVE_TRANSFER
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."RECEIVE_TRANSFER" (v_direct in char,v_receive_no in varchar,v_step_code in varchar) 
IS 
    l_cnt number;    
    l_badNo number;
    l_isPass  char;
    l_standard char;
BEGIN
/*--------------------------------
 For Test
----------------------------------*/
   IF v_direct = '1' THEN  -- paper to online
      update spt21 set online_flg = 'Y', online_cout = 'Y'  where receive_no = v_receive_no;
      Insert into receive
      Select spt21.receive_no,appl_no , trim(v_step_code),
        '0', '1', '1',null,null,0,0,0,
        case when trim(v_step_code) = '0' then null else processor_no end,
        object_id,null,null,NULL
      From SPT21
      Where receive_no = v_receive_no;
   END IF;
   
   IF v_direct = '2' THEN  --  online to paper 
      update spt21 set online_flg = 'N', online_cout = 'N'  where receive_no = v_receive_no;
      delete receive
           Where receive_no = v_receive_no;
   END IF;
  
    dbms_output.put_line('Finish');
EXCEPTION
  WHEN OTHERS THEN
  
    dbms_output.put_line('Error Code:' ||  SQLCODE || ' : ' || SQLERRM);   
     
END RECEIVE_TRANSFER;

/
