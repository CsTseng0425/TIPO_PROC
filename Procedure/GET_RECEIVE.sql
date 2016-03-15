--------------------------------------------------------
--  DDL for Procedure GET_RECEIVE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."GET_RECEIVE" (p_object_id in varchar2,
                                        p_quota     in number,
                                        p_out_msg   out varchar2) is
/*---------------------------------
-- Get receive
ModiyDate : 105/02/15
Desc: 	承辦人同時擁有一般新案及其他種類公文的承辦權限時，在領辦時所領公文一半的數量由一般新案中掉落（小數點進位），
如果一般新案不足則從後續文中補足，其餘領辦檢核條件不變。
例如邱俊銘領50件公文，則其中25件從一般新案中掉落，但是如果有同案全領及續領後續等因素相關公文已然會被邱俊銘領取
105/02/18: merge 10000,10002,10003,10007  into one item 

---------------------------------*/
  type receive_no_tab is table of spt21.receive_no%type;
  g_rec        number;
  g_rec_n      number;
  g_rec_a      number;
  g_difference number;
  g_difference_n number; -- the number can get : new-receive
  g_difference_a number; -- the number can get : append-receive
  g_total      number;
  g_total_n      number; -- the number has gotten : new-receive
  g_total_a      number; -- the number has gotten : append-receive
  g_maxNO      number;
  g_holdNO     number;
  g_ecode        number;
  g_reason     nvarchar2(100);
  err_code        number ;
  err_msg         varchar2(200);
  err_func        varchar2(20);
  
  CURSOR list_cursor IS 
    select distinct spt21.receive_date,  tmp.receive_no, tmp.pre_no 
    from  tmp_get_receive tmp join spt21 on  tmp.receive_no = spt21.receive_no
    where  (exists (select processor_no
                      from skill
                     where (case
                             when tmp.skill = 'INVENTION' then  INVENTION
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
        and is_get = '0'
    order by  spt21.receive_date,  tmp.pre_no,tmp.receive_no
    ;
    
    CURSOR list_cursor_p IS 
    select '' receive_date, receive_no  ,  pre_no
    from tmp_get_receive 
    where skill = p_object_id  
    and is_get = '0'
       ;
    
 procedure get_append(append_num out number)
  is
  begin
    err_func := 'get_append';
    select count(1) into append_num
    from  tmp_get_receive tmp join spt21 on  tmp.receive_no = spt21.receive_no
    where  (exists (select processor_no
                      from skill
                     where (case
                             when tmp.skill = 'INVENTION' then  INVENTION
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
            and substr(pre_no,4,1) = '3'
            and is_get = '0'
            ;
 
  
  end get_append;
  
   procedure get_new(new_num out number)
  is
  begin
    err_func := 'get_new';
      select count(1) into new_num
    from  tmp_get_receive tmp join spt21 on  tmp.receive_no = spt21.receive_no
    where  (exists (select processor_no
                      from skill
                     where (case
                             when tmp.skill = 'INVENTION' then  INVENTION
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
            and substr(pre_no,4,1) = '2'
            and is_get = '0'
            ;
 
  
  end get_new;

procedure update_receive(l_receive_date char ,l_rec_no char, l_pre_no char)
  is
    l_rec number;
    l_rec_n number;
    l_rec_a number;
  begin
        err_func := 'update_receive';
         l_rec := 0; --initial 
               
         update receive set step_code = '2', processor_no  = p_object_id, process_date = to_char(to_number(to_char(sysdate,'yyyyMMdd'))-19110000)
          where receive_no in (
                       select distinct receive_no from tmp_get_receive where pre_no = l_pre_no and is_get ='0' 
                       ) and  step_code = '0';
                       
              l_rec := SQL%ROWCOUNT; -- the real records are gotten
           --    dbms_output.put_line('l_rec='||l_rec);
              IF l_rec  > 0 THEN
                       select sum(case when substr(receive_no,4,1)='2' then '1' else '0' end) ,
                       sum(case when substr(receive_no,4,1)!='2' then '1' else '0' end)
                       into l_rec_n, l_rec_a from receive 
                        where receive_no in (
                         select distinct receive_no from tmp_get_receive where pre_no = l_pre_no and is_get ='0'                  
                         ) 
                         ;
                      --   dbms_output.put_line('l_rec_n='||l_rec_n || ',l_rec_a='|| l_rec_a);
                       ---------------------
                        -- record receive transfer history
                       ---------------------
                        INSERT INTO RECEIVE_TRANS_LOG
                        SELECT nvl((select to_number(max(receive_seq))+1 from RECEIVE_TRANS_LOG where receive_no = receive.receive_no ),'1')  seq , 
                                receive.receive_no, receive.appl_no , p_object_id,'2',sysdate,'領辦'
                                from receive
                                where receive_no in (
                                 select distinct receive_no from tmp_get_receive where pre_no = l_pre_no and is_get ='0' 
                                 ) ;
                       ---------------------------------------------
                        update spt21 set  processor_no  = p_object_id , process_result = null  where receive_no in (
                         select distinct receive_no from tmp_get_receive where pre_no = l_pre_no and is_get ='0' 
                          ) ;
                        
                        update spt31
                        set sch_processor_no= p_object_id, phy_processor_no = p_object_id
                        where appl_no in 
                        (
                            select appl_no from spt31a
                              where appl_no in
                              (
                                select appl_no from  spt21   where receive_no in (
                                    select distinct receive_no from tmp_get_receive where pre_no =  l_pre_no
                                    and is_get ='0'             )
                              )
                              and substr(appl_no,10,1) != 'N'
                              and ((step_code between '10' and '19'  and step_code != '15')
                                    or step_code = '30'
                                    or step_code = '29'
                                    or step_code = '49'
                                    or  exists (
                                        select 1 from  spt21   where receive_no in (
                                    select distinct receive_no from tmp_get_receive where pre_no =  l_pre_no
                                    and is_get ='0'             )
                                    and  type_no in ('16000','16002','22210')
                                      )
                                ))
                            ;  
                            update appl
                            set processor_no = p_object_id
                            where appl_no in 
                           (
                            select appl_no from spt31a
                              where appl_no in
                              (
                                select appl_no from  spt21   where receive_no in (
                                    select distinct receive_no from tmp_get_receive where pre_no =  l_pre_no
                                    and is_get ='0'             )
                              )
                              and substr(appl_no,10,1) != 'N'
                              and ((step_code between '10' and '19'  and step_code != '15')
                                    or step_code = '30'
                                    or step_code = '29'
                                    or step_code = '49'
                                    or  exists (
                                        select 1 from  spt21   where receive_no in (
                                    select distinct receive_no from tmp_get_receive where pre_no =  l_pre_no
                                    and is_get ='0'             )
                                    and  type_no in ('16000','16002','22210')
                                      )
                                ))
                            ;  
                          
                        update tmp_get_receive  set  is_get ='1',udate=sysdate  where pre_no = l_pre_no and is_get ='0' ;
                        
                       g_total_n := g_total_n + l_rec_n;
                       g_total_a := g_total_a + l_rec_a;
                       g_total :=  g_total_n + g_total_a ;
                       
                         dbms_output.put_line('g_total_n=' ||g_total_n||',g_total_a='|| g_total_a ||',l_rec_n='||l_rec_n ||',l_rec_a='|| l_rec_a);
                    END IF;
               commit;

end;


/*
不限要求件數,後續文全部領取
*/
procedure transfer_p
 --移轉文號
   is
   v_rec_no   char(15);
   v_pre_no   char(15);
   v_receive_date char(7);
   l_rec     number;
   l_append_num number;
  begin
    err_func := 'transfer_p';
    l_append_num :=0;
    
    OPEN list_cursor_p;
   LOOP
      FETCH list_cursor_p INTO v_receive_date,v_rec_no,v_pre_no ;
       EXIT WHEN  list_cursor_p%NOTFOUND;
       
            dbms_output.put_line('v_rec_no:' || v_rec_no || ';v_pre_no:' ||v_pre_no  );
            
                l_rec := 0;
                --- the record should be gotten
                select count(1)   into l_rec  from receive 
                where receive_no in (
                 select distinct receive_no from tmp_get_receive where pre_no = v_pre_no and is_get ='0'                  
                 ) and  step_code = '0';
                
                IF l_rec  >0 THEN
                    update_receive(v_receive_date,v_rec_no,v_pre_no);
                END IF;
      
   END LOOP;
   CLOSE list_cursor_p;
  end;
/*--------------
  判斷領取件數
----------------*/
  procedure transfer
  --移轉文號
   is
   v_rec_no   char(15);
   v_pre_no   char(15);
   v_receive_date char(7);
   l_rec     number;
   l_append_num number;
   l_new_num    number;
  begin
    err_func := 'transfer';

    
    OPEN list_cursor;
   LOOP
      FETCH list_cursor INTO v_receive_date,v_rec_no,v_pre_no ;
       EXIT WHEN  list_cursor%NOTFOUND;
       
         l_append_num :=0;
         l_new_num :=0;
         get_append(l_append_num);
         get_new(l_new_num);
         
         if l_new_num =0 and l_append_num=0 then
            EXIT;
         end if;
         
           l_rec := 0;
                --- the record should be gotten
                select count(1)   into l_rec  from receive 
                where receive_no in (
                 select distinct receive_no from tmp_get_receive where pre_no = v_pre_no and is_get ='0'                  
                 ) and  step_code = '0';
          
           dbms_output.put_line('l_append_num='||l_append_num||',l_new_num='|| l_new_num);
         
         if l_append_num = 0 then 
              --已沒有後續文可領,改領新案
              g_difference_n := g_difference_n + (g_difference_a - g_total_a);
              g_difference_a := g_total_a;
         else
             if  g_total_a >= g_difference_a and substr(v_pre_no,4,1) ='3' then
                  l_rec :=0;
             end if;
         end if;
         if l_new_num = 0 then
               g_difference_a := g_difference_a + (g_difference_n - g_total_n);
               g_difference_n := g_total_n;
         else
               if  g_total_n >= g_difference_n and substr(v_pre_no,4,1) ='2' then
                   l_rec :=0;
             end if;
         end if;
         dbms_output.put_line('g_difference_n='||g_difference_n ||',g_difference_a='||g_difference_a);
         dbms_output.put_line('v_receive_date:' || v_receive_date ||'v_rec_no:' || v_rec_no || ';v_pre_no:' ||v_pre_no  );
               
              
               
                IF l_rec  >0 THEN
                    update_receive(v_receive_date,v_rec_no,v_pre_no);
                END IF;
                
               dbms_output.put_line('g_total='||g_total|| ',g_difference='||g_difference);
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
   err_func := 'related_case2';
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
    select receive_no , pre_no ,'related_case2','MISC_AMEND','外包自動退文,和後續文一起領','0',sysdate
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
  g_total_n    := 0;
  g_total_a    := 0;
  g_rec        := 0;
  err_func := 'Main';
  
  SELECT count(1) into g_rec from receive where step_code = '0' and return_no not in ('4','A','B','C');
 
 ------------------------------------------
 -- Batch , for test
 --------------------------------------------
  -- 外包退辦重領
  related_case2;
  -- 後續文優先領取
  transfer_p;
  --取得最大領取公文數
  select pname into g_maxNO from parameter where para_no = 'MAX_REC';
  --取得目前辦理中的公文數
  select count(1) into g_holdNO from receive where processor_no = p_object_id and step_code > '0' and step_code <'8';
  
  IF g_holdNO >= g_maxNO THEN
     p_out_msg := '您的線上公文已超過最大件數:' || g_maxNO;
  ELSE
  -- 決定領取件數
    IF g_maxNO - g_holdNO < p_quota THEN
        g_difference := g_maxNO - (g_holdNO - g_total_n - g_total_a) ; -- 可領數     
    ELSE
        g_difference_n := p_quota;
    END IF;
    -- 計算新案及後續文領取件數
    g_difference_n :=  ceil(g_difference/2)-g_total_n;
    g_difference_a :=  floor(g_difference/2)-g_total_a;
    dbms_output.put_line('g_difference_n='||g_difference_n ||',g_difference_a='||g_difference_a);
    -- 領辦
    transfer;
    
     IF g_rec = 0 THEN
       p_out_msg := '無可領之線上公文';
     ELSE
        IF g_total = 0 THEN
           p_out_msg := '無權限可領';
        ELSE
          p_out_msg := '領取新案:' || g_total_n || ' 件,後續文:' || g_total_a || ' 件';
        END IF;
     END IF;
  END IF;
  
 

  dbms_output.put_line(p_out_msg);
EXCEPTION
   when others then
    rollback;
    err_code := SQLCODE;
    err_msg := SUBSTR(SQLERRM, 1, 200);
   
    raise_application_error(-20001,to_char(sysdate,'yyyyMMdd hh24:mm:ss') ||':Procedure GET_RECEIVE_NEW[' || err_func || '] error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
END GET_RECEIVE;

/
