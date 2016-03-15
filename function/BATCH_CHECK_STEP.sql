--------------------------------------------------------
--  DDL for Function BATCH_CHECK_STEP
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."BATCH_CHECK_STEP" (p_batch_no in varchar2)
  return char is

  l_step_code char(1);
  v_step_code char(1);
begin
  
    select step_code into v_step_code 
    from batch 
    where batch_no = p_batch_no
    and batch_seq = (select max(batch_seq) from batch where batch_no = p_batch_no)
    ;
 
     select step_code into l_step_code 
     from
     (
       select batch.batch_no , '3' step_code
        from batch_detail 
        join batch on batch.batch_no = batch_detail.batch_no and batch.batch_seq = batch_detail.batch_seq
        join spm56 on spm56.receive_no = batch_detail.receive_no 
        join ap.sptd02 sd02 on sd02.form_file_a = spm56.form_file_a
        where batch.batch_seq  = (select max(batch_seq) from batch where batch_no = batch_detail.batch_no)
     --   and batch.step_code = '1'
        and batch.process_result = '1' -- pass
        and is_rejected='0'
        and spm56.form_file_a = (select max(form_file_a) from spm56 s56 where s56.receive_no = spm56.receive_no and s56.issue_flag = '1')
        and batch.batch_no = p_batch_no
        group by batch.batch_no
        having  sum(case when sd02.flow_step != '04' then 1 else 0 end )=0
        union all
        select batch.batch_no , '4' step_code -- 判發中
        from batch_detail 
        join batch on batch.batch_no = batch_detail.batch_no and batch.batch_seq = batch_detail.batch_seq
        join spm56 on spm56.receive_no = batch_detail.receive_no 
        join ap.sptd02 sd02 on sd02.form_file_a = spm56.form_file_a
        where batch.batch_seq  = (select max(batch_seq) from batch where batch_no = batch_detail.batch_no)
     --   and batch.step_code = '1'
        and batch.process_result = '1' -- pass
        and is_rejected='0'
        and spm56.form_file_a = (select max(form_file_a) from spm56 s56 where s56.receive_no = spm56.receive_no and s56.issue_flag = '1')
        and batch.batch_no = p_batch_no
        group by batch.batch_no
        having  sum(case when sd02.flow_step != '04' then 1 else 0 end )>0
        union all 
         select batch.batch_no ,'2' step_code 
          from batch_detail 
          join batch on batch.batch_no = batch_detail.batch_no and batch.batch_seq = batch_detail.batch_seq
          join spm56 on spm56.receive_no = batch_detail.receive_no 
          join ap.sptd02 sd02 on sd02.form_file_a = spm56.form_file_a
          where batch.batch_seq  = (select max(batch_seq) from batch where batch_no = batch_detail.batch_no)
        --  and batch.step_code = '1'
          and batch.process_result in ('2','3') -- fail
          and is_rejected='0'
          and spm56.form_file_a = (select max(form_file_a) from spm56 s56 where s56.receive_no = spm56.receive_no and s56.issue_flag = '1')
          and batch.batch_no = p_batch_no
          group by batch.batch_no
          having sum(case when sd02.flow_step != '01' then 1 else 0 end )=0 --
           union all 
         select batch.batch_no ,'5' step_code  -- 退辦中
          from batch_detail 
          join batch on batch.batch_no = batch_detail.batch_no and batch.batch_seq = batch_detail.batch_seq
          join spm56 on spm56.receive_no = batch_detail.receive_no 
          join ap.sptd02 sd02 on sd02.form_file_a = spm56.form_file_a
          where batch.batch_seq  = (select max(batch_seq) from batch where batch_no = batch_detail.batch_no)
        --  and batch.step_code = '1'
          and batch.process_result in ('2','3') -- fail
          and is_rejected='0'
          and spm56.form_file_a = (select max(form_file_a) from spm56 s56 where s56.receive_no = spm56.receive_no and s56.issue_flag = '1')
          and batch.batch_no = p_batch_no
          group by batch.batch_no
          having sum(case when sd02.flow_step != '01' then 1 else 0 end )>0 --
             union all 
         select batch.batch_no ,'1' step_code  -- 待驗
          from batch_detail 
          join batch on batch.batch_no = batch_detail.batch_no and batch.batch_seq = batch_detail.batch_seq
          join spm56 on spm56.receive_no = batch_detail.receive_no 
          join ap.sptd02 sd02 on sd02.form_file_a = spm56.form_file_a
          where batch.batch_seq  = (select max(batch_seq) from batch where batch_no = batch_detail.batch_no)
          and is_rejected='0'
          and spm56.form_file_a = (select max(form_file_a) from spm56 s56 where s56.receive_no = spm56.receive_no and s56.issue_flag = '1')
          and batch.batch_no = p_batch_no
          group by batch.batch_no
          having sum(case when sd02.flow_step != '02' then 1 else 0 end )=0 --
          )
          ;
          
          return nvl(l_step_code,v_step_code);
exception
  when others then
    return v_step_code;
end BATCH_CHECK_STEP;

/
