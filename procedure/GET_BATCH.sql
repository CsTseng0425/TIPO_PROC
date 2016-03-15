--------------------------------------------------------
--  DDL for Procedure GET_BATCH
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."GET_BATCH" (checkdate in varchar2,
                                        is_fix    in char,
                                        p_rec     out int
                                         ) IS
  /*
  DESC: 產生外包批次資料,只處理線上公文
  PARAMETER: checkdate : 送核日期
             s_fix: 是否凍結 ; (0: 白天批次執行,每小時加入公文到批次中; 1: 晚上執行最後一次批次新增; 之後,不再增加公文)
  ModifyDate : 104/07/08
  104/07/23: change return record parameter 
  */

  CURSOR BATCH_CUR IS
    SELECT distinct d02.create_date  || '-' || s21.processor_no , s21.processor_no, s21.receive_no ,s21.appl_no
      FROM spm56 s56
      JOIN receive s21
        on s56.appl_no = s21.appl_no
       and s56.receive_no = s21.receive_no  and s56.processor_no = s21.processor_no
       JOIN (
      select d02.form_file_a, d03.create_date 
      from ap.sptd02  d02
      join ap.sptd03 d03 on  d02.form_file_a = d03.form_file_a and d02.node_no = d03.node_no
      where  d02.flow_step ='02'
      ) d02 on d02.form_file_a = s56.form_file_a
     WHERE s21.processor_no  between 'P2121' and 'P2124'
       and s56.ISSUE_FLAG = '1'
       AND d02.create_date  = checkdate
        and s56.receive_no not in (select bd2.receive_no from batch_detail bd2  join batch b2 on b2.batch_seq = bd2.batch_seq and b2.batch_no = bd2.batch_no
         and bd2.is_rejected = '0'
         and b2.step_code <='3'
         and b2.batch_seq = (select max(batch_seq) from batch where batch_no = b2.batch_no)
         )
       ;

  l_batch_date      varchar2(10);
  l_batch_processor varchar2(10);
  l_receive_no      varchar2(15);
  l_appl_no         varchar2(15);
  l_step_code       char;
  l_batch_no        varchar2(50);
  l_cnt1            number;

  l_urec            integer;
BEGIN
 l_cnt1 := 0;
 l_urec := 0;
 p_rec  := 0;
  OPEN BATCH_CUR;
    LOOP
      FETCH BATCH_CUR
        INTO l_batch_no, l_batch_processor,l_receive_no,l_appl_no;
      EXIT WHEN BATCH_CUR%NOTFOUND;
      
   --   l_cnt1 := l_cnt1 + 1;
       dbms_output.put_line( l_cnt1 || ':l_batch_no:' || l_batch_no || ';receive_no =' || l_receive_no);
  -------------------------
  -- Insert Batch
  -------------------------
    INSERT INTO batch
    (batch_seq, batch_no, outsourcing, step_code,process_date)
    select '1',l_batch_no ,
                  l_batch_processor,
                    '0', -- 未凍結
                   substr(l_batch_no,1,7)
      FROM dual
      LEFT JOIN BATCH
        on BATCH.Batch_No = l_batch_no
     WHERE Batch.Batch_No is null;
     --  l_urec :=  SQL%RowCount;
       
             
       update receive
       set step_code = '4' --陳核中
       where receive_no = l_receive_no
       and not exists
       (select 1 FROM BATCH_DETAIL bd
         WHERE  bd.batch_no = l_batch_no
          AND bd.receive_no = l_receive_no
          )
        and exists ( select 1 from batch where Batch_No = l_batch_no and step_code = '0')
        ;
     --   l_urec := l_urec +  SQL%RowCount;
          dbms_output.put_line('update record:' || l_urec);
          
           select count(1) into l_urec
        FROM dual
       WHERE  not exists (select 1 from   BATCH_DETAIL bd
                 where bd.Batch_No = l_batch_no and bd.receive_no = l_receive_no)
        and exists ( select 1 from batch where Batch_No = l_batch_no and step_code = '0')
     ;
     p_rec := p_rec + l_urec;
        
     INSERT INTO batch_detail
      SELECT distinct 1,
                    l_batch_no,
                    l_receive_no,
                    l_appl_no,
                    '0',
                    '0',
                    null,
                    '0'
      FROM dual
    WHERE  not exists (select 1 from   BATCH_DETAIL bd
        where bd.Batch_No = l_batch_no and bd.receive_no = l_receive_no)
     ;
     
    --  l_urec := l_urec +  SQL%RowCount;
        dbms_output.put_line('update + insert record:' || l_urec);
  ----------------------------------------------------------
  -- Fix records , no more record can be added to batch
  ----------------------------------------------------------
    
  END LOOP;
  CLOSE BATCH_CUR;
    COMMIT;
  
   
      IF is_fix = '1' THEN
         UPDATE batch
         SET STEP_CODE = '1', PROCESS_DATE = checkdate, approver= (select max(checker) from ap.spm72 where dept_no = '70012' and processor_no = batch.outsourcing)
          WHERE substr(batch_no,1,7) = checkdate; 
         --  p_rec := p_rec + SQL%RowCount;
       END IF;
   p_rec := nvl(p_rec,0);
  dbms_output.put_line('Finish total record:' || p_rec);
--EXCEPTION
--  WHEN OTHERS THEN
  
  --  dbms_output.put_line('Error Code:' || SQLCODE || ' : ' || SQLERRM);
END GET_Batch;

/
