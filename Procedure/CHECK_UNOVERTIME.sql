create or replace PROCEDURE        CHECK_UNOVERTIME ( p_rec out int)
is
    p_msg            varchar2(100);
    ap_code          varchar2(10);
    l_appl_no        appl.appl_no%type;
    ecode            number;
    l_exist          number;
    cnt              number;
    update_cnt       number;
    CURSOR appl_cursor IS
    select appl_no
      from appl
     where divide_code in ('1','2')
     and IS_OVERTIME = '1'
    order by appl_no;
  
 ---------------------------
 -- remove overtime or taketurn status
 -- divide_code = 1 is overtime project / divide_code = 2 is taketurn project
 -- ModifyDate : 104/09/17
 -- 
 --  先判斷是否要進入自動輪辦,再判斷是否個人逾期
 -- Modify : update the condition 
 -- 104/08/11 : remove takturn status
 -- 104/09/17 : new project doesn't set the outsourcing condistion 
 ---------------------------------
PROCEDURE Check_Case1(p_appl_no in char, p_is_exist out number)
  -- 
  is

BEGIN
     ap_code := 'case1';
     
    ----------------
    -- '新案,逾期:'
    ---------------
   select case when  count(1) >0 then '1' else '0' end into p_is_exist
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
               and appl_no = p_appl_no
      group by appl_no     
    ) s32 on s32.appl_no = s41.appl_no
    left join 
    (
     select appl_no ,sum( case when PRIORITY_DATE is  null then 0
                      else 1 end) cnt
      from spt32 
      where  priority_flag = '1'
      and appl_no = p_appl_no
       group by appl_no
    ) s32_2  on s32_2.appl_no = s41.appl_no
     left join 
    (
     select appl_no ,sum( case when (PRIORITY_DATE is not null  
               and  (ACCESS_CODE  is not  null  or PRIORITY_DOC_FLAG is not  null)) then 0
            else 1 end) cnt
      from spt32 
       where  priority_flag = '1'
       and appl_no = p_appl_no
      group by appl_no
    ) s32_3  on s32_3.appl_no = s41.appl_no
    where   trunc(sysdate) > case  when  valid_tw_date2(FILE_LIM_DATE)=0  then  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20 )
                           else  trunc(to_date('21991231','yyyyMMdd') )
                      end   
     and  (s32.isOverTime = '1'  or s32_2.cnt =0  or s32_3.cnt =0)
     and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
    --  and  exists (select 1 from spm63 where  processor_no = s41.processor_no  and quit_date is  null)
    --  and  substr(s41.processor_no,1,1)!='P'
      and s41.appl_no = p_appl_no
      ;

     
 --   dbms_output.put_line('新案,逾期:');
 
END Check_Case1;
  
  ----------------------------
  --再審程序審查
  -----------------------------
   
  PROCEDURE Check_Case2(p_appl_no in char, p_is_exist out number)
  --
  is

  BEGIN
   ap_code := 'case2';
        
     ---再審,逾期
     select case when  count(1) >0 then '1' else '0' end into p_is_exist
     from spt41 s41
     join 
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no , s31a.type_no ,s31a.step_code
      from spm56 join spt31a s31a on spm56.appl_no = s31a.appl_no
      where  spm56.form_id = 'A04'
      and s31a.step_code = '30'
      and s31a.appl_no = p_appl_no
      group by spm56.appl_no  , s31a.type_no  ,s31a.step_code
      ) s56 on s41.form_file_a = s56.form_file_a and s41.appl_no = s56.appl_no
      left join spt32 on spt32.appl_no = s41.appl_no
      where (spt32.data_seq = (select max(s32.data_seq) from spt32 s32 where spt32.appl_no= s32.appl_no) or spt32.data_seq is null)
      and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
      --and sysdate > to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20
      and trunc(sysdate) > case when valid_tw_date2(FILE_LIM_DATE)=1  then trunc(to_date('21991231','yyyyMMdd'))  else  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20) end
     -- and exists (select 1 from spm63 where  processor_no = s41.processor_no and quit_date is  null)
      and s41.appl_no = p_appl_no
      ;
     
    --    dbms_output.put_line('審查逾期:');
 
  END Check_Case2;
  
  ----------------------------
  -- 待實體審查
  -----------------------------  
  PROCEDURE Check_Case3(p_appl_no in char, p_is_exist out number)
  --  
  is
 
  BEGIN
  ap_code := 'case3';
         

      select case when  count(1) >0 then '1' else '0' end into p_is_exist
        from spt41 s41
      join 
      (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no , s31a.type_no ,s31a.step_code
      from spm56 join spt31a s31a on spm56.appl_no = s31a.appl_no
      where ( spm56.form_id = 'P18' or spm56.form_id = 'P19' )
      and s31a.step_code = '16'
      and s31a.appl_no = p_appl_no
      group by spm56.appl_no  , s31a.type_no  ,s31a.step_code
      ) s56 on s41.form_file_a = s56.form_file_a and s41.appl_no = s56.appl_no
      where (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
      and trunc(sysdate) > case when valid_tw_date2(FILE_LIM_DATE)=1  then trunc(to_date('21991231','yyyyMMdd'))  else  trunc(to_date(to_char(to_number(substr(s41.FILE_LIM_DATE,1,3))+1911) || substr( s41.FILE_LIM_DATE,4,4),'yyyyMMdd')+20) end
      and not exists ( select 1 from spm56 where spm56.appl_no = s56.appl_no and spm56.form_id = 'P32')
    --  and exists (select 1 from spm63 where  processor_no = s41.processor_no and quit_date is  null)
      and s41.appl_no >= '091132001'
  --    and exists ( select 1 from spt31 where spt31.appl_no = s41.appl_no and spt31.material_appl_date is  null)
      and s41.appl_no = p_appl_no
     ;
     
  --    dbms_output.put_line('實體審查,逾期');
 
  END check_case3;
  ----------------------------
  -- 讓與
  -----------------------------
   PROCEDURE Check_Case4(p_appl_no in char, p_is_exist out number)
  --  
  is
   
  BEGIN
  ap_code := 'case4';
        
     select case when  count(1) >0 then '1' else '0' end into p_is_exist
        from  spt41 s41
     join
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no  ,s31a.step_code
      from spm56 
      join spt31a s31a on spm56.appl_no = s31a.appl_no
   --   join spt41 s41 on S41.Form_File_A = spm56.form_file_a 
      where  substr(spm56.appl_no,4,1) = '1' -- 只清查發明案
       and s31a.step_code in ('16','20')
       and s31a.appl_no = p_appl_no
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
    --   and exists (select 1 from spm63 where  processor_no = s41.processor_no  and quit_date is  null )
       and s41.appl_no = p_appl_no
     ;
    
 --     dbms_output.put_line('讓與,逾期:' || p_is_exist);


  END check_case4;
  ----------------------------
  -- 變更
  -----------------------------  
  PROCEDURE Check_Case5(p_appl_no in char, p_is_exist out number)
  --  
  is
  
  BEGIN
  ap_code := 'case5';
        
    
      select case when  count(1) >0 then '1' else '0' end into p_is_exist
      from  spt41 s41
     join
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no , s31a.type_no ,s31a.step_code
      from spm56 
      join spt31a s31a on spm56.appl_no = s31a.appl_no
      where  substr(s31a.appl_no,4,1) = '1' -- 只清查發明案
       and s31a.step_code in ('16','20')
       and s31a.appl_no = p_appl_no
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
   --    and exists (select 1 from spm63 where processor_no = s41.processor_no  and quit_date is  null )
       and s41.appl_no = p_appl_no
      ;
    
    --   dbms_output.put_line('變更,逾期:');

 
  END Check_Case5;
----------------------------
-- 延長
----------------------------- 
  PROCEDURE Check_Case6(p_appl_no in char, p_is_exist out number)
  --  
is
  
BEGIN
   ap_code := 'case6';
         
      select case when  count(1) >0 then '1' else '0' end into p_is_exist
       from spt41 s41
      join spt21 s21 on s21.receive_no  = s41.receive_no
      join spt31a on s21.appl_no = spt31a.appl_no
      where  s41.issue_type = '22210'
      and trunc(sysdate) > trunc(add_months(to_date(to_char(to_number(substr(lpad(trim(s21.RECEIVE_DATE),7,'0'),1,3))+1911) || substr( lpad(trim(s21.RECEIVE_DATE),7,'0'),4,4),'yyyyMMdd'),7))
     -- and exists (select 1 from spm63 where  processor_no = s41.processor_no and quit_date is null) 
      and not exists ( select 1 from spm56 where spm56.form_file_a = s41.form_file_a and spm56.form_id = 'A06-2')
      and (select count(1) from spt21 s21 where s21.appl_no = s41.appl_no and process_result is null) =0
      and exists
     (
      select max(spm56.form_file_a) form_file_a, spm56.appl_no 
      from spm56 join spt41 on spm56.form_file_a = spt41.Form_File_A
      where  spm56.form_id = 'E01'
     -- and exists ( select 1 from spm63 where  processor_no = spt41.processor_no and quit_date is null)
      and  s41.appl_no = spm56.appl_no 
      and spm56.appl_no = p_appl_no
      group by spm56.appl_no 
      ) 
       and s41.appl_no = p_appl_no
      ;
      
   --   dbms_output.put_line('延長,逾期');
 
  END Check_Case6;
 

BEGIN

  update_cnt := 0;
 
  OPEN appl_cursor;
  LOOP
    FETCH appl_cursor
      INTO l_appl_no;
    EXIT WHEN appl_cursor%NOTFOUND;
      -- initial
       l_exist :=0;
       cnt :=0;
       check_case1(l_appl_no,l_exist);
       cnt := cnt + l_exist;
       -- initial
       l_exist :=0;
       
       check_case2(l_appl_no,l_exist);
       cnt := cnt + l_exist;
       -- initial
       l_exist :=0;
       check_case3(l_appl_no,l_exist);
       cnt := cnt + l_exist;
       -- initial
       l_exist :=0;
       check_case4(l_appl_no,l_exist);
       cnt := cnt + l_exist;
       -- initial
       l_exist :=0;
       check_case5(l_appl_no,l_exist);
       cnt := cnt + l_exist;
       -- initial
       l_exist :=0;
       check_case6(l_appl_no,l_exist);
       cnt := cnt + l_exist;
    --    dbms_output.put_line(l_appl_no || ' : cnt=' || cnt);
       -----------------
       -- if didn't exist in any overtime list then remove it from list
       -----------------
      
       if cnt = 0 then -- overtime condition is not exist
            update appl
              set  IS_OVERTIME = '0' ,
                   DIVIDE_CODE  = '0',
                   ASSIGN_DATE = null
              where appl_no = l_appl_no; 
             dbms_output.put_line( l_appl_no || ' update !');
              
              update_cnt := update_cnt +1;
       end if;
      
  END LOOP;
  CLOSE appl_cursor;
          
   commit;
   p_rec := update_cnt;
   dbms_output.put_line('Finish!!' || p_rec);
EXCEPTION
  WHEN OTHERS THEN
   ecode := SQLCODE;
   p_msg := ap_code || ':' || SQLCODE || ':' || SQLERRM; 
    dbms_output.put_line('Error Code:' || ecode || '; Error Message:' || p_msg);
END CHECK_UNOVERTIME;