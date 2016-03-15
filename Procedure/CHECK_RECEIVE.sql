--------------------------------------------------------
--  DDL for Procedure CHECK_RECEIVE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CHECK_RECEIVE" (is_refresh in char,p_rec  out int,p_out_msg   out varchar2) is
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
/* ----------------------------------------
 -- Modify Date: 
 105/01/26
Desc; 1.	�N�o���s�סB�s���s�סB�]�p�s�סB�έl�ͳ]�p�X�֬�1�����O�u�@��s�סv�C
      2.	���Ϋ���B�Χ�Ы��򪺱���אּ�A�ӫ���大�׸������L����/��зs�׮ץѡA�Ӯ׸��L�A�f�ӽФ�h�Ӥ嬰����/��Ы����F
          �Ӯ׸����A�f�ӽФ�p�A�f�ӽФ�P�Ӯ׭������妬���ζl�W����ۦP�A�h������/��Ы����F
          �Ӯ׸����A�f�ӽФ�p�A�f�ӽФ�P�Ӯ׭������妬���ζl�W������P�A�h���@������C
105/02/18:  merge 10000,10002,10003,10007  into one item 
105/03/03: �Ӯ׭������妬��� ��spt31.first_day
 -----------------------------------------*/

  procedure related_case1
  --  �D�i�ꤺ�u���v���s�ӽЮפ�����C�J�����ץ�
  --  �ݧP�_���
   is
  --  v_collect receive_no_tab;
  begin
    insert into tmp_get_receive
    select receive_no , receive_no ,'related_case1_1','MISC_AMEND','�D�i�ꤺ�u���v���s�ӽЮפ�����','0',sysdate
      from receive
     where exists (select appl_no
              from spt32
             where spt32.PRIORITY_NATION_ID = 'TW'
               and spt32.appl_no = receive.appl_no)
       and substr(receive.receive_no, 4, 1) = '2'
       and step_code = '0'
       and doc_complete = '1'
       and return_no not in ('4','A','B','C','D') --�h�줽��
       and not exists (select 1 from tmp_get_receive where receive_no = receive.receive_no and is_get = '0')
       ;
       l_rec_cnt := l_rec_cnt +  SQL%RowCount;
      -- �s���������
      insert into tmp_get_receive
      select receive.receive_no , n.receive_no ,'related_case1_2','MISC_AMEND','�D�i�ꤺ�u���v���s�ӽЮפ������','0',sysdate
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
   l_rec_cnt := l_rec_cnt +  SQL%RowCount;
       dbms_output.put_line(' �D�i�ꤺ�u���v���s�ӽЮפ�����C�J�����ץ��� ' || l_rec_cnt);
      commit;
    g_reason := '�D�i�ꤺ�u���v���s�ӽЮפ�����C�J�����ץ���';
  
  end related_case1;

  procedure related_case2
  --  �~�]�۰ʰh��,�M�����@�_��
  --  �ݾ�]����,�P�_����
   is
   -- v_collect receive_no_tab;
  begin
   --dbms_output.put_line('update �~�]�۰ʰh��');
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
    select receive_no , pre_no ,'related_case2','MISC_AMEND','�~�]�۰ʰh��,�M�����@�_��','0',sysdate
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
        where  not exists (select 1 from tmp_get_receive where receive_no = tmp_get_receive.receive_no and is_get = '0')
     ;
     
    l_rec_cnt := l_rec_cnt +  SQL%RowCount;
      dbms_output.put_line(' �~�]�۰ʰh��,�M�����@�_�� ' || l_rec_cnt);
    commit;
    g_reason := '�~�]�۰ʰh��,�M�����@�_��';

  end related_case2;

  procedure related_case3
  --  �h�孫�s��� 
    -- 2:�d��H���h�� 3:�D�ްh��
    -- �P�_����
    -- 9/4 ���շ|ĳ,���� 3:�D�ްh��
   is
  --  v_collect receive_no_tab;
  begin
     insert into tmp_get_receive
     select receive_no , pre_no ,'related_case3_1','MISC_AMEND','�h��-���׭��s���','0',sysdate
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
                       and  not exists (select 1 from tmp_get_receive where receive_no = a.receive_no )
                       group by appl_no
                                    ) c
                  on b.appl_no = c.appl_no and b.receive_no != c.receive_no
             where substr(b.receive_no, 4, 1) = '3'
               and b.step_code = '0'
               and b.doc_complete = '1'
               )
          where not exists (select 1 from tmp_get_receive where receive_no = tmp_get_receive.receive_no and is_get = '0')
     ;
        l_rec_cnt := l_rec_cnt +  SQL%RowCount;

     
         dbms_output.put_line(' �h���� ' || l_rec_cnt);
       commit;
    g_reason := '�h����';

  end related_case3;

  procedure related_case4
  /*
����A�M����B���P�׸�
����A�O�s��(��4�X=2)�B��ץѬ���еo���M�Q(11000),��зs���M�Q(11002),��г]�p�M�Q(11003),��Эl�ͳ]�p�M�Q(11007),��пW�߱M�Q(11010)�C
����B�������(�帹��4�X=3)
(a)�Ӯ׸��L�A�f�ӽФ�(spt31.RE_APPL_DATE)�A�h����B����Ы����C
(b) �Ӯ׸����A�f�ӽФ�,�p�A�f�ӽФ�P�Ӯ׭������妬���(spt31.FIRST_DAY)�ζl�W���(spt21.POSTMARK_DATE)�ۦP�A�h����B����Ы����C
(c) �Ӯ׸����A�f�ӽФ�p�A�f�ӽФ�P�Ӯ׭������妬���ζl�W������P�A�h����B���@������

  */
   is
  --  v_collect receive_no_tab;
  begin
    --- ����зs�ӽЪ���,�ΥѨ��зs�ӽ��v�����H����s�ӽЩM�����
    insert into tmp_get_receive
    select receive_no  , pre_no ,'related_case4_1','CONVERTING','��зs�ӽЮ�+��Ы����','0',sysdate
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
            union all  -- �������
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
             )
             where not exists (select 1 from tmp_get_receive where receive_no = tmp_get_receive.receive_no and is_get = '0')
             ;
          l_rec_cnt := l_rec_cnt +  SQL%RowCount;
             dbms_output.put_line(' ��зs�ӽЮ�+��Ы���� ' || l_rec_cnt);
        commit;
    g_reason := '��зs�ӽЮ�+��Ы����';
   
   --------------------
   -- '��Ы����'
   -------------------
       
    insert into tmp_get_receive
     select receive_no  ,( select min(receive_no) from receive where appl_no = a.appl_no and step_code='0' and doc_complete = '1' group by Receive.Appl_No )
          ,'related_case4_2',
    ( select   case when spt31.RE_APPL_DATE is null  then 'CONVERTING_AMEND' 
                    when spt31.RE_APPL_DATE is not null and ( spt31.RE_APPL_DATE  =  spt21.POSTMARK_DATE or spt31.RE_APPL_DATE   = spt31.FIRST_DAY) then 'CONVERTING_AMEND'    
                    when spt31.RE_APPL_DATE is not null and ( spt31.RE_APPL_DATE  !=  spt21.POSTMARK_DATE  or  spt31.RE_APPL_DATE != spt31.FIRST_DAY) then 'MISC_AMEND'
               else 'CONVERTING_AMEND'         end 
       from spt31 join spt21 on spt31.appl_no = spt21.appl_no
        where spt31.appl_no = a.appl_no
        and substr(spt21.receive_no,4,1) = '2' -- a.receive_no
        and spt21.type_no in ('11000', '11002', '11003', '11007', '11010')
      )
      ,  ( select   case when spt31.RE_APPL_DATE is null  then '��Ы����'     
                         when spt31.RE_APPL_DATE is not null and ( spt31.RE_APPL_DATE  =  spt21.POSTMARK_DATE or spt31.RE_APPL_DATE   = spt31.FIRST_DAY) then '��Ы����'                         
                         when spt31.RE_APPL_DATE is not null and  ( spt31.RE_APPL_DATE  !=  spt21.POSTMARK_DATE  or  spt31.RE_APPL_DATE != spt31.FIRST_DAY)  then '��Ы����-�@��'                         
                    else '��Ы����'         
                    end 
        from spt31 join spt21 on spt31.appl_no = spt21.appl_no
        where spt31.appl_no = a.appl_no
        and substr(spt21.receive_no,4,1) = '2' -- a.receive_no
        and spt21.type_no in ('11000', '11002', '11003', '11007', '11010')
      )
      ,'0',sysdate
      from receive a 
      where a.step_code = '0'
       and a.doc_complete = '1'
       and return_no not in ('4','A','B','C','D')
       and substr(a.receive_no, 4, 1) = '3'
       and exists (select ''
              from  spt21 s21 left join receive b on b.receive_no = s21.receive_no
             where s21.appl_no = a.appl_no
               and s21.receive_no < a.receive_no
               and s21.type_no in ('11000', '11002', '11003', '11007', '11010')
               and (( s21.process_result is not null and online_flg = 'N') or (s21.ONLINE_FLG='Y' and b.step_code ='8') )
              )
         and  not exists (select 1 from tmp_get_receive where receive_no = a.receive_no )
             ;
 l_rec_cnt := l_rec_cnt +  SQL%RowCount;
      g_reason := '��Ы����';
   dbms_output.put_line(' ��Ы���� ' || l_rec_cnt);
          
     commit;
      g_reason := '��зs�ӽЮפ@������';
    
  end related_case4;

  procedure related_case5
  --    ���Ϋ����
  -- ���P�_���
   is
    v_collect receive_no_tab;
  begin
  
    --- �����ηs�ӽЪ���,�ΥѨ���ηs�ӽ��v�����H����s�ӽЩM�����
    insert into tmp_get_receive
    select receive_no  , pre_no ,'related_case5_1','DIVIDING','���ηs�ӽ� + ���Ϋ����','0',sysdate
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
          )
          where not exists (select 1 from tmp_get_receive where receive_no = tmp_get_receive.receive_no and is_get = '0')
          ;
          
    g_reason := '���ηs�ӽ� + ���Ϋ����';
   l_rec_cnt := l_rec_cnt +  SQL%RowCount;
      dbms_output.put_line(' ���ηs�ӽ� + ���Ϋ���� ' || l_rec_cnt);
    commit;
  
    ---���Ϋ����
    insert into tmp_get_receive
    select a.receive_no   ,    ( select min(receive_no) from receive where appl_no = a.appl_no and step_code='0' and doc_complete = '1' group by Receive.Appl_No ) 
            ,'related_case5_2',
         ( select  case  when s31.RE_APPL_DATE is null  then 'DIVIDING_AMEND'     
                         when s31.RE_APPL_DATE is not null and (s31.RE_APPL_DATE = s21.POSTMARK_DATE or s31.RE_APPL_DATE  = s31.FIRST_DAY) then 'DIVIDING_AMEND'     
                         when s31.RE_APPL_DATE is not null and  (s31.RE_APPL_DATE != s21.POSTMARK_DATE or s31.RE_APPL_DATE  != s31.FIRST_DAY) then 'MISC_AMEND'
                    else 'DIVIDING_AMEND'         
                    end 
        from spt21 s21 
        join spt31 s31 on s21.appl_no = s31.appl_no
         where s21.appl_no = a.appl_no
        and substr(s21.receive_no,4,1) = '2'
        and s21.type_no in ('12000', '11092')
      )
      ,  ( select  case when s31.RE_APPL_DATE is null  then '���Ϋ����'     
                         when s31.RE_APPL_DATE is not null and  (s31.RE_APPL_DATE = s21.POSTMARK_DATE or s31.RE_APPL_DATE  = s31.FIRST_DAY) then '���Ϋ����'     
                         when s31.RE_APPL_DATE is not null and  (s31.RE_APPL_DATE != s21.POSTMARK_DATE or s31.RE_APPL_DATE  != s31.FIRST_DAY) then '���Ϋ����-�@��'
                    else '���Ϋ����'         
                    end 
        from spt21 s21 
        join spt31 s31 on s21.appl_no = s31.appl_no
        where s21.appl_no = a.appl_no
        and substr(s21.receive_no,4,1) = '2'
        and s21.type_no in ('12000', '11092')
      )
      ,'0',sysdate
     from receive a 
     join spt21 s21 on a.receive_no = s21.receive_no
     where a.step_code = '0'
       and a.doc_complete = '1'
       and return_no not in ('4','A','B','C','D')
       and substr(a.receive_no, 4, 1) = '3'
       and exists (select ''
              from spt21 s21  left join receive b on b.receive_no = s21.receive_no
              where s21.appl_no = a.appl_no
              and s21.receive_no < a.receive_no
              and s21.type_no in ('12000', '11092')
              and (( s21.process_result is not null and online_flg = 'N') or (s21.ONLINE_FLG='Y' and b.step_code ='8') )
              )
       and  not exists (select 1 from tmp_get_receive where receive_no = a.receive_no )
       ;
     
    g_reason := '���Ϋ����';
   l_rec_cnt := l_rec_cnt +  SQL%RowCount;
     dbms_output.put_line(' ���Ϋ���� ' || l_rec_cnt);
    commit;

  end related_case5;

  procedure related_case6
  --  ������� 
  -- ���P�_���
   is
    v_collect receive_no_tab;
  begin
              
     insert into tmp_get_receive
      select distinct a.receive_no , a.receive_no ,'related_case6',c.processor_no,'�������','0',sysdate
      from receive a 
      join ( select appl_no, processor_no from receive b
       where  b.step_code > '0' and b.step_code < '8'
       and substr(b.receive_no, 4, 1) = '3'
       ) c on a.appl_no = c.appl_no
      where a.step_code = '0'
       and a.doc_complete = '1'
       and return_no not in ('4','A','B','C','D')
       and substr(a.receive_no, 4, 1) = '3'
       and  not exists (select 1 from tmp_get_receive where receive_no = a.receive_no )
     ;
   l_rec_cnt := l_rec_cnt +  SQL%RowCount;
      dbms_output.put_line(' ������� ' || l_rec_cnt);
    commit;
    g_reason := '�������';
   
  end related_case6;

  procedure same_case1
  --  �s�שӿ�H�u������ 
  -- ���P�_���
   is
    v_collect receive_no_tab;
  begin
 
     insert into tmp_get_receive
      select a.receive_no , a.receive_no ,'same_case1',b.processor_no,'�s�שӿ�H�u������','0',sysdate
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
   l_rec_cnt := l_rec_cnt +  SQL%RowCount;
      dbms_output.put_line(' �s�שӿ�H�u������ ' || l_rec_cnt);
    commit;
    g_reason := '�s�שӿ�H�u������';
   
  end same_case1;

  procedure same_case2 is
   begin
   -- ��]��
    ---�P�ץ���
  
    insert into tmp_get_receive
     select v.receive_no, v.receive_no,'same_case2',v.skill,'�P�ץ��� ','0',sysdate
                      from VW_PULLING v
                     where substr(v.receive_no, 4, 1) = '2'
                       and v.return_no  not in ('4','A','B','C','D')
                       and not exists (select 1 from tmp_get_receive where receive_no = v.receive_no)     
                       and exists (select 1 from receive where receive.appl_no = v.appl_no and receive_no > v.receive_no)
           union all 
                       select v.receive_no, n.receive_no, 'same_case2',n.skill,'�P�ץ��� ','0',sysdate
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
    l_rec_cnt := l_rec_cnt +  SQL%RowCount;
          dbms_output.put_line(' �P�ץ��� ' || l_rec_cnt);
       commit;
   
    g_reason := '�P�ץ���';

  end same_case2;
  
  procedure common_case
  --����@����t�帹
  -- �P�_���
   is
  begin
    insert into tmp_get_receive
    select receive_no , receive_no ,'common_case',v.skill,'����@����t�帹 ','0',sysdate
      from VW_PULLING v
     where return_no <= '3'
      and not exists (select 1 from tmp_get_receive where receive_no = v.receive_no and is_get = '0')
        ;
       l_rec_cnt := l_rec_cnt +  SQL%RowCount;
        dbms_output.put_line(' ����@����t�帹 ' || l_rec_cnt);
          commit;
   
    g_reason := '����@����t�帹';

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
   
    -- �������,���γQ�����ƭ���
     related_case6;
   --�s�שӿ�H�u������ ,���γQ�����ƭ���
    same_case1;
    --   g_reason := '�D�i�ꤺ�u���v���s�ӽЮ�';
    related_case1;
 
    related_case2;
    -- �h�孫���
   related_case3;
 
   related_case4;
 
   related_case5;

 --  �P�ץ��� 
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

/
