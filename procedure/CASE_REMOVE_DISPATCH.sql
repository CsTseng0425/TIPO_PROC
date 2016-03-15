--------------------------------------------------------
--  DDL for Procedure CASE_REMOVE_DISPATCH
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CASE_REMOVE_DISPATCH" (p_in_appl_no in char,
                                                 p_out_msg    out varchar2) is

begin
  /*
  Desc : chief assign list for removing project from the processor_no
  MOdifyDate: 104/10/26
  remove dispatch status  
   */

  update appl
     set divide_code = '0', processor_no = null , is_overtime = '0'
   where appl_no = p_in_appl_no;

  p_out_msg := p_in_appl_no || ' ²¾°£¦¨¥\';

end CASE_REMOVE_DISPATCH;

/
