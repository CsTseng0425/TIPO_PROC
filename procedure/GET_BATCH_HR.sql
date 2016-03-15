--------------------------------------------------------
--  DDL for Procedure GET_BATCH_HR
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."GET_BATCH_HR" (p_rec  out int
                                         ) IS
  /*
  產生外包批次資料,只處理線上公文
  參數: checkdate : 送核日期
       is_fix: 是否凍結 ; (0: 白天批次執行,每小時加入公文到批次中; 1: 晚上執行最後一次批次新增; 之後,不再增加公文)
  
  */
BEGIN
  GET_Batch(to_char(to_number(to_char(sysdate,'yyyyMMdd'))-19110000),'0',p_rec);
  dbms_output.put_line('Finish total record:' || p_rec);
  
   /*-------------------------------------
     check batch status by form status
    
    --------------------------------------*/
    update batch 
    set step_code = '3'
    where batch_no in 
    (
        select batch.batch_no
        from batch_detail 
        join batch on batch.batch_no = batch_detail.batch_no and batch.batch_seq = batch_detail.batch_seq
        join spm56 on spm56.receive_no = batch_detail.receive_no 
        join ap.sptd02 sd02 on sd02.form_file_a = spm56.form_file_a
        where batch.batch_seq  = (select max(batch_seq) from batch where batch_no = batch_detail.batch_no)
        and batch.step_code = '1'
        and batch.process_result = '1' -- pass
        and is_rejected='0'
        and spm56.form_file_a = (select max(form_file_a) from spm56 s56 where s56.receive_no = spm56.receive_no and s56.issue_flag = '1')
        group by batch.batch_no
        having  sum(case when sd02.flow_step != '04' then 1 else 0 end )=0
        )
        ;
         p_rec := p_rec +  SQL%RowCount;
        dbms_output.put_line('batch pass record:' || SQL%RowCount);

        update batch 
        set step_code = '2'
        where batch_no in 
        (
          select batch.batch_no
          from batch_detail 
          join batch on batch.batch_no = batch_detail.batch_no and batch.batch_seq = batch_detail.batch_seq
          join spm56 on spm56.receive_no = batch_detail.receive_no 
          join ap.sptd02 sd02 on sd02.form_file_a = spm56.form_file_a
          where batch.batch_seq  = (select max(batch_seq) from batch where batch_no = batch_detail.batch_no)
          and batch.step_code = '1'
          and batch.process_result in ('2','3') -- fail
          and is_rejected='0'
          and spm56.form_file_a = (select max(form_file_a) from spm56 s56 where s56.receive_no = spm56.receive_no and s56.issue_flag = '1')
          group by batch.batch_no
          having sum(case when sd02.flow_step != '01' then 1 else 0 end )=0 --
        )
        ;
        dbms_output.put_line('batch fail record:' || SQL%RowCount);
       p_rec := p_rec +  SQL%RowCount;
        commit;

EXCEPTION
  WHEN OTHERS THEN
  
    dbms_output.put_line('Error Code:' || SQLCODE || ' : ' || SQLERRM);
END GET_Batch_HR;

/
