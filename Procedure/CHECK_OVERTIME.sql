create or replace PROCEDURE        CHECK_OVERTIME ( p_rec out int)
is
    ecode            number;
    ap_code          varchar2(100);
    p_msg            varchar2(3000);
    rec1 number;
    rec2 number;
    rec_cnt number;
    type APPL_NO_TAB is table of spt41.appl_no%type;
    type FORM_FILE_A_TAB is table of spt41.FORM_FILE_A%type;
    type STEP_CODE_TAB is table of spt31a.step_code%type;  
    type PROCESSOR_NO_TAB is table of spt41.processor_no%type;
    type REASON_TAB is table of varchar2(50);
  
  /*-------------------------------------
  -- ModifyDate : 104/09/17
  -- record project status on 193 system
  --1:個人逾期、2:自動輪辦、
  -- Modify: overtime reason
  -- taketurn processor_no start from the next  of last time recorded in appl_para where sys='OVERTIME' and subsys = 'TAKETURN'
     104/07/22 : not to write back spt31.sch_processor_no
     104/09/17 :(1) modify the return record count 
                (2) if overtime record is exists , do nothing 
  -------------------------------------*/
  PROCEDURE Update_DivideCode(g_app in APPL_NO_TAB,g_form_file_a in FORM_FILE_A_TAB, g_step_code in STEP_CODE_TAB ,g_process_no in PROCESSOR_NO_TAB,g_reason in varchar2)
  is
  begin
    for l_idx in 1 .. g_app.count
      loop
         select count(1) into rec1 from appl where appl_no = g_app(l_idx)  ;
         --- 已逾期或移除逾期 不用再列入
         select count(1) into rec2 from appl where appl_no = g_app(l_idx) and is_overtime ='0' and divide_code = '0';
         
         insert into tmp_appl_overtime values( g_app(l_idx),g_form_file_a(l_idx),g_step_code(l_idx),g_process_no(l_idx),g_reason);
         
         if rec1 = 0  then
            insert into appl
                select g_app(l_idx) ,  g_step_code(l_idx) ,'1',g_reason,null,0,1,'1',null,to_char(to_number(to_char(sysdate,'yyyyMMdd'))-19110000), g_process_no(l_idx),null,'0'
                from dual; 
              
         --   dbms_output.put_line('新增:逾期 ' || g_app(l_idx) || ':' || g_step_code(l_idx) || ':' || g_process_no(l_idx)); 
          end if;
          if rec1 !=0 and rec2>0 then
             update appl
              set step_code =  g_step_code(l_idx), divide_code = '1' , processor_no = g_process_no(l_idx), IS_OVERTIME = '1',divide_reason = g_reason
              where appl_no =  g_app(l_idx)
              and divide_code != '1'; 
            
         --    dbms_output.put_line('修改:逾期 ' ||  g_app(l_idx) || ':' || g_step_code(l_idx) || ':' || g_process_no(l_idx)); 
          end if;
           rec_cnt := rec_cnt + 1;
      end loop;
     commit;
  end Update_DivideCode;
    --1:個人逾期、2:自動輪辦、
  PROCEDURE Update_TakeTurn(g_app in APPL_NO_TAB,g_form_file_a in FORM_FILE_A_TAB, g_step_code in STEP_CODE_TAB ,g_process_no in PROCESSOR_NO_TAB,g_reason in REASON_TAB)
  is
  begin
    for l_idx in 1 .. g_app.count
      loop
         select count(1) into rec1 from appl where appl_no = g_app(l_idx) ;
         -------
         -- for check
         --------
         insert into tmp_appl_overtime values( g_app(l_idx),g_form_file_a(l_idx),g_step_code(l_idx),g_process_no(l_idx),g_reason(l_idx));
        
         if rec1 = 0  then
            insert into appl
                select g_app(l_idx) ,  g_step_code(l_idx) ,'2',g_reason(l_idx),null,0,1,'0',null,to_char(to_number(to_char(sysdate,'yyyyMMdd'))-19110000), g_process_no(l_idx),null,'0'
                from dual; 
               
        --    dbms_output.put_line('新增:自動輪辦 ' || g_app(l_idx) || ':' || g_step_code(l_idx) || ':' || g_process_no(l_idx)); 
          else
            update appl
              set step_code =  g_step_code(l_idx), divide_code = '2' , processor_no =null, ASSIGN_DATE = null, IS_OVERTIME = '1' ,divide_reason = g_reason(l_idx)
              where appl_no =  g_app(l_idx)
              and divide_code != '2'; 
           
          --   dbms_output.put_line('修改:自動輪 ' ||  g_app(l_idx) || ':' || g_step_code(l_idx) || ':' || g_process_no(l_idx)); 
          end if;
           rec_cnt := rec_cnt + 1;
      end loop;
     commit;
  end Update_TakeTurn;
 ---------------------------
 --  新案-初審程序審查, 自動輪辦
 --  先判斷是否要進入自動輪辦,再判斷是否個人逾期
 ---------------------------
PROCEDURE Check_Case1_1
  -- 
  is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
     v_reason REASON_TAB;
BEGIN
     ap_code := 'case1_1';
         
-- 自動輪辦
 
     select s41.appl_no,s41.form_file_a ,s56.step_code, s41.processor_no, case when substr(s41.processor_no,1,1) ='P' then '新申請案外包輪辦' else '新申請案離職輪辦' end 
            bulk collect
            into v_app, v_form_file_a, v_step_code ,v_process_no,v_reason
     from spt41 s41
    join 
    (
    select max(spm56.form_file_a) form_file_a, spm56.appl_no , s31a.type_no ,s31a.step_code
    from spm56 join spt31a s31a on spm56.appl_no = s31a.appl_no
    where  spm56.form_id = 'A02'
    and s31a.step_code = '10'
    group by spm56.appl_no  , s31a.type_no  ,s31a.step_code
    ) s56 on s41.form_file_a = s56.form_file_a and s41.appl_no = s56.appl_no
    left join 
    (
      select appl_no , 
          (case   
               when  (substr(appl_no,4,1) = '1' OR substr(appl_no,4,1) = '2') and  sysdate> add_months(to_date(min(PRIORITY_DATE),'yyyyMMdd'),16 )
                    then 1
               when  (substr(appl_no,4,1) = '3' OR (substr(appl_no,4,1) = '3' and substr(appl_no,10,1) = 'D' )) and  sysdate> add_months(to_date(min(PRIORITY_DATE),'yyyyMMdd'),10 )
                    then 1
              else 0
          end) isOverTime   
      from spt32 
      where    PRIORITY_DOC_FLAG is  null  
               and ACCESS_CODE   is  null  
               and PRIORITY_DATE is not null
               and priority_flag = '1'
      group by appl_no     
    ) s32 on s32.appl_no = s41.appl_no
     left join 
    (
     select appl_no ,sum( case when PRIORITY_DATE is  null then 0
                      else 1 end) cnt
      from spt32 
      where  priority_flag = '1'
       group by appl_no
    ) s32_2  on s32_2.appl_no = s41.appl_no
     left join 
    (
     select appl_no ,sum( case when (PRIORITY_DATE is not null  
               and  (ACCESS_CODE  is not  null  or PRIORITY_DOC_FLAG is not  null)) then 0
            else 1 end) cnt
      from spt32 
       where  priority_flag = '1'
      group by appl_no
    ) s32_3  on s32_3.appl_no = s41.appl_no
    where   trunc(sysdate) > case  when  valid_tw_date2(FILE_LIM_DATE)=0  then  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20 )
                           else  trunc(to_date('21991231','yyyyMMdd') )
                      end   
     and  (s32.isOverTime = '1'  or s32_2.cnt =0  or s32_3.cnt =0)
     and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
     and  exists (select 1 from spm63 where   (processor_no = s41.processor_no or substr(s41.processor_no,1,1)='P' ) and quit_date is not null)
     -- and s41.appl_no = '103112248' -- for test
    ;
   --   dbms_output.put_line('新案,自動輪辦:' || v_app.count);
    Update_TakeTurn(v_app ,v_form_file_a, v_step_code ,v_process_no,v_reason);
  --   dbms_output.put_line('新案,自動輪辦:');
      
END Check_Case1_1;
 ---------------------------
 --  新案-初審程序審查,逾期
 --  先判斷是否要進入自動輪辦,再判斷是否個人逾期
 ---------------------------------
PROCEDURE Check_Case1_2
  -- 
  is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
BEGIN
     ap_code := 'case1_2';
     
    ----------------
    -- '新案,逾期:'
    ---------------
   select s41.appl_no, s41.form_file_a , s56.step_code, s41.processor_no
    bulk collect
    into v_app ,v_form_file_a, v_step_code ,v_process_no
    from spt41 s41
    join 
    (
    select max(spm56.form_file_a) form_file_a, spm56.appl_no , s31a.type_no ,s31a.step_code
    from spm56 join spt31a s31a on spm56.appl_no = s31a.appl_no
    where  spm56.form_id = 'A02'
    and s31a.step_code = '10'
    group by spm56.appl_no  , s31a.type_no  ,s31a.step_code
    ) s56 on s41.form_file_a = s56.form_file_a and s41.appl_no = s56.appl_no
    left join 
    (
      select appl_no , 
          (case 
               when  (substr(appl_no,4,1) = '1' OR substr(appl_no,4,1) = '2') and  sysdate> add_months(to_date(min(PRIORITY_DATE),'yyyyMMdd'),16 )
                    then 1
               when  (substr(appl_no,4,1) = '3' OR (substr(appl_no,4,1) = '3' and substr(appl_no,10,1) = 'D' )) and  sysdate> add_months(to_date(min(PRIORITY_DATE),'yyyyMMdd'),10 )
                    then 1
              else 0
          end) isOverTime   
      from spt32 
      where    PRIORITY_DOC_FLAG is  null  
               and ACCESS_CODE   is  null  
               and PRIORITY_DATE is not null
               and priority_flag = '1'
      group by appl_no     
    ) s32 on s32.appl_no = s41.appl_no
    left join 
    (
     select appl_no ,sum( case when PRIORITY_DATE is  null then 0
                      else 1 end) cnt
      from spt32 
      where  priority_flag = '1'
       group by appl_no
    ) s32_2  on s32_2.appl_no = s41.appl_no
     left join 
    (
     select appl_no ,sum( case when (PRIORITY_DATE is not null  
               and  (ACCESS_CODE  is not  null  or PRIORITY_DOC_FLAG is not  null)) then 0
            else 1 end) cnt
      from spt32 
       where  priority_flag = '1'
      group by appl_no
    ) s32_3  on s32_3.appl_no = s41.appl_no
    where   trunc(sysdate) > case  when  valid_tw_date2(FILE_LIM_DATE)=0  then  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20 )
                           else  trunc(to_date('21991231','yyyyMMdd') )
                      end   
     and  (s32.isOverTime = '1'  or s32_2.cnt =0  or s32_3.cnt =0)
     and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
      and  exists (select 1 from spm63 where  processor_no = s41.processor_no  and quit_date is  null)
      and  substr(s41.processor_no,1,1)!='P'
  --    and s41.appl_no in ('103302035','103210096','103121597','103117249','103301997') -- for test
      ;

     Update_DivideCode(v_app,v_form_file_a , v_step_code ,v_process_no,'新案逾期');
 --   dbms_output.put_line('新案,逾期:');
 
END Check_Case1_2;
  
  ----------------------------
  --再審程序審查
  -----------------------------
  PROCEDURE Check_Case2_1
  --
  is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
     v_reason REASON_TAB;
  BEGIN
   ap_code := 'case2_1';
         
   
      -- 自動輪辦
  
      select s41.appl_no, s41.form_file_a,s56.step_code, s41.processor_no ,'離職人員再審輪辦'
            bulk collect
            into v_app,v_form_file_a, v_step_code ,v_process_no,v_reason
      from spt41 s41
     join 
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no , s31a.type_no ,s31a.step_code
      from spm56 join spt31a s31a on spm56.appl_no = s31a.appl_no
      where  spm56.form_id = 'A04'
      and s31a.step_code = '30'
      group by spm56.appl_no  , s31a.type_no  ,s31a.step_code
      ) s56 on s41.form_file_a = s56.form_file_a and s41.appl_no = s56.appl_no
      left join spt32 on spt32.appl_no = s41.appl_no
      where (spt32.data_seq = (select max(s32.data_seq) from spt32 s32 where spt32.appl_no= s32.appl_no) or spt32.data_seq is null)
      and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
      --and sysdate > to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20
      and trunc(sysdate) > case when valid_tw_date2(FILE_LIM_DATE)=1  then trunc(to_date('21991231','yyyyMMdd'))  else  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20) end
      and exists (select 1 from spm63 where processor_no = s41.processor_no and quit_date is not  null)
      ;
 
      Update_TakeTurn(v_app ,v_form_file_a, v_step_code ,v_process_no,v_reason);
  --   dbms_output.put_line('審查自動輪辦');
      
  END Check_Case2_1;
  
  PROCEDURE Check_Case2_2
  --
  is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
  BEGIN
   ap_code := 'case2_2';
        
     ---再審,逾期
       select s41.appl_no , s41.form_file_a,s56.step_code, s41.processor_no
         bulk collect
         into v_app ,v_form_file_a , v_step_code ,v_process_no
     from spt41 s41
     join 
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no , s31a.type_no ,s31a.step_code
      from spm56 join spt31a s31a on spm56.appl_no = s31a.appl_no
      where  spm56.form_id = 'A04'
      and s31a.step_code = '30'
      group by spm56.appl_no  , s31a.type_no  ,s31a.step_code
      ) s56 on s41.form_file_a = s56.form_file_a and s41.appl_no = s56.appl_no
      left join spt32 on spt32.appl_no = s41.appl_no
      where (spt32.data_seq = (select max(s32.data_seq) from spt32 s32 where spt32.appl_no= s32.appl_no) or spt32.data_seq is null)
      and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
      --and sysdate > to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20
      and trunc(sysdate) > case when valid_tw_date2(FILE_LIM_DATE)=1  then trunc(to_date('21991231','yyyyMMdd'))  else  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20) end
      and exists (select 1 from spm63 where  processor_no = s41.processor_no and quit_date is  null)
  --    and s41.appl_no in ('101305523','101150129','102115604')  -- for test
      ;
     Update_DivideCode(v_app ,v_form_file_a, v_step_code ,v_process_no,'再審逾期');
    --    dbms_output.put_line('再審逾期:');
 
  END Check_Case2_2;
  
  ----------------------------
  -- 待實體審查
  -----------------------------
  PROCEDURE Check_Case3_1
  --  
  is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
     v_reason REASON_TAB;
  BEGIN
  ap_code := 'case3_1';
         
      
     select s41.appl_no, s41.form_file_a,s56.step_code, s41.processor_no ,'離職人員實體審查輪辦'
            bulk collect
            into v_app,v_form_file_a, v_step_code ,v_process_no,v_reason
      from spt41 s41
      join 
      (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no , s31a.type_no ,s31a.step_code
      from spm56 join spt31a s31a on spm56.appl_no = s31a.appl_no
      where ( spm56.form_id = 'P18' or spm56.form_id = 'P19' )
      and s31a.step_code = '16'
      group by spm56.appl_no  , s31a.type_no  ,s31a.step_code
      ) s56 on s41.form_file_a = s56.form_file_a and s41.appl_no = s56.appl_no
      where (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
      and trunc(sysdate) > case when valid_tw_date2(FILE_LIM_DATE)=1  then trunc(to_date('21991231','yyyyMMdd'))  else  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20) end
      and not exists ( select 1 from spm56 where spm56.appl_no = s56.appl_no and spm56.form_id = 'P32')
      and s41.appl_no >= '091132001'
      and exists (select 1 from spm63 where  processor_no = s41.processor_no and quit_date is not null)
   --   and s41.appl_no >= '091132001'
      ;     
   
        
     Update_TakeTurn(v_app,v_form_file_a , v_step_code ,v_process_no,v_reason);
  --   dbms_output.put_line('離職人員實體審查輪辦');
 
  END check_case3_1;
  
  PROCEDURE Check_Case3_2
  --  
  is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
  BEGIN
  ap_code := 'case3_2';
         

      select s41.appl_no , s41.form_file_a,s56.step_code, s41.processor_no
         bulk collect
         into v_app, v_form_file_a , v_step_code ,v_process_no
      from spt41 s41
      join 
      (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no , s31a.type_no ,s31a.step_code
      from spm56 join spt31a s31a on spm56.appl_no = s31a.appl_no
      where ( spm56.form_id = 'P18' or spm56.form_id = 'P19' )
      and s31a.step_code = '16'
      group by spm56.appl_no  , s31a.type_no  ,s31a.step_code
      ) s56 on s41.form_file_a = s56.form_file_a and s41.appl_no = s56.appl_no
      where (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
      and trunc(sysdate) > case when valid_tw_date2(FILE_LIM_DATE)=1  then trunc(to_date('21991231','yyyyMMdd'))  else  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20) end
      and not exists ( select 1 from spm56 where spm56.appl_no = s56.appl_no and spm56.form_id = 'P32')
      and exists (select 1 from spm63 where  processor_no = s41.processor_no and quit_date is  null)
      and s41.appl_no >= '091132001'
      and exists ( select 1 from spt31 where spt31.appl_no = s41.appl_no and spt31.material_appl_date is  null)
      ;
     Update_DivideCode(v_app ,v_form_file_a, v_step_code ,v_process_no,'實體審查逾期');
  --    dbms_output.put_line('實體審查,逾期');
 
  END check_case3_2;
  ----------------------------
  -- 讓與
  -----------------------------
  PROCEDURE Check_Case4_1
  --  
  is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
     v_reason REASON_TAB;
  BEGIN
  ap_code := 'case4_1';
        
   -- 自動輪辦

     
      select s41.appl_no , s41.form_file_a,s56.step_code, s41.processor_no,'離職人員讓與輪辦'
            bulk collect
            into v_app,v_form_file_a, v_step_code ,v_process_no,v_reason
           from  spt41 s41
     join
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no  ,s31a.step_code
      from spm56 
      join spt31a s31a on spm56.appl_no = s31a.appl_no
   --   join spt41 s41 on S41.Form_File_A = spm56.form_file_a 
      where  substr(spm56.appl_no,4,1) = '1' -- 只清查發明案
       and s31a.step_code in ('16','20')
       and s31a.appl_no not in ( select s.appl_no from spt41 s  join spm56 s56 on s.form_file_a = s56.form_file_a
                             where  s.appl_no = s31a.appl_no 
                             and s.issue_no > (select max(issue_no) from spt41 where s.appl_no = spt41.appl_no   and issue_type = '40007')
                             and ( (s.issue_type = '40101' and s56.form_id = 'B38')
                               or ( s.issue_type = '40103' and s56.form_id = 'B38')   
                               or ( s56.form_id  in ('P03-1','A06','P31') )
                               )
                        )
       and exists (select 1 from spt41 s2 where  s2.appl_no =  s31a.appl_no and s2.issue_type = '40007')
      group by spm56.appl_no  , s31a.step_code
       )  s56 on  s41.form_file_a = s56.form_file_a 
      where     ( s41.file_d_flag is null or s41.file_d_flag = ' ')
        and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
   --    and not exists (select 1 from spm56 where spm56.appl_no = s41.appl_no and spm56.form_file_a >s41.form_file_a and spm56.form_id  in ('P03-1','A06','P31'))
      and trunc(sysdate) > case when valid_tw_date2(FILE_LIM_DATE)=1  then trunc(to_date('21991231','yyyyMMdd'))  else  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20) end
       and exists (select 1 from spm63 where  processor_no = s41.processor_no  and quit_date is not null )
    ;
   Update_TakeTurn(v_app ,v_form_file_a, v_step_code ,v_process_no,v_reason);
 --   dbms_output.put_line('讓與,自動輪辦:');
 
  END Check_Case4_1;
  
  
   PROCEDURE Check_Case4_2
  --  
  is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
  BEGIN
  ap_code := 'case4_2';
        
     select s41.appl_no , s41.form_file_a,s56.step_code, s41.processor_no
         bulk collect
         into v_app,v_form_file_a , v_step_code ,v_process_no
      from  spt41 s41
     join
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no  ,s31a.step_code
      from spm56 
      join spt31a s31a on spm56.appl_no = s31a.appl_no
   --   join spt41 s41 on S41.Form_File_A = spm56.form_file_a 
      where  substr(spm56.appl_no,4,1) = '1' -- 只清查發明案
       and s31a.step_code in ('16','20')
       and s31a.appl_no not in ( select s.appl_no from spt41 s  join spm56 s56 on s.form_file_a = s56.form_file_a
                             where  s.appl_no = s31a.appl_no 
                             and s.issue_no > (select max(issue_no) from spt41 where s.appl_no = spt41.appl_no   and issue_type = '40007')
                             and ( (s.issue_type = '40101' and s56.form_id = 'B38')
                               or ( s.issue_type = '40103' and s56.form_id = 'B38')   
                               or ( s56.form_id  in ('P03-1','A06','P31') )
                               )
                        )
       and exists (select 1 from spt41 s2 where  s2.appl_no =  s31a.appl_no and s2.issue_type = '40007')
      group by spm56.appl_no  , s31a.step_code
       )  s56 on  s41.form_file_a = s56.form_file_a 
      where     ( s41.file_d_flag is null or s41.file_d_flag = ' ')
        and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
   --    and not exists (select 1 from spm56 where spm56.appl_no = s41.appl_no and spm56.form_file_a >s41.form_file_a and spm56.form_id  in ('P03-1','A06','P31'))
      and trunc(sysdate) > case when valid_tw_date2(FILE_LIM_DATE)=1  then trunc(to_date('21991231','yyyyMMdd'))  else  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20) end
       and exists (select 1 from spm63 where  processor_no = s41.processor_no  and quit_date is  null )
   ;
    Update_DivideCode(v_app,v_form_file_a , v_step_code ,v_process_no,'讓與逾期');
   --    dbms_output.put_line('讓與,逾期:');


  END check_case4_2;
  ----------------------------
  -- 變更
  -----------------------------
PROCEDURE Check_Case5_1
  --  
  is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
     v_reason REASON_TAB;
  BEGIN
  ap_code := 'case5_1';
        
    
     select s41.appl_no , s41.form_file_a,s56.step_code, s41.processor_no,'離職人員變更輪辦'
            bulk collect
            into v_app,v_form_file_a, v_step_code ,v_process_no,v_reason
       from  spt41 s41
     join
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no , s31a.type_no ,s31a.step_code
      from spm56 
      join spt31a s31a on spm56.appl_no = s31a.appl_no
      where  substr(s31a.appl_no,4,1) = '1' -- 只清查發明案
       and s31a.step_code in ('16','20')
        group by spm56.appl_no  , s31a.type_no  ,s31a.step_code
       )  s56 on s41.form_file_a = s56.form_file_a and s41.appl_no = s56.appl_no
      where    s41.appl_no in 
      ( select appl_no
      from  spt41 s41
      where      ( s41.file_d_flag is null or s41.file_d_flag = ' ')
       and s41.issue_type = '40009'
       and  substr(s41.appl_no,4,1) = '1' -- 只清查發明案
       and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
       and not exists ( select 1 from spm56 where spm56.appl_no = s41.appl_no and spm56.form_id in ('C09','C09-1','C09-2','C09-3','C10','P03-1','A06','P32') )
       and (select count(1) from spt41  where spt41.appl_no = s41.appl_no and spt41.process_result is null) =0
       )
      and trunc(sysdate) > case when valid_tw_date2(FILE_LIM_DATE)=1  then trunc(to_date('21991231','yyyyMMdd'))  else  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20) end
      and exists (select 1 from spm63 where processor_no = s41.processor_no  and quit_date is not  null )
      ;
     Update_TakeTurn(v_app,v_form_file_a , v_step_code ,v_process_no,v_reason);
   --    dbms_output.put_line('變更,輪辦:');

 
  END Check_Case5_1;
  
  PROCEDURE Check_Case5_2
  --  
  is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
  BEGIN
  ap_code := 'case5_2';
        
    
      select s41.appl_no,s41.form_file_a,s56.step_code, s41.processor_no
         bulk collect
         into v_app ,v_form_file_a, v_step_code ,v_process_no
       from  spt41 s41
     join
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no , s31a.type_no ,s31a.step_code
      from spm56 
      join spt31a s31a on spm56.appl_no = s31a.appl_no
      where  substr(s31a.appl_no,4,1) = '1' -- 只清查發明案
       and s31a.step_code in ('16','20')
        group by spm56.appl_no  , s31a.type_no  ,s31a.step_code
       )  s56 on s41.form_file_a = s56.form_file_a and s41.appl_no = s56.appl_no
      where    s41.appl_no in 
      ( select appl_no
      from  spt41 s41
      where     ( s41.file_d_flag is null or s41.file_d_flag = ' ')
       and s41.issue_type = '40009'
       and  substr(s41.appl_no,4,1) = '1' -- 只清查發明案
       and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
       and not exists ( select 1 from spm56 where spm56.appl_no = s41.appl_no and spm56.form_id in ('C09','C09-1','C09-2','C09-3','C10','P03-1','A06','P32') )
       and (select count(1) from spt41  where spt41.appl_no = s41.appl_no and spt41.process_result is null) =0
       )
      and trunc(sysdate) > case when valid_tw_date2(FILE_LIM_DATE)=1  then trunc(to_date('21991231','yyyyMMdd'))  else  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20) end
    --   and s41.appl_no in ('100102735','101116862','101116442')    -- for test
       and exists (select 1 from spm63 where processor_no = s41.processor_no  and quit_date is  null )
      ;
     Update_DivideCode(v_app ,v_form_file_a , v_step_code ,v_process_no,'變更逾期');
    --   dbms_output.put_line('變更,逾期:');

 
  END Check_Case5_2;
----------------------------
-- 延長
-----------------------------
PROCEDURE Check_Case6_1
  --  
is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
     v_reason REASON_TAB;
BEGIN
   ap_code := 'case6_1';
         
     -- 自動輪辦
    
      select s21.appl_no,null,spt31a.step_code, s21.processor_no,'離職人員延長專利權輪辦'
       bulk collect
      into v_app,v_form_file_a , v_step_code ,v_process_no,v_reason
       from spt41 s41
     join spt21 s21 on s21.receive_no  = s41.receive_no
      join spt31a on s21.appl_no = spt31a.appl_no
      where  s41.issue_type = '22210'
      and trunc(sysdate) > trunc(add_months(to_date(to_char(to_number(substr(lpad(trim(s21.RECEIVE_DATE),7,'0'),1,3))+1911) || substr( lpad(trim(s21.RECEIVE_DATE),7,'0'),4,4),'yyyyMMdd'),7))
      and exists (select 1 from spm63 where  processor_no = s41.processor_no and quit_date is null) 
      and not exists ( select 1 from spm56 where spm56.form_file_a = s41.form_file_a and spm56.form_id = 'A06-2')
      and exists
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no 
      from spm56 join spt41 on spm56.form_file_a = spt41.Form_File_A
      where  spm56.form_id = 'E01'
      and exists ( select 1 from spm63 where  processor_no = spt41.processor_no and quit_date is not null)
      and  s41.appl_no = spm56.appl_no 
      group by spm56.appl_no 
      )  
      ;
     Update_TakeTurn(v_app ,v_form_file_a, v_step_code ,v_process_no,v_reason);
   --  dbms_output.put_line('延長,自動輪辦');
 
  END Check_Case6_1;
  
  PROCEDURE Check_Case6_2
  --  
is
     v_app APPL_NO_TAB;
     v_form_file_a FORM_FILE_A_TAB;
     v_step_code STEP_CODE_TAB;
     v_process_no PROCESSOR_NO_TAB;
BEGIN
   ap_code := 'case6_2';
         
      select s21.appl_no,null,spt31a.step_code, s21.processor_no
       bulk collect
      into v_app ,v_form_file_a, v_step_code ,v_process_no
       from spt41 s41
     join spt21 s21 on s21.receive_no  = s41.receive_no
      join spt31a on s21.appl_no = spt31a.appl_no
      where  s41.issue_type = '22210'
      and trunc(sysdate) > trunc(add_months(to_date(to_char(to_number(substr(lpad(trim(s21.RECEIVE_DATE),7,'0'),1,3))+1911) || substr( lpad(trim(s21.RECEIVE_DATE),7,'0'),4,4),'yyyyMMdd'),7))
      and exists (select 1 from spm63 where  processor_no = s41.processor_no and quit_date is null) 
      and not exists ( select 1 from spm56 where spm56.form_file_a = s41.form_file_a and spm56.form_id = 'A06-2')
      and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
      and exists
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no 
      from spm56 join spt41 on spm56.form_file_a = spt41.Form_File_A
      where  spm56.form_id = 'E01'
      and exists ( select 1 from spm63 where  processor_no = spt41.processor_no and quit_date is null)
      and  s41.appl_no = spm56.appl_no 
      group by spm56.appl_no 
      ) 
      ;
       Update_DivideCode(v_app ,v_form_file_a, v_step_code ,v_process_no,'延長逾期');
   --   dbms_output.put_line('延長,逾期');
 
  END Check_Case6_2;
  
  PROCEDURE Assign_AutoTurn
  IS
    CURSOR d_curosr IS
      select appl_no from appl where divide_code = '2' and assign_date is null;
      
    type PROCESSOR_NO_TAB is table of appl.processor_no%type;
    v_process_no PROCESSOR_NO_TAB;
    l_appl_no     spt31.appl_no%type;
    l_idx number;
    l_processor_no skill.processor_no%type;
  BEGIN
  
    select trim(processor_no) 
    bulk collect
    into v_process_no
    from skill where auto_shift = '1'
    order by processor_no
    ;
   
      -- record the last assign processor 
     select trim(para_no) into l_processor_no from appl_para where sys = 'OVERTIME' and subsys = 'TAKETURN';
     if l_processor_no is null then
          l_idx := 0;
     else
          select  seq into l_idx
          from
            (
             select skill.processor_no,rownum seq
             from skill 
             where auto_shift = '1'
             order by processor_no
           ) where processor_no = l_processor_no
           ;
            IF l_idx = v_process_no.count THEN
                l_idx := 0;
             END IF;
     end if;
     
   
     OPEN d_curosr;
     LOOP
     FETCH d_curosr
      INTO l_appl_no;
     EXIT WHEN d_curosr%NOTFOUND;
        l_idx := l_idx +1;
      --  SYS.Dbms_Output.Put_Line(v_process_no(l_idx) || ':' || l_appl_no);
         update appl set processor_no = v_process_no(l_idx),
                         assign_date = to_char(to_number(to_char(sysdate,'yyyyMMdd')-19110000))
         where appl_no = l_appl_no;
      --   Dbms_Output.Put_Line(SQL%RowCount|| ': update appl');
      --- 104/07/21 Test Meeting ,decide not to write back to 190 table SPT31
      --    UPDATE SPT31   SET SCH_PROCESSOR_NO =  v_process_no(l_idx)    WHERE APPL_NO = l_appl_no;
       --   Dbms_Output.Put_Line(SQL%RowCount|| ': update SPT31 processor_no : ' ||  v_process_no(l_idx) || '; l_appl_no:' ||l_appl_no);
     
       IF l_idx = v_process_no.count THEN
           l_idx := 0;
       END IF;
     END LOOP;
    
     CLOSE d_curosr;
     
     update  appl_para set para_no =   v_process_no(l_idx) where sys = 'OVERTIME' and subsys = 'TAKETURN' ;
     
  END;

  
BEGIN

  rec_cnt :=0;
   delete  tmp_appl_overtime;
   commit;
 
   check_case1_1;
   -- dbms_output.put_line(' check_case1_1 Finish!!');
   check_case1_2;
   -- dbms_output.put_line(' check_case1_2 Finish!!');   
   check_case2_1;
   --dbms_output.put_line(' check_case2_1 Finish!!');
   check_case2_2;    
   --dbms_output.put_line(' check_case2_2 Finish!!');
   check_case3_1;
   --dbms_output.put_line(' check_case3_1 Finish!!');
   check_case3_2;
   --dbms_output.put_line(' check_case3_2 Finish!!');
   check_case4_1;
   --dbms_output.put_line(' check_case4_1 Finish!!');
   check_case4_2;
   --dbms_output.put_line(' check_case4_2 Finish!!');
   check_case5_1;
   --dbms_output.put_line(' check_case5_1 Finish!!');
   check_case5_2;
   --dbms_output.put_line(' check_case5_2 Finish!!');
   check_case6_1;
   --dbms_output.put_line(' check_case6_1 Finish!!');
   check_case6_2;
   --dbms_output.put_line(' check_case6_2 Finish!!');
   
   Assign_AutoTurn;
   
   commit;
    p_rec := rec_cnt;
   dbms_output.put_line('Finish!!' || p_rec);
EXCEPTION
  WHEN OTHERS THEN
   ecode := SQLCODE;
   p_msg := ap_code || ':' || SQLCODE || ':' || SQLERRM; 
   -- dbms_output.put_line('Error Code:' || ecode || '; Error Message:' || p_msg);
END CHECK_OVERTIME;