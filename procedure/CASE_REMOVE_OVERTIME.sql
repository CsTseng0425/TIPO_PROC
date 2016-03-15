--------------------------------------------------------
--  DDL for Procedure CASE_REMOVE_OVERTIME
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CASE_REMOVE_OVERTIME" (p_in_appl_no in char,
                                                 p_status in char,
                                                 p_out_msg    out varchar2) is
  l_status char(1);
  l_in_appl_no char(15);
begin
  /*
  ModifyDate : 104/10/08
  Desc:remove appl overtime status
  104/05/21 : add parameter p_status for judge is delete overtime status or remove overtime
  */

  
  l_status := trim(p_status);
  l_in_appl_no := trim(p_in_appl_no);
  
  IF l_status = '1' then 
       
     update appl set is_overtime = '2' where appl_no = l_in_appl_no;
     p_out_msg := l_in_appl_no || ' 移除逾期成功';
  END IF;

  IF l_status = '2' then 
    
     update appl set is_overtime = '0', divide_code = '0', assign_date = null where appl_no = l_in_appl_no;
     p_out_msg := l_in_appl_no || ' 刪除逾期狀態成功';
  END IF;
  

end CASE_REMOVE_OVERTIME;

/
