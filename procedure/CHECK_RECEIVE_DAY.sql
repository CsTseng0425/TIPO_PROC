--------------------------------------------------------
--  DDL for Procedure CHECK_RECEIVE_DAY
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CHECK_RECEIVE_DAY" (p_rec  out int
                                         ) IS
  /*
  準備領辦公文
  104/08/28: 當已存在doc ,可直接update doc_complte = 1
  105/01/08: 
  */
  p_out_msg    varchar2(1000);
BEGIN
  update receive set doc_complete = '1'
  where receive_no in  ( select receive_no from doc where trim(doc.receive_no) = trim(receive.receive_no))
    and doc_complete = '0'
    and exists ( select '' from spt21 where spt21.receive_no = receive.receive_no and spt21.online_flg='Y')
  ;
  CHECK_RECEIVE('1',p_rec,p_out_msg);

EXCEPTION
  WHEN OTHERS THEN
  
    dbms_output.put_line('Error Code:' || SQLCODE || ' : ' || SQLERRM);
END CHECK_RECEIVE_DAY;

/
