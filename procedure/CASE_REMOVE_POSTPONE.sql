--------------------------------------------------------
--  DDL for Procedure CASE_REMOVE_POSTPONE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CASE_REMOVE_POSTPONE" (p_in_receive_no in char,
                                                 p_out_msg       out varchar2) is

begin
  /*
  MOdifyDate: 104/10/08
  remove receive postpone status
  remove postpone reason  
    */

  
  update receive set is_postpone = '0' , post_reason = null where receive_no = p_in_receive_no;

  delete appl_para
   where sys = 'POSTPONE'
     and subsys = p_in_receive_no;

  p_out_msg := p_in_receive_no || ' 移除緩辦成功';

end CASE_REMOVE_POSTPONE;

/
