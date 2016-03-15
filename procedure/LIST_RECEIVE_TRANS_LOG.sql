--------------------------------------------------------
--  DDL for Procedure LIST_RECEIVE_TRANS_LOG
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."LIST_RECEIVE_TRANS_LOG" (p_in_receive_no in char,
                                                   p_out_list      out sys_refcursor) is
begin
/*
文案歷程
ModifyDate : 2015/06/25
Desc : (1) add status : 待分, 主管退辦
(2) change date format
*/

  OPEN p_out_list FOR
    select to_char(RECEIVE_TRANS_LOG.trans_date, 'yyyy/MM/dd HH24:mi') as trans_date,
           RECEIVE_TRANS_LOG.receive_no,
           spm63.name_c,
          case
             when step_code_d = '0' and return_no = '4' then
              '待分'
             when step_code_d = '0'  then
              '待領'
             when step_code_d = '1' then
              '它科待辦'
             when step_code_d = '2' then
              '待辦'
             when step_code_d = '3' then
              '已銷號'
             when step_code_d = '4' and return_no = '5' then 
              '主管退辦'
             when step_code_d = '4'  then 
              '送核'
             when step_code_d = '5' then
              '將逾期'
             when step_code_d = '6' then
              '已逾期'
             when step_code_d = '8' then
              '辦結'
             else
              '無'
           end as step,
           memo
      from RECEIVE_TRANS_LOG
      left join receive on RECEIVE_TRANS_LOG.receive_no = receive.receive_no
      left join spm63
        on RECEIVE_TRANS_LOG.processor_no_d = spm63.processor_no
     where RECEIVE_TRANS_LOG.receive_no = p_in_receive_no
     order by RECEIVE_TRANS_LOG.trans_date
     ;

end LIST_RECEIVE_TRANS_LOG;

/
