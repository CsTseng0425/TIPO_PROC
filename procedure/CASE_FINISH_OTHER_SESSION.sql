--------------------------------------------------------
--  DDL for Procedure CASE_FINISH_OTHER_SESSION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CASE_FINISH_OTHER_SESSION" (p_in_appl_no      in char,
                                                      p_in_processor_no in char,
                                                      p_out_msg         out varchar2) is

  v_OUT_MSG number;
  
begin
  /*
  MOdify : 104/10/08
  change appl status to finish which is assigned by other session
   */

  update appl
     set DIVIDE_CODE = '0', FINISH_FLAG = '1'
   where appl_no = p_in_appl_no;
   
  

  SEND_APPL_TO_EARLY_PUBLICATION(p_in_processor_no,
                                 p_in_appl_no,
                                 '1',
                                 null,
                                 v_OUT_MSG);

  p_out_msg := p_in_appl_no || ' 設定完成成功';

end CASE_FINISH_OTHER_SESSION;

/
