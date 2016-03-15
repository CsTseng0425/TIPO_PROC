--------------------------------------------------------
--  DDL for Procedure RESET_INFO_APPLS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."RESET_INFO_APPLS" (p_pre_date in varchar2,
                                                     p_out_msg         out varchar2) is
  v_count      number;                --���}����
  v_notice_date date;                 --���}���
  v_notice_date7 char(7);             --���}���(������)
  v_flag_date      number;            --193�n�����}���
  v_flag_no      number;              --193�s���}��
   v_code_id  ap.spmf6.code_id%type;  --��s v_code_id & v_data_seq
  v_data_seq  ap.spmf6.data_seq%type;
begin
  select count(1) into v_count from ppr82 where PRE_DATE=p_pre_date;

  if v_count > 0 then
    v_notice_date:=add_months(to_date(p_pre_date+19110000,'YYYYMMDD'),3);
    SYS.Dbms_Output.Put_Line('notice_date: '||to_char(v_notice_date,'YYYYMMDD'));
    
    --�ˬd193���}����B���}��
    v_notice_date7:=lpad(to_char(v_notice_date,'YYYYMMDD')-19110000,7,'0');    
    select (case when notice_no_193=notice_no_190 then 1 else 0 end),
           (case when count_193=count_190 then 1 else 0 end) into v_flag_no,v_flag_date
    from
        (select nvl(max(notice_no_2),0) notice_no_193 from ppr82 where notice_date_2=v_notice_date7),
        (select nvl(max(notice_no_2),0) notice_no_190 from spt82 where notice_date_2=v_notice_date7),
        (select count(1) count_193 from ppr82 where notice_date_2=v_notice_date7),
        (select count(1) count_190 from spt82 where notice_date_2=v_notice_date7)
    ;
    if v_flag_no=0 then
      p_out_msg:='�]�M�Q��F�t�Τw�s���}���A�L�k�٭�!!';
      SYS.Dbms_Output.Put_Line(p_out_msg);
      return;
    end if;
    if v_flag_date=0 then
      p_out_msg:='�]�M�Q��F�t�Τw�n�����}����A�L�k�٭�!!';
      SYS.Dbms_Output.Put_Line(p_out_msg);
      return;
    end if;

    --�٭줽�}���,���}��
    update spt82 set Notice_No_2='0', Notice_Date_2=null,notice_status_2='0',prv_notice_date_2=null
    where appl_no in (select appl_no from ppr82 where PRE_DATE=p_pre_date);
    
    --�٭����
    update spt81a set Notice_No_B=null,Notice_No_E=null
    where Notice_Date=to_char(to_char(v_notice_date,'YYYYMMDD')-19110000);
    update spmf1 set Notice_Vol_3=null,Notice_Vol_4=null,Notice_no_2=null,Notice_date_2=null
    where appl_no in (select appl_no from ppr82 where PRE_DATE=p_pre_date); 
    
    --�٭�spt81a���}��
    begin
      select CODE_ID,data_seq into v_code_id,v_data_seq
      from(
        select lpad(Notice_Vol_1,3,'0')||lpad(Notice_Vol_2,3,'0') code_id, 
               nvl(Notice_No_E,to_char(v_notice_date,'YYYY')||'00000') data_seq
        from spt81a 
        where substr(notice_date,1,3)=to_char(to_char(v_notice_date,'YYYY')-1911)
        and (Notice_No_E is not null or Notice_Vol_2=1)
        order by 1 desc
      )where rownum=1
      ;
    SYS.Dbms_Output.Put_Line('code_id='||v_code_id||' data_seq='||v_data_seq);
      
    EXCEPTION
      --WHEN NO_DATA_FOUND THEN
      WHEN others THEN
      DBMS_OUTPUT.PUT_LINE (SQLERRM);
    end;

    update spmf6 set data_seq=v_data_seq, code_id=v_code_id
    where sys_id='F6' 
    and class_id=to_char(to_char(v_notice_date,'YYYY')-1911);
    
    --�٭줽�}���q�O
    update spt31b set step_code='30' where step_code in ('50','60') and appl_no in (select appl_no from ppr82 where PRE_DATE=p_pre_date and online_flag='1');
    update spt31b set step_code='50' where step_code='60' and appl_no in (select appl_no from ppr82 where PRE_DATE=p_pre_date and online_flag in ('0','2'));
    
    --�R���u�W���}�ץ�
    delete spt82 where appl_no in (select appl_no from ppr82 where PRE_DATE=p_pre_date and online_flag='1');

    --�R��193���}�ץ�
    delete ppr82 where PRE_DATE=p_pre_date;

  end if;

  p_out_msg:='�٭�(��)���}�ץ� '||v_count||' ��!';
  SYS.Dbms_Output.Put_Line(p_out_msg);
exception
  when others then  
  rollback;
  p_out_msg:='�٭�(��)���}�ץ󥢱�!';
  SYS.Dbms_Output.Put_Line(p_out_msg);
  DBMS_OUTPUT.PUT_LINE (SQLERRM);
end RESET_INFO_APPLS;

/
