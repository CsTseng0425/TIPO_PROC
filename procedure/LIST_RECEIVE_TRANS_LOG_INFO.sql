--------------------------------------------------------
--  DDL for Procedure LIST_RECEIVE_TRANS_LOG_INFO
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."LIST_RECEIVE_TRANS_LOG_INFO" (p_in_receive_no in char,
                                                        receive_no      out varchar2,
                                                        receive_date    out varchar2,
                                                        last_pno        out varchar2,
                                                        last_step_code  out varchar2) is
begin
/*
 ModifyDate : 2015/06/02
*/

  select receive_no,
         (select receive_date from spt21 where receive_no = lg.receive_no) as receive_date,
         processor_no_d last_pno,
         case
           when step_code_d = '0' then
            '待領'
           when step_code_d = '1' then
            '他科待辦'
           when step_code_d = '2' then
            '待辦'
           when step_code_d = '3' then
            '已銷號'
           when step_code_d = '4' then
            '陳核中'
           when step_code_d = '5' then
            '將逾期'
           when step_code_d = '6' then
            '已逾期'
           when step_code_d = '8' then
            '辦結'
           else
            '無'
         end as last_step_code
    into receive_no, receive_date, last_pno, last_step_code
    from RECEIVE_TRANS_LOG lg
   where receive_no = p_in_receive_no
     and trans_date = (select max(trans_date)
                         from RECEIVE_TRANS_LOG
                        where lg.receive_no = receive_no);
exception
  when no_data_found then
    receive_no     := p_in_receive_no;
    receive_date   := '';
    last_pno       := '';
    last_step_code := '';
  
end LIST_RECEIVE_TRANS_LOG_INFO;

/
