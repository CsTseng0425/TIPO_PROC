--------------------------------------------------------
--  DDL for Procedure RECEIVE193
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."RECEIVE193" ( p_rec out int)
IS 
    l_cnt number;    
    l_badNo number;
    l_isPass  char;
    l_standard char;
    l_where varchar2(1000);
    l_out_msg    varchar2(100);
BEGIN
/*--------------------------------
 Modify Date : 104/12/03
 Get Recive from 190
 (1) get receive data from spt21 where  online_flg = Y  and online_cout = 'N' and 090  picture file is ready
 (2) update online_cout =Y where  online_flg = Y  and online_cout = 'N' and   090 picture file is ready  
 (3) when 1,2 ready, get receive from 190 to 193
 (4) record receive transfer history
 (5) check_receive add parameter
 (6) 104/6/2  change receive_trans_log schema
 (7) 104/6/3  error reporting check
 (8) 104/6/24 add new project from spt31 to appl
 (9) 104/08/05  add condition  spt21.dept_no = '70012'
 (10) 104/08/07 cancel to check image has getted
 (11) 104/09/09 exclude the receives which process_result = 57001
 (12) 104/11/27 add conditon for appl : spt31a.step_code != '99'
 (13) 104/12/03 when receiver hasn't insert into table receive , can't update online_cout = 'Y'
----------------------------------*/
    -- check picture file is ready 
    -- get to 193
    select count(1) into p_rec
    FROM SPT21 LEFT JOIN RECEIVE on SPT21.receive_no = RECEIVE.receive_no
    WHERE online_flg = 'Y' and online_cout = 'N'
    AND dept_no = '70012'
    AND receive.receive_no is null
    AND spt21.appl_no is not null
    AND ( spt21.process_result != '57001' or spt21.process_result is null)
     ;
    
    
     INSERT into receive
    SELECT spt21.receive_no,
           spt21.appl_no , 
           '0' as step_code,
           '0' as is_postpone, 
           '1' as img_complete, 
           '1' as rec_complete,
           null as sign_date,
           null as merge_master,
           '0' as unusual,
           '0' as doc_complete,
           '0' as return_no,
           '70012' as processor_no, 
           '' object_id,
           null as process_result,
           null as receive_date ,
           null as ACCEPT_DATE
    FROM SPT21 LEFT JOIN RECEIVE on SPT21.receive_no = RECEIVE.receive_no
    WHERE online_flg = 'Y' and online_cout = 'N'
    AND dept_no = '70012'
    AND receive.receive_no is null
    AND spt21.appl_no is not null
    AND ( spt21.process_result != '57001' or spt21.process_result is null)
     ;
    
    dbms_output.put_line('total records:' || p_rec);   
  
    ---------------------
    -- record receive transfer history
    ---------------------
      INSERT INTO RECEIVE_TRANS_LOG
     SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = spt21.receive_no ),'1') seq , 
              spt21.receive_no, spt21.appl_no , '70012','0',sysdate,'190¼g¤J193'
      from spt21
      WHERE online_flg = 'Y' and online_cout = 'N' AND dept_no = '70012'
      AND spt21.appl_no is not null
      AND ( spt21.process_result != '57001' or spt21.process_result is null)
    ;

   
  dbms_output.put_line('write to log');
     --  must modify the condition when checking the file is ready
    UPDATE spt21 set online_cout = 'Y',processor_no = '70012' 
    WHERE online_flg = 'Y' and online_cout = 'N' AND dept_no = '70012'
    AND spt21.appl_no is not null
    AND ( spt21.process_result != '57001' or spt21.process_result is null)
    AND  exists ( select 1 from s193.receive where receive_no = spt21.receive_no )
     ;
     commit;
     dbms_output.put_line('update spt21 online_cout and processor_no');
  


    ---------------------------------------
    -- add new project from spt31 to appl
    ----------------------------------------
   
     insert into appl(APPL_NO,STEP_CODE,DIVIDE_CODE,DIVIDE_REASON,FINISH_FLAG,
                       RETURN_NO,IS_OVERTIME,PROCESS_DATE,PROCESSOR_NO)
  select spt31.appl_no, '1','0',null,'0','0','0',null,spt31.sch_processor_no
  from spt31 join spt31a on spt31a.appl_no = spt31.appl_no
  where not exists (select 1 from appl where appl.appl_no = spt31.appl_no)
  and spt31a.step_code != '99'
  ;
   /*
  update appl set processor_no = ( select sch_processor_no from spt31 s31 where s31.appl_no = appl.appl_no )
  where appl_no in (select appl_no from spt31 where spt31.appl_no = appl.appl_no and spt31.sch_processor_no != appl.processor_no)
  and appl.is_overtime = '0' and divide_code = '0';
  */
  commit;
 --  p_rec := SQL%RowCount;
   
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('Error Code:' ||  SQLCODE || ' : ' || SQLERRM);   
     raise_application_error(-20001,'Error Code:' ||  SQLCODE || ' : ' || SQLERRM);
    
END RECEIVE193;

/
