create or replace PROCEDURE        CHECK_RECEIVE (is_refresh in char,p_rec  out int,p_out_msg   out varchar2) is
  type receive_no_tab is table of spt21.receive_no%type;
  l_rec        number;
  l_rec2       number;
  g_difference number;
  g_total      number;
  ecode        number;
  g_reason     nvarchar2(100);
  v_rec_no   char(15);
  v_pre_no   char(15);
  l_pre_no   char(15);
  l_pre_no2   char(15);
  v_receive_date char(7);
  l_rec_cnt   number;
 ----------------------------------------
 -- Modify Date: 104/08/07
 -- desc : prepare for receive-getting
 -- Get type_no from spt21
 -- add condition: return_no status
 -- add parameter is_refresh, only when is_refresh is 1 then delete the temp talbe 
 -- 7/7: update error, return_no = '0' , not  0
 -- 104/07/24 -- modify the procedure common_case : delete conditoin to judge national priority 
 -- 104/08/07 -- change conditon of "the same project getting all " 
--               add conditon  doc_complete = '1'       
 -----------------------------------------

  procedure related_case1
  --  主張國內優先權的新申請案之公文列入複雜案件
  --  需判斷件數
   is
  --  v_collect receive_no_tab;
  begin
    insert into tmp_get_receive
    select receive_no , receive_no ,'related_case1_1','MISC_AMEND','主張國內優先權的新申請案之公文','0'
      from receive
     where exists (select appl_no
              from spt32
             where spt32.PRIORITY_NATION_ID = 'TW'
               and spt32.appl_no = receive.appl_no)
       and substr(receive.receive_no, 4, 1) = '2'
       and step_code = '0'
       and doc_complete = '1'
       and return_no not in ('4','A','B','C','D')
       and not exists (select 1 from tmp_get_receive where receive_no = receive.receive_no and is_get = '0')
       ;
       l_rec_cnt := l_rec_cnt +  SQL%RowCount;
      -- 新案續領後續文
      insert into tmp_get_receive
      select receive.receive_no , n.receive_no ,'related_case1_2','MISC_AMEND','主張國內優先權的新申請案之後續文','0'
      from receive
      join  (select appl_no , receive_no
              from receive
              where exists (select 1
                            from spt32
                            where spt32.PRIORITY_NATION_ID = 'TW'
                            and spt32.appl_no = receive.appl_no)
                            and substr(receive.receive_no, 4, 1) = '2'
                            and step_code = '0'
                            and doc_complete = '1'
                            and return_no not in ('4','A','B','C','D')
      ) n
         on receive.receive_no = n.receive_no
     where substr(receive.receive_no, 4, 1) = '3'
        and step_code = '0'
        and doc_complete = '1'
        and return_no not in ('4','A','B','C','D')
        and not exists (select 1 from tmp_get_receive where receive_no = receive.receive_no and is_get = '0')
      ;
   
       dbms_output.put_line(' 主張國內優先權的新申請案之公文列入複雜案件領取 ' || l_rec_cnt);
      commit;
    g_reason := '主張國內優先權的新申請案之公文列入複雜案件領取';
  
  end related_case1;

  procedure related_case2
  --  外包自動退文,和後續文一起領
  --  需整包全領,判斷條件
   is
   -- v_collect receive_no_tab;
  begin
   --dbms_output.put_line('update 外包自動退文');
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
                       and b.doc_complete = '1'
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
                       and b.doc_complete = '1'
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
               and a.doc_complete = '1'
            union all
            Select b.receive_no , c.receive_no pre_no
              from receive b 
              join (select appl_no ,receive_no
                                   from receive a
                                  where a.return_no = '1'
                                    And a.step_code = '0'
                                    and a.doc_complete = '1'
                                    ) c
                  on b.appl_no = c.appl_no
             where substr(b.receive_no, 4, 1) = '3'
               and b.step_code = '0'
               and b.doc_complete = '1'
               )
     ;
     
    
      dbms_output.put_line(' 外包自動退文,和後續文一起領 ' || l_rec_cnt);
    commit;
    g_reason := '外包自動退文,和後續文一起領';

  end related_case2;

  procedure related_case3
  --  退文重新領辦 
    -- 2:查驗人員退辦 3:主管退辦
    -- 判斷條數
    -- 9/4 測試會議,取消 3:主管退辦
   is
  --  v_collect receive_no_tab;
  begin
     insert into tmp_get_receive
    select receive_no , pre_no ,'related_case3_1','MISC_AMEND','退文-全案重新領辦','0'
         from (Select min(a.receive_no) receive_no, min(a.receive_no) pre_no
              from receive a
             where a.return_no in ('2')
               And a.step_code = '0'
               and a.doc_complete = '1'
                and  not exists (select 1 from tmp_get_receive where receive_no = a.receive_no and is_get = '0')
               group by appl_no
            union all
            Select b.receive_no , c.receive_no pre_no
              from receive b 
              join ( Select appl_no , min(receive_no) receive_no
                    from receive a
                     where a.return_no in ('2')
                       And a.step_code = '0'
                       and a.doc_complete = '1'
                        and  not exists (select 1 from tmp_get_receive where receive_no = a.receive_no and is_get = '0')
                       group by appl_no
                                    ) c
                  on b.appl_no = c.appl_no and b.receive_no != c.receive_no
             where substr(b.receive_no, 4, 1) = '3'
               and b.step_code = '0'
               and b.doc_complete = '1'
               )
         
     ;
        l_rec_cnt := l_rec_cnt +  SQL%RowCount;

     
         dbms_output.put_line(' 退文領辦 ' || l_rec_cnt);
       commit;
    g_reason := '退文領辦';

  end related_case3;

  procedure related_case4
  --    改請後續文
  -- 新案+改請,整包領取, 不判斷件數
  -- 後續改請, 後續改請,一般: 不判斷件數
   is
  --  v_collect receive_no_tab;
  begin
    --- 有改請新申請的文,統由具改請新申請權限的人領取新申請和後續文
    insert into tmp_get_receive
    select receive_no  , pre_no ,'related_case4_1','CONVERTING','改請新申請案+改請後續文','0'
      from (select a.receive_no ,a.receive_no  pre_no
              from receive a join spt21 s21 on a.receive_no = s21.receive_no
             where a.step_code = '0'
               and a.doc_complete = '1'
               and substr(a.receive_no, 4, 1) = '2'
               and return_no not in ('4','A','B','C','D')
               and s21.type_no in
                   ('11000', '11002', '11003', '11007', '11010')
              and not exists (select 1
                            from spt32
                            where spt32.PRIORITY_NATION_ID = 'TW'
                            and spt32.appl_no = a.appl_no)
                            and substr(a.receive_no, 4, 1) = '2'
                            and step_code = '0'
                            and doc_complete = '1'
                            and return_no not in ('4','A','B','C','D')
            union all  -- 續領後續文
            select a.receive_no , c.receive_no pre_no
              from receive a join
               (select b.appl_no, b.receive_no
                      from receive b join spt21 s21 on b.receive_no = s21.receive_no
                     where b.step_code = '0'
                       and b.doc_complete = '1'
                       and return_no not in ('4','A','B','C','D')
                       and substr(b.receive_no, 4, 1) = '2'
                       and b.appl_no = b.appl_no
                       and s21.type_no in
                           ('11000', '11002', '11003', '11007', '11010')
                      and not exists (select 1
                            from spt32
                            where spt32.PRIORITY_NATION_ID = 'TW'
                            and spt32.appl_no = b.appl_no)
                            and substr(b.receive_no, 4, 1) = '2'
                            and step_code = '0'
                            and doc_complete = '1'
                            and return_no not in ('4','A','B','C','D')
              ) c   on a.appl_no = c.appl_no
             where a.step_code = '0'
               and a.doc_complete = '1'
               and return_no not in ('4','A','B','C','D')
               and substr(a.receive_no, 4, 1) = '3'
             );
          
             dbms_output.put_line(' 改請新申請案+改請後續文 ' || l_rec_cnt);
        commit;
    g_reason := '改請新申請案+改請後續文';
   
   --------------------
   -- '改請後續文'
   -------------------
       
    insert into tmp_get_receive
     select receive_no  ,( select min(receive_no) from receive where appl_no = a.appl_no and step_code='0' and doc_complete = '1' group by Receive.Appl_No )
          ,'related_case4_2',
    ( select   case when type_no  in ('13003', '21100', '24100') then 'MISC_AMEND'
          else 'CONVERTING_AMEND'         end 
        from spt21 
        where receive_no = ( select min(receive_no) from receive where appl_no = a.appl_no and step_code='0' and doc_complete = '1' group by Receive.Appl_No )
        and appl_no = a.appl_no
      )
      ,  ( select   case when spt21.type_no  in ('13003', '21100', '24100') then '改請後續文-一般'
          else '改請後續文'         end 
        from receive join spt21 on receive.receive_no = spt21.receive_no
        where receive.receive_no = ( select min(receive_no) from receive where appl_no = a.appl_no and step_code='0' and doc_complete = '1' group by Receive.Appl_No )
        and receive.appl_no = a.appl_no
      )
      ,'0'
      from receive a 
      where a.step_code = '0'
       and a.doc_complete = '1'
       and return_no not in ('4','A','B','C','D')
       and substr(a.receive_no, 4, 1) = '3'
       and exists (select 1
              from  spt21 s21 left join receive b on b.receive_no = s21.receive_no
             where s21.appl_no = a.appl_no
               and s21.type_no in
                   ('11000', '11002', '11003', '11007', '11010')
               and ( step_code = '8' or  step_code is null  ))
             ;
 
      g_reason := '改請後續文';
   dbms_output.put_line(' 改請後續文 ' || l_rec_cnt);
          
     commit;
      g_reason := '改請新申請案一般後續文';
    
  end related_case4;

  procedure related_case5
  --    分割後續文
  -- 不判斷件數
   is
    v_collect receive_no_tab;
  begin
  
    --- 有分割新申請的文,統由具分割新申請權限的人領取新申請和後續文
    insert into tmp_get_receive
    select receive_no  , pre_no ,'related_case5_1','DIVIDING','分割新申請 + 分割後續文','0'
      from (select a.receive_no ,a.receive_no pre_no
              from receive a join spt21 s21 on a.receive_no = s21.receive_no
             where a.step_code = '0'
              and a.doc_complete = '1'
              and return_no not in ('4','A','B','C','D')
               and substr(a.receive_no, 4, 1) = '2'
               and s21.type_no in ('12000', '11092')
               and not exists (select 1
                            from spt32
                            where spt32.PRIORITY_NATION_ID = 'TW'
                            and spt32.appl_no = a.appl_no)
            union all
            select a.receive_no, c.receive_no
              from receive a join
              (select b.appl_no, b.receive_no
                      from receive b join spt21 s21 on b.receive_no = s21.receive_no
                     where b.step_code = '0'
                       and b.doc_complete = '1'
                       and return_no not in ('4','A','B','C','D')
                       and substr(b.receive_no, 4, 1) = '2'
                       and s21.type_no in ('12000', '11092')
                       and not exists (select 1
                            from spt32
                            where spt32.PRIORITY_NATION_ID = 'TW'
                            and spt32.appl_no = b.appl_no)
                        ) c
                  on a.appl_no = c.appl_no
             where a.step_code = '0'
               and a.doc_complete = '1'
               and return_no not in ('4','A','B','C','D')
               and substr(a.receive_no, 4, 1) = '3'
          );
    g_reason := '分割新申請 + 分割後續文';
   
      dbms_output.put_line(' 分割新申請 + 分割後續文 ' || l_rec_cnt);
    commit;
  
    ---分割後續文
    insert into tmp_get_receive
    select a.receive_no   , ( select min(receive_no) from receive where appl_no = a.appl_no and step_code='0' and doc_complete = '1' group by Receive.Appl_No ) 
            ,'related_case5_2',
          ( select   case when s.type_no  in ('13003', '21100', '24100') then 'MISC_AMEND'
          else 'DIVIDING_AMEND'         end 
        from receive join spt21 s on receive.receive_no = s.receive_no
        where receive.receive_no = ( select min(receive_no) from receive where appl_no = a.appl_no and step_code='0' and doc_complete = '1' group by Receive.Appl_No )
        and receive.appl_no = a.appl_no
      )
      ,  ( select   case when s.type_no  in ('13003', '21100', '24100') then '分割後續文-一般'
          else '分割後續文'         end 
        from receive join spt21 s on receive.receive_no = s.receive_no
        where receive.receive_no = ( select min(receive_no) from receive where appl_no = a.appl_no and step_code='0' and doc_complete = '1' group by Receive.Appl_No )
        and receive.appl_no = a.appl_no
      )
      ,'0'
     from receive a 
     join spt21 s21 on a.receive_no = s21.receive_no
     where a.step_code = '0'
       and a.doc_complete = '1'
       and return_no not in ('4','A','B','C','D')
       and substr(a.receive_no, 4, 1) = '3'
       and exists (select 1
              from spt21 s21 left join receive b on b.receive_no = s21.receive_no
             where s21.appl_no = a.appl_no
               and ( b.step_code = '8' or b.step_code is null)
               and s21.type_no in ('12000', '11092'))
       ;
     
    g_reason := '分割後續文';
   
     dbms_output.put_line(' 分割後續文 ' || l_rec_cnt);
    commit;

  end related_case5;

  procedure related_case6
  --  續領後續文 
  -- 不判斷件數
   is
    v_collect receive_no_tab;
  begin
   
              
     insert into tmp_get_receive
      select a.receive_no , a.receive_no ,'related_case6',c.processor_no,'續領後續文','0'
      from receive a 
      join ( select appl_no, processor_no from receive b
       where  b.step_code > '0' and b.step_code < '8'
       and substr(b.receive_no, 4, 1) = '3'
       ) c on a.appl_no = c.appl_no
      where a.step_code = '0'
       and a.doc_complete = '1'
       and return_no not in ('4','A','B','C','D')
       and substr(a.receive_no, 4, 1) = '3'
     ;
   
      dbms_output.put_line(' 續領後續文 ' || l_rec_cnt);
    commit;
    g_reason := '續領後續文';
   
  end related_case6;

  procedure same_case1
  --  新案承辦人優先全領 
  -- 不判斷件數
   is
    v_collect receive_no_tab;
  begin
 
     insert into tmp_get_receive
      select a.receive_no , a.receive_no ,'same_case1',b.processor_no,'新案承辦人優先全領','0'
      from receive a
      join receive b
        on a.appl_no = b.appl_no
     where substr(b.receive_no, 4, 1) = '2'
       and b.step_code = '2'
       and a.step_code = '0'
       and a.doc_complete = '1'
       and a.return_no not in ('4','A','B','C','D')
       and a.receive_no > b.receive_no
       and not exists (select 1 from tmp_get_receive where receive_no = a.receive_no and is_get='0')
    ;
   
      dbms_output.put_line(' 新案承辦人優先全領 ' || l_rec_cnt);
    commit;
    g_reason := '新案承辦人優先全領';
   
  end same_case1;

  procedure same_case2 is
   begin
   -- 整包領
    ---同案全領
  
    insert into tmp_get_receive
     select v.receive_no, v.receive_no,'same_case2',v.skill,'同案全領 ','0'
                      from VW_PULLING v
                     where substr(v.receive_no, 4, 1) = '2'
                       and v.return_no  not in ('4','A','B','C','D')
                       and not exists (select 1 from tmp_get_receive where receive_no = v.receive_no)     
                       and exists (select 1 from receive where receive.appl_no = v.appl_no and receive_no > v.receive_no)
           union all 
                       select v.receive_no, n.receive_no, 'same_case2',n.skill,'同案全領 ','0'
                      from VW_PULLING v 
                      join (
                      select v.appl_no, v.receive_no, v.skill
                      from VW_PULLING v
                     where substr(v.receive_no, 4, 1) = '2'
                       and v.return_no  not in ('4','A','B','C','D')
                       and not exists (select 1 from tmp_get_receive where receive_no = v.receive_no)
                      ) n on v.appl_no = n.appl_no
                     where substr(v.receive_no, 4, 1) = '3'
                       and v.return_no  not in ('4','A','B','C','D')
                      and not exists (select 1 from tmp_get_receive where receive_no = v.receive_no and is_get = '0')
            ;
    
          dbms_output.put_line(' 同案全領 ' || l_rec_cnt);
       commit;
   
    g_reason := '同案全領';

  end same_case2;
  
  procedure common_case
  --領取一般分配文號
  -- 判斷件數
   is
  begin
    insert into tmp_get_receive
    select receive_no , receive_no ,'common_case',v.skill,'領取一般分配文號 ','0'
      from VW_PULLING v
     where return_no <= '3'
      and not exists (select 1 from tmp_get_receive where receive_no = v.receive_no and is_get = '0')
        ;
       
        dbms_output.put_line(' 領取一般分配文號 ' || l_rec_cnt);
          commit;
   
    g_reason := '領取一般分配文號';

  end common_case;

begin
   g_total      := 0;
   l_rec_cnt    := 0;

  SELECT count(1) into l_rec from receive where step_code = '0' and doc_complete = '1';
--------------------------------
 --  is_refresh  default = 1
--------------------------------
 if trim(nvl(is_refresh,'1')) = '1' then
   delete  tmp_get_receive;
end if ;
   
    -- 續領後續文,不用被領取件數限制
     related_case6;
   --新案承辦人優先全領 ,不用被領取件數限制
    same_case1;
    --   g_reason := '主張國內優先權的新申請案';
    related_case1;
 
    related_case2;
    -- 退文重領辦
   related_case3;
 

    related_case4;
 
    related_case5;

 



 --  同案全領 
  same_case2;

  common_case;
  commit;
  select count(1) into p_rec from tmp_get_receive;

  dbms_output.put_line(p_rec);
EXCEPTION
  WHEN OTHERS THEN
    ecode     := SQLCODE;
    p_out_msg := SQLCODE || ' : ' || SQLERRM;
    dbms_output.put_line('Error Code:' || ecode || '; Error Message:' ||
                         p_out_msg);
END CHECK_RECEIVE;