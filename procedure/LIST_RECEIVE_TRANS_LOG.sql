--------------------------------------------------------
--  DDL for Procedure LIST_RECEIVE_TRANS_LOG
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."LIST_RECEIVE_TRANS_LOG" (p_in_receive_no in char,
                                                   p_out_list      out sys_refcursor) is
begin
/*
��׾��{
ModifyDate : 2015/06/25
Desc : (1) add status : �ݤ�, �D�ްh��
(2) change date format
*/

  OPEN p_out_list FOR
    select to_char(RECEIVE_TRANS_LOG.trans_date, 'yyyy/MM/dd HH24:mi') as trans_date,
           RECEIVE_TRANS_LOG.receive_no,
           spm63.name_c,
          case
             when step_code_d = '0' and return_no = '4' then
              '�ݤ�'
             when step_code_d = '0'  then
              '�ݻ�'
             when step_code_d = '1' then
              '����ݿ�'
             when step_code_d = '2' then
              '�ݿ�'
             when step_code_d = '3' then
              '�w�P��'
             when step_code_d = '4' and return_no = '5' then 
              '�D�ްh��'
             when step_code_d = '4'  then 
              '�e��'
             when step_code_d = '5' then
              '�N�O��'
             when step_code_d = '6' then
              '�w�O��'
             when step_code_d = '8' then
              '�쵲'
             else
              '�L'
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
