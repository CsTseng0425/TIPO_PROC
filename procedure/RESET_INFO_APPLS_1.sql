--------------------------------------------------------
--  DDL for Procedure RESET_INFO_APPLS_1
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."RESET_INFO_APPLS_1" (p_appl_no in varchar2,
                                                     p_out_msg         out varchar2) is
/*
取消資服組剔除案件
20151015  新增
*/
  v_count      number;
begin
  select count(1) into v_count from ppr82 where trim(appl_no)=p_appl_no;
  if v_count > 0 then
    --還原公開日期,公開號
    update spt82 set Notice_No_2='0', Notice_Date_2=null,notice_status_2='0',prv_notice_date_2=null
    where appl_no in (select appl_no from ppr82 where trim(appl_no)=p_appl_no);
    
    --還原卷期
    update spmf1 set Notice_Vol_3=null,Notice_Vol_4=null,Notice_no_2=null,Notice_date_2=null
    where appl_no in (select appl_no from ppr82 where trim(appl_no)=p_appl_no); 
    
    --還原公開階段別
    update spt31b set step_code='30' where step_code in ('50','60') and appl_no in (select appl_no from ppr82 where trim(appl_no)=p_appl_no and online_flag='1');
    update spt31b set step_code='50' where step_code='60' and appl_no in (select appl_no from ppr82 where trim(appl_no)=p_appl_no and online_flag in ('0','2'));
    
    --刪除線上公開案件
    delete spt82 where appl_no in (select appl_no from ppr82 where trim(appl_no)=p_appl_no and online_flag='1');

    --刪除193公開案件
    delete ppr82 where trim(appl_no)=p_appl_no;
  end if;
  p_out_msg:='取消資服組剔除案件 '||v_count||' 筆!';
  SYS.Dbms_Output.Put_Line(p_out_msg);
exception
  when others then  
  rollback;
  p_out_msg:='取消資服組剔除案件失敗!';
  SYS.Dbms_Output.Put_Line(p_out_msg);
end RESET_INFO_APPLS_1;

/
