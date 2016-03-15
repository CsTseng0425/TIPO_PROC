--------------------------------------------------------
--  DDL for Procedure RESET_INFO_APPLS_1
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."RESET_INFO_APPLS_1" (p_appl_no in varchar2,
                                                     p_out_msg         out varchar2) is
/*
������A�խ簣�ץ�
20151015  �s�W
*/
  v_count      number;
begin
  select count(1) into v_count from ppr82 where trim(appl_no)=p_appl_no;
  if v_count > 0 then
    --�٭줽�}���,���}��
    update spt82 set Notice_No_2='0', Notice_Date_2=null,notice_status_2='0',prv_notice_date_2=null
    where appl_no in (select appl_no from ppr82 where trim(appl_no)=p_appl_no);
    
    --�٭����
    update spmf1 set Notice_Vol_3=null,Notice_Vol_4=null,Notice_no_2=null,Notice_date_2=null
    where appl_no in (select appl_no from ppr82 where trim(appl_no)=p_appl_no); 
    
    --�٭줽�}���q�O
    update spt31b set step_code='30' where step_code in ('50','60') and appl_no in (select appl_no from ppr82 where trim(appl_no)=p_appl_no and online_flag='1');
    update spt31b set step_code='50' where step_code='60' and appl_no in (select appl_no from ppr82 where trim(appl_no)=p_appl_no and online_flag in ('0','2'));
    
    --�R���u�W���}�ץ�
    delete spt82 where appl_no in (select appl_no from ppr82 where trim(appl_no)=p_appl_no and online_flag='1');

    --�R��193���}�ץ�
    delete ppr82 where trim(appl_no)=p_appl_no;
  end if;
  p_out_msg:='������A�խ簣�ץ� '||v_count||' ��!';
  SYS.Dbms_Output.Put_Line(p_out_msg);
exception
  when others then  
  rollback;
  p_out_msg:='������A�խ簣�ץ󥢱�!';
  SYS.Dbms_Output.Put_Line(p_out_msg);
end RESET_INFO_APPLS_1;

/
