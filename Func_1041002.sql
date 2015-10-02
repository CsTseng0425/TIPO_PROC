--------------------------------------------------------
--  已建立檔案 - 星期五-十月-02-2015   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Function ADD_TWDATE_MONTHS
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."ADD_TWDATE_MONTHS" (
  p_twdate in char,
  p_add_month in number
) 
return char 
is
  v_src_twdate char(7) := trim(p_twdate);
  v_twyear     char(3);
  v_month      char(3);
  v_day        char(3);
  v_tmp_ym     char(6);
  v_tmp_date   date;
begin
  if valid_tw_date(v_src_twdate) and p_add_month >= 0 then
    v_twyear := substr(v_src_twdate, 1, 3);
    v_month := substr(v_src_twdate, 4, 2);
    v_day := substr(v_src_twdate, 6, 2);
    v_tmp_ym := to_char(add_months(to_date((v_twyear || v_month) + 191100, 'yyyymm'), p_add_month), 'yyyymm');
    begin
      v_tmp_date := to_date(v_tmp_ym || v_day, 'yyyymmdd');
      return lpad(v_tmp_ym || v_day - '19110000', 7, '0');
    exception
      when others then
        return lpad((to_char(add_months(to_date((v_twyear || v_month) + 191100, 'yyyymm'), p_add_month + 1), 'yyyymm') || '01') - '19110000', 7, '0');
    end;
  end if;
  return '';
end add_twdate_months;

/
--------------------------------------------------------
--  DDL for Function ADD_WORKDAYS
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."ADD_WORKDAYS" (p_date_bc in timestamp, p_days in number) 
return timestamp
is
v_date_bc    ap.SPMFF.date_bc%type;
v_date       char(8);
v_date_2     char(8);
begin
  v_date:=to_char(p_date_bc,'YYYYMMDD');
  if (p_days>0) then
    v_date_2:=to_char(p_date_bc+ceil(1.5*p_days+10),'YYYYMMDD');
    select DATE_BC into v_date_bc
    from (
      select DATE_BC,row_number() over (order by DATE_BC ) as rn  
      from ap.SPMFF
      where DATE_BC<v_date_2 
      and DATE_BC>v_date and DATE_FLAG='1')
    where rn=p_days;
  else
    if (p_days<0) then
      v_date_2:=to_char(p_date_bc-ceil(-1.5*p_days+10),'YYYYMMDD');
      select DATE_BC into v_date_bc
      from (
        select DATE_BC,row_number() over (order by DATE_BC desc ) as rn  
        from ap.SPMFF 
        where DATE_BC>v_date_2
        and DATE_BC<v_date and DATE_FLAG='1')
      where -rn=p_days;
    end if;       
  end if;
  
  if(v_date_bc is not null) then
    return to_date(v_date_bc,'YYYYMMDD');
  else
    return null;
  end if;
end add_workdays;

/
--------------------------------------------------------
--  DDL for Function BATCH_CHECK_STEP
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."BATCH_CHECK_STEP" (p_batch_no in varchar2)
  return char is

  l_step_code char(1);
  v_step_code char(1);
begin
  
    select step_code into v_step_code 
    from batch 
    where batch_no = p_batch_no
    and batch_seq = (select max(batch_seq) from batch where batch_no = p_batch_no)
    ;
 
     select step_code into l_step_code 
     from
     (
       select batch.batch_no , '3' step_code
        from batch_detail 
        join batch on batch.batch_no = batch_detail.batch_no and batch.batch_seq = batch_detail.batch_seq
        join spm56 on spm56.receive_no = batch_detail.receive_no 
        join ap.sptd02 sd02 on sd02.form_file_a = spm56.form_file_a
        where batch.batch_seq  = (select max(batch_seq) from batch where batch_no = batch_detail.batch_no)
     --   and batch.step_code = '1'
        and batch.process_result = '1' -- pass
        and is_rejected='0'
        and spm56.form_file_a = (select max(form_file_a) from spm56 s56 where s56.receive_no = spm56.receive_no and s56.issue_flag = '1')
        and batch.batch_no = p_batch_no
        group by batch.batch_no
        having  sum(case when sd02.flow_step != '04' then 1 else 0 end )=0
        union all
        select batch.batch_no , '4' step_code -- 判發中
        from batch_detail 
        join batch on batch.batch_no = batch_detail.batch_no and batch.batch_seq = batch_detail.batch_seq
        join spm56 on spm56.receive_no = batch_detail.receive_no 
        join ap.sptd02 sd02 on sd02.form_file_a = spm56.form_file_a
        where batch.batch_seq  = (select max(batch_seq) from batch where batch_no = batch_detail.batch_no)
     --   and batch.step_code = '1'
        and batch.process_result = '1' -- pass
        and is_rejected='0'
        and spm56.form_file_a = (select max(form_file_a) from spm56 s56 where s56.receive_no = spm56.receive_no and s56.issue_flag = '1')
        and batch.batch_no = p_batch_no
        group by batch.batch_no
        having  sum(case when sd02.flow_step != '04' then 1 else 0 end )>0
        union all 
         select batch.batch_no ,'2' step_code 
          from batch_detail 
          join batch on batch.batch_no = batch_detail.batch_no and batch.batch_seq = batch_detail.batch_seq
          join spm56 on spm56.receive_no = batch_detail.receive_no 
          join ap.sptd02 sd02 on sd02.form_file_a = spm56.form_file_a
          where batch.batch_seq  = (select max(batch_seq) from batch where batch_no = batch_detail.batch_no)
        --  and batch.step_code = '1'
          and batch.process_result in ('2','3') -- fail
          and is_rejected='0'
          and spm56.form_file_a = (select max(form_file_a) from spm56 s56 where s56.receive_no = spm56.receive_no and s56.issue_flag = '1')
          and batch.batch_no = p_batch_no
          group by batch.batch_no
          having sum(case when sd02.flow_step != '01' then 1 else 0 end )=0 --
           union all 
         select batch.batch_no ,'5' step_code  -- 退辦中
          from batch_detail 
          join batch on batch.batch_no = batch_detail.batch_no and batch.batch_seq = batch_detail.batch_seq
          join spm56 on spm56.receive_no = batch_detail.receive_no 
          join ap.sptd02 sd02 on sd02.form_file_a = spm56.form_file_a
          where batch.batch_seq  = (select max(batch_seq) from batch where batch_no = batch_detail.batch_no)
        --  and batch.step_code = '1'
          and batch.process_result in ('2','3') -- fail
          and is_rejected='0'
          and spm56.form_file_a = (select max(form_file_a) from spm56 s56 where s56.receive_no = spm56.receive_no and s56.issue_flag = '1')
          and batch.batch_no = p_batch_no
          group by batch.batch_no
          having sum(case when sd02.flow_step != '01' then 1 else 0 end )>0 --
             union all 
         select batch.batch_no ,'1' step_code  -- 待驗
          from batch_detail 
          join batch on batch.batch_no = batch_detail.batch_no and batch.batch_seq = batch_detail.batch_seq
          join spm56 on spm56.receive_no = batch_detail.receive_no 
          join ap.sptd02 sd02 on sd02.form_file_a = spm56.form_file_a
          where batch.batch_seq  = (select max(batch_seq) from batch where batch_no = batch_detail.batch_no)
          and is_rejected='0'
          and spm56.form_file_a = (select max(form_file_a) from spm56 s56 where s56.receive_no = spm56.receive_no and s56.issue_flag = '1')
          and batch.batch_no = p_batch_no
          group by batch.batch_no
          having sum(case when sd02.flow_step != '02' then 1 else 0 end )=0 --
          )
          ;
          
          return nvl(l_step_code,v_step_code);
exception
  when others then
    return v_step_code;
end BATCH_CHECK_STEP;

/
--------------------------------------------------------
--  DDL for Function BATCH_FORMLIST
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."BATCH_FORMLIST" (p_batch_no in varchar2, p_batch_seq in number)
  return varchar2 is
  l_receive_no varchar2(2000);
  v_receive_no varchar2(12);
  CURSOR batch_cursor IS
      select bd.receive_no 
     from batch_detail bd
      join spm56 on bd.receive_no = spm56.receive_no 
      where  bd.batch_no =  p_batch_no
     and bd.batch_seq = p_batch_seq
     and spm56.issue_flag != '2'
     and spm56.form_file_a = (select max(form_file_a) from spm56 s56 where s56.receive_no = spm56.receive_no)
    union all 
      select bd.receive_no 
     from batch_detail bd
     where  bd.batch_no =  p_batch_no
     and bd.batch_seq = p_batch_seq
     and not exists (select 1 from spm56 where  bd.receive_no = spm56.receive_no )
    ;
begin
/*
Desc: check if there are forms exist in spm56 for receives in batch_no
return recive list  which hasn't form or form issue_flag != '1' --發文

*/

  OPEN batch_cursor;
  LOOP
    FETCH batch_cursor
      INTO v_receive_no;
    EXIT WHEN batch_cursor%NOTFOUND;
    l_receive_no := l_receive_no || v_receive_no || ';';
   -- SYS.Dbms_Output.Put_Line('l_receive_no='||l_receive_no);
  END LOOP;
  CLOSE batch_cursor;
  SYS.Dbms_Output.Put_Line('l_receive_no='||l_receive_no);
   if length(l_receive_no)> 0 then
        return substr(l_receive_no,1,600) || ' ...etc 公文未送核';
   else 
        return '';
   end if;
exception
  when others then
    return '';
end batch_FormList;

/
--------------------------------------------------------
--  DDL for Function BATCH_HAS_APPEND
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."BATCH_HAS_APPEND" (p_appl_no in char)
  return varchar2 is

  v_count number;
begin
     /*
      Modifydate: 2015/05/15
      Desc: judge whither has post receive
     */
     
  select  count(1)
    into v_count
    from batch_detail bd
  where (bd.appl_no) = p_appl_no
  and  Bd.Is_Rejected = '0'
  and bd.batch_seq = (select max(batch_seq) from batch_detail where batch_detail.batch_no = bd.batch_no)
  and exists
    (select 1 from spt21 left join receive on receive.receive_no = spt21.receive_no
                                    where spt21.appl_no =  bd.appl_no and spt21.receive_no > bd.receive_no
                                    and ( (receive.step_code in ('0','2') and merge_master is null) or (receive.step_code is null and spt21.file_d_flag is null))
                                    and spt21.type_no not in ('22304', '22322', '24700', '24702', '22312', '22314')
                                    )
    ;
 dbms_output.put_line(v_count);
  if v_count > 0 then
    return '1';
  else
    return '0';
  end if;

end batch_has_append;

/
--------------------------------------------------------
--  DDL for Function BATCH_MEMO
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."BATCH_MEMO" (p_batch_no in varchar2,p_batch_seq in varchar2)
  return varchar2 is
  v_batch_memo varchar2(200);
  l_batch_memo varchar2(200);
  CURSOR batch_cursor IS
    select '第' || appl_no || '號已於' || CHECK_DATE || '再次查驗合格'
      from batch 
      left join  batch_detail on batch.batch_no = batch_detail.batch_no
     where batch.batch_no = p_batch_no
     and batch.batch_seq = p_batch_seq 
     and batch_detail.batch_seq = p_batch_seq-1
     and batch_detail.IS_DEFECT = '1'
     order by appl_no;
begin

  OPEN batch_cursor;
  LOOP
    FETCH batch_cursor
      INTO v_batch_memo;
    EXIT WHEN batch_cursor%NOTFOUND;
    l_batch_memo := l_batch_memo || v_batch_memo || chr(13) ||
                      chr(10);
  
  END LOOP;
  CLOSE batch_cursor;
  SYS.Dbms_Output.Put_Line(l_batch_memo);
  return l_batch_memo;
exception
  when others then
    return '';
end batch_memo;

/
--------------------------------------------------------
--  DDL for Function BATCH_MEMO_MONTHLY
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."BATCH_MEMO_MONTHLY" (p_in_processor_no in char,
                                                    p_batch_seq in varchar2,
                                                    p_in_start        in varchar2,
                                                    p_in_end          in varchar2)
  return varchar2 is
  v_batch_memo varchar2(200);
  l_batch_memo varchar2(200);
  CURSOR batch_cursor IS
    select '第' || appl_no || '號已於' || CHECK_DATE || '再次查驗合格'
      from batch B
      left join  batch_detail on B.batch_no = batch_detail.batch_no
     WHERE B.PROCESS_RESULT <> '0'
       AND B.BATCH_SEQ = p_batch_seq
       AND B.OUTSOURCING = p_in_processor_no
       AND B.PROCESS_DATE BETWEEN p_in_start AND p_in_end
       and batch_detail.batch_seq = B.BATCH_SEQ-1
       and batch_detail.IS_DEFECT = '1'
     order by appl_no;
begin

  OPEN batch_cursor;
  LOOP
    FETCH batch_cursor
      INTO v_batch_memo;
    EXIT WHEN batch_cursor%NOTFOUND;
    l_batch_memo := l_batch_memo || v_batch_memo || chr(13) ||
                      chr(10);
  
  END LOOP;
  CLOSE batch_cursor;
  SYS.Dbms_Output.Put_Line(l_batch_memo);
  return l_batch_memo;
exception
  when others then
    return '';
end batch_memo_monthly;

/
--------------------------------------------------------
--  DDL for Function BATCH_STATUS
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."BATCH_STATUS" (p_batch_no in varchar2)
  return varchar2 is
  v_batch_status varchar2(200);
  l_batch_status varchar2(200);
  CURSOR batch_cursor IS
    select batch_seq || ' ' || process_date || case
             when check_date is null then
              ''
             else
              '/' || check_date || '/' || case
                when process_result = 1 then
                 '通過'
                when process_result = 2 then
                 '允收'
                when process_result = 3 then
                 '拒收'
              end
           end
      from batch
     where batch_no = p_batch_no
     order by batch_seq;
begin

  OPEN batch_cursor;
  LOOP
    FETCH batch_cursor
      INTO v_batch_status;
    EXIT WHEN batch_cursor%NOTFOUND;
    l_batch_status := l_batch_status || v_batch_status || chr(13) ||
                      chr(10);
  
  END LOOP;
  CLOSE batch_cursor;
  return l_batch_status;
exception
  when others then
    return '';
end batch_status;

/
--------------------------------------------------------
--  DDL for Function CASE_VALID_CONVERT
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."CASE_VALID_CONVERT" (p_in_receive_no   in char,
                                              p_in_processor_no in char)
  return varchar2 is
  v_count number;
begin
/*
 Desc : check the receive is valid
 ModifyDate: 104/09/2
 104/07/31: change condition if the receive has accepted
*/

  SELECT COUNT(1)
    INTO v_count
    FROM SPT21
   WHERE SPT21.OBJECT_ID = p_in_processor_no
     AND SPT21.RECEIVE_NO = p_in_receive_no;

  if v_count > 0 then
    --是持有人
     SELECT COUNT(1)
      INTO v_count
      FROM  SPT23 
     WHERE SPT23.OBJECT_TO = p_in_processor_no
       AND SPT23.RECEIVE_NO =  p_in_receive_no
       AND data_seq = (select max(data_seq) from spt23 s23 where spt23.receive_no = s23.receive_no)  
       AND SPT23.ACCEPT_DATE IS NULL
       AND SPT23.OBJECT_TO !=  '98888'
       ;
     
  
    if v_count > 0 then
      return '文未簽收';
    end if;
  
  else
    --不是持有人
    SELECT COUNT(1)
      INTO v_count
      FROM  SPT72
     WHERE SPT72.trans_seq = (select max(trans_seq) from spt72 s72 where s72.appl_no = SPT72.appl_no)
       AND SPT72.ACCEPT_DATE IS NULL
       AND SPT72.OBJECT_TO =  p_in_processor_no
       AND SPT72.APPL_NO = (select appl_no from spt21 where receive_no =   p_in_receive_no
       )
       ;
  
    if v_count > 0 then
      return '卷未簽收';
    end if;
  
   
  end if;

  SELECT COUNT(1)
    INTO v_count
    FROM SPT21
   WHERE RECEIVE_NO = p_in_receive_no
     AND PROCESS_RESULT IS NOT NULL;

  if v_count > 0 then
    return '文已辦結';
  end if;

  return '';
end case_valid_convert;

/
--------------------------------------------------------
--  DDL for Function CASE_VALID_PROCESS
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."CASE_VALID_PROCESS" (p_no in char)
return number
is
  v_state         number  := 1;
  v_is_receive_no boolean := false;
  v_is_appl_no    boolean := false;
  v_appl_no       char(15);
  v_sc_flag       spt31.sc_flag%type;
  v_count         number;
begin
  if v_state = 1 then
    begin
      select appl_no
        into v_appl_no
        from spt21
       where receive_no = p_no;
      v_is_receive_no := true;
      v_state := 0;
    exception
      when no_data_found then null;
    end;
  end if;
  if v_state = 1 then
    begin
      select appl_no
        into v_appl_no
        from spt31
       where appl_no = p_no;
      v_is_appl_no := true;
      v_state := 0;
    exception
      when no_data_found then null;
    end;
  end if;
  if v_state = 0 then
    select sc_flag
      into v_sc_flag
      from spt31
     where appl_no = v_appl_no;
    if v_sc_flag = 1 then
      v_state := 2;
    end if;
  end if;
  if v_state = 0 and v_is_appl_no then
    select count(1)
      into v_count
      from spt21 
     where appl_no = v_appl_no
       and process_result is null;
    if v_count > 0 then
      v_state := 3;
    end if;
  end if;
  
  return v_state;
end case_valid_process;

/
--------------------------------------------------------
--  DDL for Function CHECK_APPL_PROCESSOR
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."CHECK_APPL_PROCESSOR" (p_appl_no in char,p_processor_no in char)
return number
is
  v_count number;
begin
/*
  Desc: check if having right to operate the project 
  ModifyDate: 104/07/23
  
*/
 
  select count(1) into v_count
  from 
   (
      select processor_no from spt21 where appl_no = p_appl_no and processor_no = p_processor_no
      union all
      select processor_no from appl where appl_no = p_appl_no and processor_no = p_processor_no
    )
    ;
    if v_count > 0 then 
        return 1;
    else
        return 0;
    end if;
exception
  when others then
    return 0;
end CHECK_APPL_PROCESSOR;

/
--------------------------------------------------------
--  DDL for Function CHECK_MANAGER
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."CHECK_MANAGER" (p_dept_no in char,p_processor_no in char)
return char
is
  l_mgr number;
begin
/*
  Desc: check department manager
  ModifyDate: 104/08/19
  
*/
 
  select checker into l_mgr from ap.spm72 where processor_no = p_processor_no and dept_no = p_dept_no;
  
 -- if l_mgr is null then
--      select processor_no from ap.spm6g1 where dept_no = '70012' and primary_flag = '1';
 -- end if;

  if l_mgr is null then
     select processor_no  into l_mgr from spm63 where dept_no = '70012' and title = '科長' and rownum =1;
   end if;
   
   return l_mgr;
exception
  when others then
    return 0;
end CHECK_MANAGER;

/
--------------------------------------------------------
--  DDL for Function GET_AFTER_RECEIVES
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."GET_AFTER_RECEIVES" (
  p_receive_no in char)
return after_receive_tab
is
  v_after_receive_tab after_receive_tab;
begin
/*
Desc: get after receives list 
Last ModifyDate : 104/07/21
ModifyItem:
104/07/21 : list these receive  which  not limit the after the master reiceve , list those have in the same appl
104/07/24: change type_no to type_no || type_name
*/
  select after_receive_obj(
           receive_no,
           processor_no,
           processor_name,
           type_no,
           type_name,
           step_code,
           merge_master
         )
    bulk collect
    into v_after_receive_tab
    from (
      select spt21.receive_no,
             spt21.processor_no,
             (select spm63.name_c from spm63 where spm63.processor_no = spt21.processor_no) as processor_name,
             spt21.type_no,
             (select type_name from spm75 where spm75.type_no = spt21.type_no) as type_name,
             case when  receive.step_code in ('2','3') then   '2'  else  receive.step_code end step_code,
            --receive.step_code ,
             receive.merge_master
        from spt21
        left join receive on spt21.receive_no = receive.receive_no
       where spt21.receive_no != p_receive_no
         and spt21.appl_no = (select appl_no from receive where receive_no = p_receive_no)
         and (( receive.step_code in ('0', '2','3')  )
              or
             (receive.step_code is null and spt21.process_result is null)
               or receive.merge_master is not null
             )
        --  and  receive.merge_master is  null
         and spt21.type_no not in ('22304', '22322', '24700', '24702', '22312', '22314')
       order by receive_no
    );
  return v_after_receive_tab;
end get_after_receives;

/
--------------------------------------------------------
--  DDL for Function GET_PRE_DATE
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."GET_PRE_DATE" (p_appl_no in varchar2)
return varchar2
is
  v_pre_data varchar2(7):=null;
  v_tmp_date date:=null;
begin
  
  select pre_date into v_pre_data from spt31b where trim(appl_no)= trim(p_appl_no) and pre_date is not null;
  if(v_pre_data is not null) then 
    DBMS_OUTPUT.PUT_LINE('appl_no='||p_appl_no||' v_pre_data='||v_pre_data);
    return v_pre_data; 
  end if;
  
  select greatest(least(nvl(appl_date,priority_date),nvl(priority_date,appl_date))+1,MIN_DATE) into v_tmp_date
  from(
  select VCHAR_TO_DATE(spt31.appl_date) appl_date,VCHAR_TO_DATE(spt32.priority_date) priority_date,to_date('20010726','yyyymmdd') MIN_DATE
  from spt31
  left join spt32 on spt31.appl_no=spt32.appl_no and (priority_flag='1' or trim(priority_flag) is null)
  where trim(spt31.appl_no)=trim(p_appl_no)
  )
  ;
  
  if(v_tmp_date is null) then
    return null;
  end if;
  
  v_pre_data:=TO_CHAR(TO_NUMBER(TO_CHAR(v_tmp_date,'YYYYMMDD')) - 19110000,'0000000');
  DBMS_OUTPUT.PUT_LINE('appl_no='||p_appl_no||' v_tmp_date='||v_pre_data);
  return v_pre_data; 

exception
  when others then
    return null;
end GET_PRE_DATE;

/
--------------------------------------------------------
--  DDL for Function GET_PROCESS_PRE_SAVE_MESSAGE
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."GET_PROCESS_PRE_SAVE_MESSAGE" (
  p_appl_no in char,
  p_process_result in char
)
return varchar2_tab 
is
  v_result varchar2_tab := varchar2_tab();
  v_tw_sysdate char(7)  := to_char(sysdate, 'yyyymmdd') - 19110000;
  
  procedure add_message(p_message in varchar2)
  is
  begin
    v_result.extend;
    v_result(v_result.last) := p_message;
  end add_message;
  
begin
 
  if p_process_result in (
      '49213', '43191', '43199', '43001', '49243', '43003', '43007', '43011', '43009', '43015',
      '49215', '49217', '49201', '49203', '49205', '41001', '41003', '41005', '41007', '41011',
      '41025', '41027', '41505', '41515') then
    declare
      v_tmp_num number;
    begin
      select count(1)
        into v_tmp_num
        from spm11
       where id_type = '1'
         and appl_no = p_appl_no
         and (trim(name_c) like '%行'
              or trim(name_c) like '%社'
              or trim(name_c) like '%號'
              or trim(name_c) like '%商'
              or trim(name_c) like '%工廠'
              or trim(name_c) like '%分公司'
              or trim(name_c) like '%事務所'
              or trim(name_c) like '%分校');
      if v_tmp_num > 0 then
        add_message('請確認申請人是否適格');
      end if;
    end;
  end if;
  if p_process_result in ('41505', '43007')
    and substr(p_appl_no, 10, 1) = 'N' then
    declare
      v_charge_expir_date spmf1.charge_expir_date%type;
    begin
      select charge_expir_date
        into v_charge_expir_date
        from spmf1
       where appl_no like substr(p_appl_no, 1, 9) || '%'
         and revoke_flag != '1';
      if v_tw_sysdate > v_charge_expir_date then
        add_message('年費有效期限逾期');
      end if;
    exception
      when no_data_found then add_message('無年費資訊');
    end;
    end if;
  return v_result;
end get_process_pre_save_message;

/
--------------------------------------------------------
--  DDL for Function GET_RELATION_APPL_NO
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."GET_RELATION_APPL_NO" (p_appl_no in char)
return varchar2_tab 
is
  v_relation_appl_no_tab varchar2_tab;
begin
/*
  Last Modify Date: 104/09/18
  Desc: Object Browser- relative application list
  104/09/10: 改請母案 取消只查發 明
  104/09/18: 衍生案母案
*/
 select trim(c.appl_no)
   bulk collect
    into v_relation_appl_no_tab
   from (
   select a.appl_no
   from 
   (
      select distinct a.priority_appl_no as appl_no--國內優先權前案
        from spt32 a
       where a.appl_no = p_appl_no
         and a.priority_nation_id = 'TW'
         and length(trim(a.priority_appl_no)) in (9, 12)
       union
      select distinct appl_no as appl_no--國內優先權子案
        from spt32 a
       where a.priority_appl_no = p_appl_no
         and a.priority_nation_id = 'TW'
       union 
      select a.appl_no as appl_no--舉發相關
        from spt31 a
       where a.appl_no like substr(trim(p_appl_no),1,9) || '%'
         and length(trim(a.appl_no)) > 9
       union
      select distinct a.dep_appl_no as appl_no--改請母案
        from spt31 a, spt21 b
       where a.dep_appl_no is not null 
         and a.appl_no = b.appl_no
         and b.appl_no = p_appl_no
       --  and substr(b.appl_no, 4, 1) = '1' 
         and b.type_no in ('11000', '11002', '11003', '11007', '11010')
       union
      select distinct b.appl_no as appl_no--改請子案
        from spt31 a, spt21 b 
       where a.dep_appl_no = p_appl_no
         and a.appl_no = b.appl_no
         and b.type_no in ('11000', '11002', '11003', '11007', '11010')
       union
      select distinct a.dep_appl_no as appl_no--分割母案
        from spt31 a, spt21 b
       where a.dep_appl_no is not null
         and a.appl_no = b.appl_no
         and b.appl_no = p_appl_no
         and b.type_no in ('12000', '11092')
       union
      select distinct b.appl_no as appl_no--分割子案
        from spt31 a, spt21 b
       where a.dep_appl_no = p_appl_no
         and a.appl_no = b.appl_no
         and b.type_no in ('12000', '11092')
      union 
      select appl_no  as appl_no--母案
      from spt31 
      where substr(p_appl_no,10,1) in ('D','N')
       and trim(appl_no) = substr(p_appl_no,1,9)
    )a, spt31 b
   where trim(a.appl_no) != trim(p_appl_no)
     and b.appl_no = rpad(a.appl_no, 15, ' ')
     and b.sc_flag = '0'
       order by a.appl_no
       ) c
   group by c.appl_no;
  return v_relation_appl_no_tab;
end get_relation_appl_no;

/
--------------------------------------------------------
--  DDL for Function GET_REVISE_OPTIONS
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."GET_REVISE_OPTIONS" (
  p_appl_no in spt31.appl_no%type, 
  p_online_flg in spt21.online_flg%type)
return varchar2_tab 
is
  v_options    varchar2_tab;
  v_online_flg spt21.online_flg%type;
begin
  if upper(p_online_flg) = 'Y' then
    select b.pname 
      bulk collect
      into v_options
      from appl_para a, parameter b 
     where a.para_no = b.para_no 
       and a.sys = 'PRE_EXAM' 
       and a.subsys = substr(p_appl_no, 4, 1)
     order by a.seq;
  else
    select b.pname 
      bulk collect
      into v_options
      from appl_para a, parameter b 
     where a.para_no = b.para_no 
       and a.sys = 'OLD_EXAM' 
       and a.subsys = '1'
     order by a.seq;
  end if;
  return v_options;
exception
  when no_data_found then
    return varchar2_tab();
end get_revise_options;

/
--------------------------------------------------------
--  DDL for Function HAS_APPEND
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."HAS_APPEND" (p_receive_no in char)
  return varchar2 is

  v_count number;
begin
     /*
      Modifydate: 2015/06/04
      Desc: judge whither has post receive
      para: return 1 : 有後續文,未領辦
            return 2 : 有後續文,已領辦
     */
  v_count := 0;
     

     select count(1)
      into v_count
      from spt21 left join receive 
        on receive.receive_no = spt21.receive_no
     where spt21.receive_no > p_receive_no
       and spt21.appl_no = (select appl_no from receive where receive_no = p_receive_no)
       and ((receive.step_code in ('0') and merge_master is null) or (receive.step_code is null and spt21.process_result is null))
       and spt21.type_no not in ('22304', '22322', '24700', '24702', '22312', '22314');
    
   if v_count > 0 then 
     return '1';
   end if ;
    
    v_count := 0;
     select  count(1)
    into v_count
    from receive  join spt21 on receive.receive_no = spt21.receive_no
   where receive.receive_no > p_receive_no
   and spt21.appl_no = (select appl_no from receive where receive_no = p_receive_no)
   and receive.step_code = '2'
   and merge_master is null
   and receive.processor_no = ( select processor_no from receive r where receive_no = p_receive_no)
   and type_no not in ('22304', '22322', '24700', '24702', '22312', '22314')
    ;
    
    if v_count > 0 then 
     return '2';
    end if ;
    
 dbms_output.put_line(v_count);
    
    return '0';

end HAS_APPEND;

/
--------------------------------------------------------
--  DDL for Function SPOT_CHECK_QTY
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."SPOT_CHECK_QTY" (p_all in number) return number is

begin

  case
    when p_all between 2 and 8 then
      return 2;
    when p_all between 9 and 15 then
      return 3;
    when p_all between 16 and 25 then
      return 5;
    when p_all between 26 and 50 then
      return 8;
    when p_all between 51 and 90 then
      return 13;
    when p_all between 91 and 150 then
      return 20;
    when p_all between 151 and 280 then
      return 32;
    else
      return 50;
  end case;

end SPOT_CHECK_QTY;

/
--------------------------------------------------------
--  DDL for Function TIPOCHAR
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."TIPOCHAR" (p_data in varchar2) RETURN VARCHAR2 AS 
i long;
v_char1 CHAR(4);
v_char_t VARCHAR2(16);
v_date varchar2(2000):='';
BEGIN
  return p_data;
exception
  when others then  
/*
   For i In 1..length(trim(p_data)) Loop
     --
     v_char1:=substr(p_data,i,1);
     v_char_t:=null;
     
     --將可能包含自造字之文字轉換為標準UNICODE文字
     SELECT char_unicode INTO v_char_t FROM ap.spm77
     WHERE char_tipo=v_char1
     AND trim(char_unicode) is not null;
     
     --
     if v_char_t is null then
        v_date:=v_date||v_char1;
     else
        v_date:=v_date||v_char_t;
     end if;
   End Loop;
*/
  RETURN v_date;
END TIPOCHAR;

/
--------------------------------------------------------
--  DDL for Function VALID_DATE
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."VALID_DATE" (p_date in varchar2)
return boolean
is
  v_data varchar2(8);
  v_tmp_date date;
begin
  v_data := trim(p_date);
  if length(v_data) = 8 then
    v_tmp_date := to_date(v_data, 'yyyymmdd');
    return true;
  end if;
  return false;
exception
  when others then
    return false;
end valid_date;

/
--------------------------------------------------------
--  DDL for Function VALID_NUMBER
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."VALID_NUMBER" (p_str in varchar2)
return boolean
is
  v_tmp_num number;
begin
  v_tmp_num := to_number(p_str);
  return true;
exception
  when others then
    return false;
end valid_number;

/
--------------------------------------------------------
--  DDL for Function VALID_TW_DATE
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."VALID_TW_DATE" (p_date in varchar2)
return boolean
is
  v_data varchar2(7);
  v_tmp_date date;
  v_tmp_num number;
begin
  v_data := trim(p_date);
  v_tmp_num := to_number(substr(v_data, 1, 3));
  if length(v_data) = 7 then
    v_tmp_date := to_date(v_data + 19110000, 'yyyymmdd');
    return true;
  end if;
  return false;
exception
  when others then
    return false;
end valid_tw_date;

/
--------------------------------------------------------
--  DDL for Function VALID_TW_DATE2
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."VALID_TW_DATE2" (p_date in varchar2) 
return number
is
  v_data varchar2(7);
  v_tmp_date date;
  v_tmp_num number;
begin
  v_data := trim(p_date);
  v_tmp_num := to_number(substr(v_data, 1, 3));
  if length(v_data) = 7 then
    v_tmp_date := to_date(to_char(v_tmp_num + 1911) || substr(v_data, 4), 'yyyymmdd');
    return 0;
  end if;
  return 1;
exception
  when others then
    return 1;
end valid_tw_date2;

/
--------------------------------------------------------
--  DDL for Function VCHAR_TO_DATE
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."VCHAR_TO_DATE" (p_date in varchar2)
return date
is
  v_data varchar2(8);
  v_tmp_date date:=null;
begin
  if p_date is not null then
    v_data := trim(p_date);
    if length(v_data) = 8 then
        v_tmp_date := to_date(v_data, 'yyyymmdd');
        return v_tmp_date;
    end if;
    
    if length(v_data) = 7 then
        v_tmp_date := to_date(v_data+19110000, 'yyyymmdd');
        return v_tmp_date;
    end if;
  end if;

  return null;
exception
  when others then
    return null;
end VCHAR_TO_DATE;

/
--------------------------------------------------------
--  DDL for Function WF_CHECK
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."WF_CHECK" (p_no                      in char,
                                      p_appl_date               in varchar2,
                                      p_process_result          in varchar2,
                                      p_appl_exam_flag          in varchar2,
                                      p_appl_priority_exam_flag in varchar2,
                                      p_pre_exam_date           in varchar2,
                                      p_pre_exam_qty            in number)
  return pair_tab is
  c_yes constant char(1) := '1';
  g_out_message_array pair_tab := pair_tab();

  v_appl_no      spt21.appl_no%type;
  v_type_no      spt21.type_no%type;
  v_appl_date    spt31.appl_date%type;
  v_re_appl_date spt31.re_appl_date%type;
  v_step_code    spt31a.step_code%type;
  v_tmp_count    number(4);

  procedure add_error_message(p_key in varchar2, p_message in varchar2)
  --============--
    --新增錯誤訊息--
    --============--
   is
  begin
    g_out_message_array.extend;
    g_out_message_array(g_out_message_array.last) := pair_obj(p_key,
                                                              p_message);
  end add_error_message;
begin

  begin
    begin
      select appl_no, type_no
        into v_appl_no, v_type_no
        from spt21
       where receive_no = p_no;
    exception
      when no_data_found then
        v_appl_no := p_no;
    end;
    select appl_date, re_appl_date
      into v_appl_date, v_re_appl_date
      from spt31
     where appl_no = v_appl_no;
    select step_code
      into v_step_code
      from spt31a
     where appl_no = v_appl_no;
  exception
    when no_data_found then
      add_error_message('', '查無資料，WF_CHECK失敗');
      return g_out_message_array;
  end;

  if substr(v_appl_no, 4, 1) = '1' and
     p_process_result in ('43199', '43191', '41001', '43001') then
    add_error_message('PROCESS_RESULT',
                      '發明案不可輸入43199、43191、41001、43001');
  end if;
  if substr(v_appl_no, 4, 1) = '2' and
     p_process_result in ('49201', '49213', '43001') then
    add_error_message('PROCESS_RESULT',
                      '新型案不可輸入49201、49213、43001');
  end if;
  if substr(v_appl_no, 4, 1) = '3' and
     p_process_result in ('49201', '49213', '43191', '43199') then
    add_error_message('PROCESS_RESULT',
                      '設計、衍生設計案不可輸入49201、49213、43191、43199');
  end if;

  if substr(v_appl_no, 4, 1) = '3' and v_type_no = '10007' then
    if valid_tw_date(p_appl_date) and v_appl_date > p_appl_date then
      add_error_message('APPL_DATE',
                        '申請衍生設計專利，其申請日不得早於原設計之申請日！');
    end if;
    declare
      v_notice_date spmf1.notice_date%type;
    begin
      select notice_date
        into v_notice_date
        from spmf1
       where appl_no = v_appl_no;
      if valid_tw_date(v_notice_date) and valid_tw_date(p_appl_date) then
        if v_notice_date < p_appl_date and
           p_process_result in ('43001', '43009', '43015') then
          add_error_message('PROCESS_RESULT', '不可輸入43001,43009,43015');
        end if;
      end if;
    exception
      when no_data_found then
        null;
    end;
  end if;

  if p_process_result = '43011' then
    select count(1)
      into v_tmp_count
      from spt21
     where appl_no = v_appl_no
       and type_no in ('16000', '16002', '24060', '24062');
    if v_tmp_count = 0 then
      add_error_message('PROCESS_RESULT',
                        '此案件未收過更正案相關收文案由(16000、16002、24060、24062)【辦理結果】不可為43011(通知更正事件進行審查)');
    end if;
  end if;

  if p_process_result = '42101' then
    select count(1)
      into v_tmp_count
      from spt21
     where appl_no = v_appl_no
       and type_no = '10010';
    if v_tmp_count = 0 then
      add_error_message('PROCESS_RESULT',
                        '該申請案需收過10010(撤回專利申請)方可填入42101(撤回申請案通知函)辦理，請通知收文人員修改案由或輸入其它辦理結果');
    end if;
  end if;

  if p_process_result in ('49247', '49249') then
    if p_appl_exam_flag = c_yes then
      add_error_message('APPL_EXAM_FLAG',
                        '此辦理結果不得有申請實體審查註記，請將「申請實體審查」選項去除!!');
    end if;
    if p_appl_priority_exam_flag = c_yes then
      add_error_message('APPL_PRIORITY_EXAM_FLAG',
                        '此辦理結果不得有申請實體審查與優先審查註記，請將「申請實體審查與優先審查」選項去除!!');
    end if;
  end if;

  if v_type_no is not null then
    --有收文資料
    if p_process_result in ('41001',
                            '41003',
                            '41011',
                            '41505',
                            '41515',
                            '40009',
                            '40001',
                            '40003',
                            '40005',
                            '40007',
                            '40011',
                            '40013',
                            '40301',
                            '41005',
                            '41007',
                            '41025',
                            '41027',
                            '49201',
                            '49203',
                            '49205',
                            '49239',
                            '49251',
                            '49241',
                            '49261',
                            '49263',
                            '41071') then
      if p_pre_exam_date is null and p_pre_exam_qty is null then
        add_error_message('PRE_EXAM_DATE',
                          '補正期限或補正日數，需擇一輸入');
      end if;
      if p_pre_exam_date is not null then
        if not valid_tw_date(p_pre_exam_date) then
          add_error_message('PRE_EXAM_DATE', '補正期限格式不正確');
        elsif p_pre_exam_date < (to_char(sysdate, 'yyyymmdd') - 19110000) then
          add_error_message('PRE_EXAM_DATE', '補正期限小於系統日');
        end if;
      end if;
      if p_pre_exam_qty is not null then
        if p_pre_exam_qty > 99 then
          add_error_message('PRE_EXAM_QTY', '補正日數格式不正確');
        end if;
      end if;
    end if;
  end if;

  if p_process_result in ('49213',
                          '49215',
                          '49217',
                          '49269',
                          '43191',
                          '43199',
                          '43001',
                          '43009',
                          '43015') then
    select count(1)
      into v_tmp_count
      from spm11
     where (nvl(trim(national_id), '90') = '90' or trim(name_c) is null)
       and appl_no = v_appl_no;
    if v_tmp_count > 0 then
      add_error_message('PROCESS_RESULT',
                        '本案申請人或發明人國籍狀態為容後補呈，不可作齊備！');
    end if;
  end if;

  if p_process_result in ('43001', '49207', '49213') then
    select count(1)
      into v_tmp_count
      from spm11
     where id_type in ('1', '2')
       and id_no = 'P800138717'
       and appl_no = v_appl_no;
    if v_tmp_count > 0 then
      add_error_message('PROCESS_RESULT',
                        '本案之基本資料中有P800138717(容後補呈)之人名ID！不允許製稿。');
    end if;
  end if;

  if p_process_result in ('43001',
                          '42003',
                          '42101',
                          '49207',
                          '49213',
                          '49249',
                          '41001',
                          '49243',
                          '43191',
                          '43199') and
     not (10 <= v_step_code and v_step_code < 29) then
    add_error_message('PROCESS_RESULT',
                      '此辦理結果與案件階段別不符，請確認辦理結果是否正確');
  end if;

  if p_process_result in ('43003', '42007', '42103', '41003') then
    if not (30 <= v_step_code and v_step_code < 49) then
      add_error_message('PROCESS_RESULT',
                        '此辦理結果與案件階段別不符,請確認辦理結果是否正確');
    end if;
    if trim(v_re_appl_date) is null then
      add_error_message('', '此案無再審申請日期,無法製稿');
    end if;
  end if;

  if p_process_result in
     ('43007', '42015', '42107', '41011', '41505', '41515') and
     not (70 <= v_step_code and v_step_code < 89) then
    add_error_message('PROCESS_RESULT',
                      '此辦理結果與案件階段別不符，請確認辦理結果是否正確');
  end if;

  if p_process_result = '57001' then
    add_error_message('PROCESS_RESULT', '辦理結果不可為57001');
  end if;

  return g_out_message_array;
end wf_check;

/
