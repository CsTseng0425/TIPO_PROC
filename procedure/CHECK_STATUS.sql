--------------------------------------------------------
--  DDL for Procedure CHECK_STATUS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CHECK_STATUS" ( p_rec  out int) is
 l_out_msg varchar2(100);
 p_msg     varchar2(100);
 ap_code varchar2(20);
  rec_cnt integer;
begin
 
  /*
  Modify: 104/08/05
  Desc : check 191 status ,stepcode 4: 癳 5: 恨癶快  8: 挡
   change receive_trans_log schema
  104/07/06: add update column  return_no = '6' when form return from manager
  104/07/07: change the step_code from 6 to 5 for form rejected issue
  104/07/09: update sign_date for close date 
  104/07/16: update the condition of waiting sign
  104/07/24: update error reporting status
  104/08/05: update spt21.online_cout = 'E' --mean finish
  104/09/03: update the status of recieve has merged 
  
  */
  ap_code := 'CHECK_STATUS';
  rec_cnt := 0;
  p_rec := 0;
  
 
  ---------------------
    -- record receive transfer history
    ---------------------
   
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no ,receive.processor_no,'4',sysdate,'癳'
      from receive
    where  receive_no in (
    select receive_no from  spm56 
    join ap.SPTD02 sd02  on sd02.form_file_a = spm56.form_file_a
    where  nvl(spm56.issue_flag ,'0') = '1'
    and sd02.NODE_STATUS = '210'
    and spm56.processor_no = receive.processor_no
    )
    and step_code != '4'
    and step_code >'0';
     
  
    update receive set step_code = '4' 
    where  receive_no in (
    select receive_no from  spm56 
    join ap.SPTD02 sd02  on sd02.form_file_a = spm56.form_file_a
    where  nvl(spm56.issue_flag ,'0') = '1'
    and sd02.NODE_STATUS = '210'
    and spm56.processor_no = receive.processor_no
    )
    and step_code != '4'
    and step_code >'0';
    
    commit;
    rec_cnt := rec_cnt +  SQL%RowCount;
    dbms_output.put_line('receive waiting for signed record:' || SQL%RowCount);
    /*************************************
      online finish:      SPTD02.flow_step=09
      paper finish: SPT41. check_datetime<>Null
      set step_code = '8'
    */
  --------------------------------
  -- write to log for paper issue
  --------------------------------
   INSERT INTO RECEIVE_TRANS_LOG
     select   nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no ,receive.processor_no,'8',sysdate,'挡'
    from receive
    where receive.step_code >= '2'  and receive.step_code < '8'
    and (  receive_no in ( -- online 
        select sm56.receive_no
         from ap.SPTD02 sd02 join ap.spm56 sm56 on sd02.form_file_a = sm56.form_file_a
         where  sd02.flow_step = '09'
         and sd02.NODE_STATUS = '900'
         and sm56.processor_no = receive.processor_no
         and sm56.record_date >= receive.process_date
         and sm56.form_file_a = (select max(form_file_a) from spm56 where spm56.receive_no = sm56.receive_no and spm56.processor_no = sm56.processor_no)
     ) or
      receive_no in ( -- paper 
         select s41.receive_no
         from  ap.spt41 s41
         where s41.check_datetime is not null
         and s41.processor_no = receive.processor_no
         and substr(s41.check_datetime,1,7) >= receive.process_date
         and s41.issue_no = (select max(issue_no) from spt41 where spt41.receive_no = s41.receive_no and spt41.processor_no = s41.processor_no)
     )
     );
     
      INSERT INTO RECEIVE_TRANS_LOG
     select   nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no ,receive.processor_no,'8',sysdate,'ㄖ快ゅ挡'
    from receive
    where receive.step_code >= '2'  and receive.step_code < '8'
    and (  merge_master in ( -- online 
        select sm56.receive_no
         from ap.SPTD02 sd02 join ap.spm56 sm56 on sd02.form_file_a = sm56.form_file_a
         where  sd02.flow_step = '09'
         and sd02.NODE_STATUS = '900'
         and sm56.processor_no = receive.processor_no
         and sm56.record_date >= receive.process_date
         and sm56.form_file_a = (select max(form_file_a) from spm56 where spm56.receive_no = sm56.receive_no and spm56.processor_no = sm56.processor_no)
     ) or
      merge_master in ( -- paper 
          select s41.receive_no
         from  ap.spt41 s41
         where s41.check_datetime is not null
         and s41.processor_no = receive.processor_no
         and substr(s41.check_datetime,1,7) >= receive.process_date
         and s41.issue_no = (select max(issue_no) from spt41 where spt41.receive_no = s41.receive_no and spt41.processor_no = s41.processor_no)
     )
     );
  
    ------------------------------------
    -- update step_code for paper issue
    ------------------------------------
    update receive set step_code = '8' ,
                       sign_date = ( select substr(check_datetime,1,7) from spt41 where check_datetime is not null
    and  spt41.receive_no = receive.receive_no and spt41.processor_no = receive.processor_no 
      and issue_no = (select max(issue_no) from spt41 s41 where s41.receive_no = spt41.receive_no and s41.processor_no = spt41.processor_no )
    )
     where receive.step_code >= '2'  and receive.step_code < '8'
    and (  receive_no in ( -- online 
        select sm56.receive_no
         from ap.SPTD02 sd02 join ap.spm56 sm56 on sd02.form_file_a = sm56.form_file_a
         where  sd02.flow_step = '09'
         and sd02.NODE_STATUS = '900'
         and sm56.processor_no = receive.processor_no
         and sm56.record_date >= receive.process_date
         and sm56.form_file_a = (select max(form_file_a) from spm56 where spm56.receive_no = sm56.receive_no and spm56.processor_no = sm56.processor_no)
     ) or
      receive_no in ( -- paper 
           select s41.receive_no
         from  ap.spt41 s41
         where s41.check_datetime is not null
         and s41.processor_no = receive.processor_no
         and substr(s41.check_datetime,1,7) >= receive.process_date
         and s41.issue_no = (select max(issue_no) from spt41 where spt41.receive_no = s41.receive_no and spt41.processor_no = s41.processor_no)
     ) 
     );
     rec_cnt := rec_cnt +  SQL%RowCount;
     
     update receive set step_code = '8' ,
                       sign_date = ( select substr(check_datetime,1,7) from spt41 where check_datetime is not null
    and  spt41.receive_no = receive.merge_master and spt41.processor_no = receive.processor_no 
      and issue_no = (select max(issue_no) from spt41 s41 where s41.receive_no = spt41.receive_no and s41.processor_no = spt41.processor_no )
    )
     where receive.step_code >= '2'  and receive.step_code < '8'
    and (  
     receive.merge_master in ( -- online 
        select sm56.receive_no
         from ap.SPTD02 sd02 join ap.spm56 sm56 on sd02.form_file_a = sm56.form_file_a
         where  sd02.flow_step = '09'
         and sd02.NODE_STATUS = '900'
         and sm56.processor_no = receive.processor_no
         and sm56.record_date >= receive.process_date
         and sm56.form_file_a = (select max(form_file_a) from spm56 where spm56.receive_no = sm56.receive_no and spm56.processor_no = sm56.processor_no)
     ) or
      receive.merge_master in ( -- paper 
        select s41.receive_no
         from  ap.spt41 s41
         where s41.check_datetime is not null
         and s41.processor_no = receive.processor_no
         and substr(s41.check_datetime,1,7) >= receive.process_date
         and s41.issue_no = (select max(issue_no) from spt41 where spt41.receive_no = s41.receive_no and spt41.processor_no = s41.processor_no)
     )
     );
     
    rec_cnt := rec_cnt +  SQL%RowCount;
     commit;
   
    
   dbms_output.put_line('receive finish record:' || SQL%RowCount);
    /*-------------------
    --  5: 恨癶快  
    -- online issue : SPTD02.resend=Ynullsign_user=┯快
    -- form rejected from manager
    ----------------------*/

    ---------------------------------
    -- write to log for online issue 
    ---------------------------------
     INSERT INTO RECEIVE_TRANS_LOG
     select   nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no ,receive.processor_no,'5',sysdate,'ㄧ絑癶快'
    from receive
    where receive.step_code > '3'
    and receive_no in (
     select sm56.receive_no
    from ap.SPTD02 sd02 join ap.spm56 sm56 on sd02.form_file_a = sm56.form_file_a
     where (sd02.SIGN_RESULT = '2' or NODE_STATUS = '130' ) -- 癶快
     and sm56.processor_no = receive.processor_no
     and sm56.record_date >= receive.process_date
     and sm56.form_file_a = (select max(form_file_a) from spm56 where spm56.receive_no = sm56.receive_no and spm56.processor_no = sm56.processor_no)
    )
    and step_code > '0'
    and step_code != '5'
    ;
  
   -------------------------------------
   -- update step_code for online issue
   -------------------------------------
     update receive set step_code = '5' , return_no = '6' ,sign_date = null
     where receive.step_code > '3'
     and receive_no in (
     select sm56.receive_no
    from ap.SPTD02 sd02 join ap.spm56 sm56 on sd02.form_file_a = sm56.form_file_a
     where (sd02.SIGN_RESULT = '2' or NODE_STATUS = '130' ) -- 癶快
     and sm56.processor_no = receive.processor_no
     and sm56.record_date >= receive.process_date
     and sm56.form_file_a = (select max(form_file_a) from spm56 where spm56.receive_no = sm56.receive_no and spm56.processor_no = sm56.processor_no)
    )
    and step_code > '0'
    and step_code != '5'
    ;
    
    
    rec_cnt := rec_cnt +  SQL%RowCount;
      dbms_output.put_line('receive return record:' || SQL%RowCount);
    commit;
   
    
    
   /*-------------------
    --  5: 紀  
    -- ゅ絑簿だ快,┯快簿癶快
    -- form rejected from manager
    ----------------------*/
     ---------------------------------
    -- write to log for online issue 
    ---------------------------------
     INSERT INTO RECEIVE_TRANS_LOG
     select   nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no ,receive.processor_no,'0',sysdate,'ㄧ絑紀'
    from receive
    where receive.step_code > '0'
    and receive_no in (
     select sm56.receive_no
    from ap.SPTD02 sd02 join ap.spm56 sm56 on sd02.form_file_a = sm56.form_file_a
     where  NODE_STATUS > '900'  -- 紀
     and sm56.processor_no = receive.processor_no
     and sm56.form_file_a = (select max(form_file_a) from spm56 where spm56.receive_no = sm56.receive_no and spm56.processor_no = sm56.processor_no)
     and substr(sm56.processor_no,1,1)='P'
    )
    and step_code != '0'
    ;
       INSERT INTO RECEIVE_TRANS_LOG
     select   nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1') seq , 
              receive.receive_no, receive.appl_no ,receive.processor_no,'5',sysdate,'ㄧ絑紀'
    from receive
     where receive.step_code > '0'
    and receive_no in (
     select sm56.receive_no
    from ap.SPTD02 sd02 join ap.spm56 sm56 on sd02.form_file_a = sm56.form_file_a
     where  NODE_STATUS > '900'  -- 紀
     and sm56.processor_no = receive.processor_no
     and sm56.form_file_a = (select max(form_file_a) from spm56 where spm56.receive_no = sm56.receive_no and spm56.processor_no = sm56.processor_no)
     and substr(sm56.processor_no,1,1) !='P'
    )
    and step_code != '5'
    ;
     update receive set step_code = '0' , return_no = '4' ,sign_date = null
    where receive.step_code > '0'
    and receive_no in (
     select sm56.receive_no
    from ap.SPTD02 sd02 join ap.spm56 sm56 on sd02.form_file_a = sm56.form_file_a
     where  NODE_STATUS > '900'  -- 紀
     and sm56.processor_no = receive.processor_no
     and sm56.form_file_a = (select max(form_file_a) from spm56 where spm56.receive_no = sm56.receive_no and spm56.processor_no = sm56.processor_no)
     and substr(sm56.processor_no,1,1)='P'
    )
    and step_code != '0'
    ;
     rec_cnt := rec_cnt +  SQL%RowCount;
     dbms_output.put_line('Outsourcing form failed record:' || SQL%RowCount);
     
     update receive set step_code = '5' , return_no = '6' ,sign_date = null
     where receive.step_code > '0'
    and receive_no in (
     select sm56.receive_no
    from ap.SPTD02 sd02 join ap.spm56 sm56 on sd02.form_file_a = sm56.form_file_a
     where  NODE_STATUS > '900'  -- 紀
     and sm56.processor_no = receive.processor_no
     and sm56.form_file_a = (select max(form_file_a) from spm56 where spm56.receive_no = sm56.receive_no and spm56.processor_no = sm56.processor_no)
     and substr(sm56.processor_no,1,1) !='P'
    )
    and step_code != '5'
    ;
    rec_cnt := rec_cnt +  SQL%RowCount;
    commit;
    dbms_output.put_line('form return record:' || SQL%RowCount);
    ---------------------------------
    -- update error reporting when document file has new one 
    ---------------------------------
    update error_reporting er
    set status = '1'
    where receive_no in 
    (
    select receive_no -- to_char(report_date,'yyyyMMddhh:mi:ss') 
    from  doc imp 
    where trim(er.receive_no) = trim(imp.receive_no) 
    and  to_char(report_date,'yyyyMMddhh:mi:ss')  <  to_char(to_number(to_char(modify_time,'yyyyMMdd'))) || to_char(modify_time,'hh:mi:ss')
    )
    and status in ('0','3')
    ;
    rec_cnt := rec_cnt +  SQL%RowCount;
    commit;
    dbms_output.put_line('error_reporting pass record:' || SQL%RowCount);
   
  
  -----------------------------------
  -- update  appl.online_flg for early publish
  -----------------------------------
  update appl set online_flg = '1'
  where  appl_no in 
  (
    select spt41.appl_no from spt41
    join spm56 on spt41.form_file_a = spm56.form_file_a and spt41.processor_no = spm56.processor_no
    where  spt41.appl_no = appl.appl_no and spt41.processor_no = appl.processor_no 
    and spt41.receive_no is null
    and spt41.check_datetime is not null
    and spm56.form_id = 'P03-1'
   -- and issue_type in ('49213','49215','49217','49269','49271') 
    )
  and  online_flg = '2'
  ;
    rec_cnt := rec_cnt +  SQL%RowCount;
  
  update appl set online_flg = '1'
  where  appl_no in 
  (
    select spt41.appl_no from spt41
    join receive on spt41.receive_no = receive.receive_no and spt41.appl_no  = receive.appl_no 
               and spt41.processor_no = receive.processor_no
    join spm56 on spt41.form_file_a = spm56.form_file_a and spt41.processor_no = spm56.processor_no
    where receive.step_code = '8'
    and spt41.valid_date is not null
    and spt41.check_datetime is not null
   -- and issue_type in ('49213','49215','49217','49269','49271') 
    and spm56.form_id = 'P03-1'
  )
  and  online_flg = '2'
  ;
    rec_cnt := rec_cnt +  SQL%RowCount;
        p_rec := rec_cnt;
        
EXCEPTION
  WHEN OTHERS THEN
  
   p_msg := ap_code || ':' || SQLCODE || ':' || SQLERRM; 
    dbms_output.put_line('Error Code:' || SQLCODE || '; Error Message:' || p_msg);     
end CHECK_STATUS;

/
