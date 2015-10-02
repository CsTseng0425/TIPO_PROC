create or replace PROCEDURE        GET_RECEIVE (p_object_id in varchar2,
                                        p_quota     in number,
                                        p_out_msg   out varchar2) is
---------------------------------
-- Get receive
-- Modify Date : 104/07/16
-- Get type_no from spt21
-- 5/20 record transfer history
-- 6/2  change receive_trans_log schema
-- 6/25 update process_date
-- 104/07/16 change the rule of getting number ,reference parameter
---------------------------------
  type receive_no_tab is table of spt21.receive_no%type;
  l_rec        number;
  l_rec2       number;
  g_difference number;
  g_total      number;
  g_maxNO      number;
  g_holdNO     number;
  ecode        number;
  g_reason     nvarchar2(100);
  v_rec_no   char(15);
  v_pre_no   char(15);
  v_receive_date char(7);
  
  CURSOR list_cursor IS 
     select distinct spt21.receive_date,  tmp.receive_no, tmp.pre_no 
    from  tmp_get_receive tmp join spt21 on  tmp.receive_no = spt21.receive_no
    where  (exists (select processor_no
                      from skill
                     where (case
                             when tmp.skill = 'INVENTION' then  INVENTION
                             when tmp.skill = 'UTILITY' then   UTILITY
                             when tmp.skill = 'DESIGN' then    DESIGN
                             when tmp.skill = 'DERIVATIVE' then  DERIVATIVE
                             when tmp.skill = 'IMPEACHMENT' then IMPEACHMENT
                             when tmp.skill = 'REMEDY' then     REMEDY
                             when tmp.skill = 'PETITION' then  PETITION
                             when tmp.skill = 'DIVIDING' then  DIVIDING
                             when tmp.skill = 'CONVERTING' then CONVERTING
                             when tmp.skill = 'DIVIDING_AMEND' then  DIVIDING_AMEND
                             when tmp.skill = 'CONVERTING_AMEND' then   CONVERTING_AMEND
                             when tmp.skill = 'MISC_AMEND' then MISC_AMEND
                           end) = '1'
                       and processor_no = p_object_id --:login_user  -- 
                    ) )
    order by  spt21.receive_date,  tmp.pre_no,tmp.receive_no
    ;
     
/*
不限要求件數,一?領取
*/
procedure transfer_p
  --移轉文號
  is
  begin
  
    select count(1) into g_total from tmp_get_receive where skill = p_object_id and is_get = '0';
   
    update receive set step_code = '2', processor_no  = p_object_id , process_date = to_char(to_number(to_char(sysdate,'yyyyMMdd'))-19110000)
          where receive_no in (select receive_no from tmp_get_receive where skill = p_object_id  and is_get = '0');
    update spt21 set  processor_no  = p_object_id ,process_result = null
          where receive_no in (select receive_no from tmp_get_receive where skill = p_object_id and is_get = '0');
          
          
    update spt31
    set sch_processor_no= p_object_id, phy_processor_no = p_object_id
    where appl_no in 
    (
      select appl_no from spt31a
      where appl_no in
      (
      select appl_no from  spt21   where receive_no in (select receive_no from tmp_get_receive where skill = p_object_id and is_get = '0')
          )
        and substr(appl_no,10,1) != 'N'
        and ((step_code between '10' and '19'  and step_code != '15')
              or step_code = '30'
              or step_code = '29'
              or step_code = '49'
              or  exists (
                select 1 from  spt21   where receive_no in (select receive_no from tmp_get_receive where skill = p_object_id and is_get = '0')
               and  type_no in ('16000','16002','22210')
          )
        ))
      ;
     ---------------------
    -- record receive transfer history
    ---------------------
      INSERT INTO RECEIVE_TRANS_LOG
      SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1')  seq , 
              receive.receive_no, receive.appl_no , p_object_id,'2',sysdate,'領辦'
      from receive
       where receive_no in (select receive_no from tmp_get_receive where skill = p_object_id  and is_get = '0');
         
    update tmp_get_receive  set  is_get ='1'  
    where receive_no in (select receive_no from tmp_get_receive where skill = p_object_id and is_get = '0');
              
    commit;
  end;

/*--------------
  判斷領取件數
----------------*/
  procedure transfer
  --移轉文號
   is
  begin
  
    OPEN list_cursor;
   LOOP
      FETCH list_cursor INTO v_receive_date,v_rec_no,v_pre_no ;
       EXIT WHEN  list_cursor%NOTFOUND;
           
             dbms_output.put_line('v_rec_no:' || v_rec_no || ';v_pre_no:' ||v_pre_no  );
                  l_rec2 := 0;
                
                --- the record should be gotten
                select count(1) into l_rec2 from receive 
                where receive_no in (
                 select distinct receive_no from tmp_get_receive where pre_no = v_pre_no and is_get ='0'                  
                 ) and  step_code = '0';
                
                IF l_rec2 >0 THEN
                  update receive set step_code = '2', processor_no  = p_object_id, process_date = to_char(to_number(to_char(sysdate,'yyyyMMdd'))-19110000)
                  where receive_no in (
                       select distinct receive_no from tmp_get_receive where pre_no = v_pre_no and is_get ='0' 
                       ) and  step_code = '0';
                       
                   l_rec2 := SQL%ROWCOUNT; -- the real records are gotten
                   dbms_output.put_line(l_rec2 || ':'||l_rec2);
                   IF l_rec2 > 0 THEN
                       ---------------------
                        -- record receive transfer history
                       ---------------------
                        INSERT INTO RECEIVE_TRANS_LOG
                        SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1')  seq , 
                                receive.receive_no, receive.appl_no , p_object_id,'2',sysdate,'領辦'
                                from receive
                                where receive_no in (
                                 select distinct receive_no from tmp_get_receive where pre_no = v_pre_no and is_get ='0' 
                                 ) ;
                       ---------------------------------------------
                        update spt21 set  processor_no  = p_object_id , process_result = null  where receive_no in (
                         select distinct receive_no from tmp_get_receive where pre_no = v_pre_no and is_get ='0' 
                          ) ;
                        
                        update spt31
                        set sch_processor_no= p_object_id, phy_processor_no = p_object_id
                        where appl_no in 
                        (
                            select appl_no from spt31a
                              where appl_no in
                              (
                                select appl_no from  spt21   where receive_no in (
                                    select distinct receive_no from tmp_get_receive where pre_no =  v_pre_no
                                    and is_get ='0'             )
                              )
                              and substr(appl_no,10,1) != 'N'
                              and ((step_code between '10' and '19'  and step_code != '15')
                                    or step_code = '30'
                                    or step_code = '29'
                                    or step_code = '49'
                                    or  exists (
                                        select 1 from  spt21   where receive_no in (
                                    select distinct receive_no from tmp_get_receive where pre_no =  v_pre_no
                                    and is_get ='0'             )
                                    and  type_no in ('16000','16002','22210')
                                      )
                                ))
                            ;  
                          
                        update tmp_get_receive  set  is_get ='1'  where pre_no = v_pre_no and is_get ='0' ;
                    END IF;
               commit;
               g_total := g_total + l_rec2;
             END IF;
       EXIT WHEN g_total >= g_difference;
   END LOOP;
   CLOSE list_cursor;
  
  
  end;
  procedure related_case2
  --  外包自動退文,和後續文一起領
  --  需整包全領,判斷條件
   is
   -- v_collect receive_no_tab;
  begin
   dbms_output.put_line('update 外包自動退文');
    update receive
       set return_no = '1', step_code = '0', processor_no = '70012'
     where receive_no in
           (Select distinct a.receive_no
              from receive a
              join receive b
                on a.appl_no = b.appl_no
             where substr(a.processor_no, 1, 1) = 'P'
               And a.step_code = '2'
               and substr(a.receive_no, 4, 1) = '2'
               and a.return_no = '0'
               and exists (select 1
                      from receive b join spt21 s21 on b.receive_no = s21.receive_no
                     where b.appl_no = a.appl_no
                       and substr(b.receive_no, 4, 1) = '3'
                       and b.step_code = '0'
                       and s21.type_no in ('10010','13002','15002','16004','16006',
                                         '24708','17000','24022','24308','21002',
                                         '24004','24010','24018','24028','24060',
                                         '20000','20002','20004','20006','20008',
                                         '20010','24500','24502',
                                         '24714','24716','24712','24720','21400','24706','24710'
                                         ))
                        )
          and not  exists (select 1
                            from spt32
                            where spt32.PRIORITY_NATION_ID = 'TW'
                            and spt32.appl_no = receive.appl_no);
   update spt21
       set  processor_no = '70012'
     where receive_no in
           (Select distinct a.receive_no
              from receive a
              join receive b
                on a.appl_no = b.appl_no
             where substr(a.processor_no, 1, 1) = 'P'
               And a.step_code = '2'
               and substr(a.receive_no, 4, 1) = '2'
               and a.return_no = '0'
               and exists (select 1
                      from receive b join spt21 s21 on b.receive_no = s21.receive_no
                     where b.appl_no = a.appl_no
                       and substr(b.receive_no, 4, 1) = '3'
                       and b.step_code = '0'
                       and s21.type_no in ('10010','13002','15002','16004','16006',
                                         '24708','17000','24022','24308','21002',
                                         '24004','24010','24018','24028','24060',
                                         '20000','20002','20004','20006','20008',
                                         '20010','24500','24502'))
                      );                                         
    commit;                                         
    insert into tmp_get_receive
    select receive_no , pre_no ,'related_case2','MISC_AMEND','外包自動退文,和後續文一起領','0'
      from (Select a.receive_no, a.receive_no pre_no
              from receive a
             where a.return_no = '1'
               And a.step_code = '0'
            union all
            Select b.receive_no , c.receive_no pre_no
              from receive b 
              join (select appl_no ,receive_no
                                   from receive a
                                  where a.return_no = '1'
                                    And a.step_code = '0') c
                  on b.appl_no = c.appl_no
             where substr(b.receive_no, 4, 1) = '3'
               and b.step_code = '0'
               )
     ;
    commit;
  --  g_reason := '外包自動退文,和後續文一起領';

  end related_case2;

begin
  g_difference := p_quota;
  g_total      := 0;
  l_rec        := 0;

  SELECT count(1) into l_rec from receive where step_code = '0' and return_no not in ('4','A','B','C');
 
 ------------------------------------------
 -- Batch , for test
 --------------------------------------------
  -- CHECK_RECEIVE(p_out_msg);
  related_case2;
  transfer_p;
  
  select pname into g_maxNO from parameter where para_no = 'MAX_REC';
  select count(1) into g_holdNO from receive where processor_no = p_object_id and step_code in ('2','3','5');
  
  IF g_holdNO >= g_maxNO THEN
     p_out_msg := '您的線上公文已超過最大件數:' || g_maxNO;
  ELSE
    IF g_maxNO - g_holdNO < p_quota THEN
        g_difference := g_maxNO - g_holdNO ;
    ELSE
        g_difference := p_quota;
    END IF;
    
    transfer;
    
     IF l_rec = 0 THEN
       p_out_msg := '無可領之線上公文';
     ELSE
        IF g_total = 0 THEN
           p_out_msg := '無權限可領';
        ELSE
          p_out_msg := '領取' || g_total || '筆件數';
        END IF;
     END IF;
  END IF;
  
 

  dbms_output.put_line(p_out_msg);
EXCEPTION
  WHEN OTHERS THEN
    ecode     := SQLCODE;
    p_out_msg := SQLCODE || ' : ' || SQLERRM;
    dbms_output.put_line('Error Code:' || ecode || '; Error Message:' ||
                         p_out_msg);
END GET_RECEIVE;