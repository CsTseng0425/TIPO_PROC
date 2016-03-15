--------------------------------------------------------
--  DDL for Procedure SAVE_MERGE_RECEIVE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SAVE_MERGE_RECEIVE" (
  p_in_processor_no in char,
  p_in_receive_no in char,
  p_in_merge_master in char,
  p_in_merge in char
)
is
  v_processor_no spt21.processor_no%type;
  v_sc_flag      spt31.sc_flag%type;
begin
  select a.processor_no, b.sc_flag
    into v_processor_no, v_sc_flag
    from spt21 a, spt31 b
   where a.receive_no = p_in_receive_no
     and a.appl_no = b.appl_no;
  if p_in_processor_no = v_processor_no and nvl(v_sc_flag, '0') != '1' then
    if p_in_merge = 'Y' then
      update spt21
         set process_result = '40307'
       where receive_no = p_in_receive_no;
      update receive
         set merge_master = p_in_merge_master,
             step_code = (select step_code from receive where receive_no = p_in_merge_master)
       where receive_no = p_in_receive_no;
    else
      update spt21
         set process_result = ''
       where receive_no = p_in_receive_no;
      update receive
         set merge_master = '',
             step_code = '2'
       where receive_no = p_in_receive_no;
    end if;
  end if;
end save_merge_receive;

/
