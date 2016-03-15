--------------------------------------------------------
--  DDL for Procedure RESET_EARLY_APPLS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."RESET_EARLY_APPLS" (p_appl_no in varchar2,
                                                      p_out_msg         out varchar2) is
  v_count      number;
begin
  SYS.Dbms_Output.Put_Line('appl_no='||p_appl_no);
/*
105/01/26: ���� update appl ���� step_code = 25
105/02/16: �W�[ update appl ���� divide_code =  '3'  -- only cancel the application from  70014
*/

  if trim(p_appl_no) is not null then
      select count(1) into v_count from appl_catg  where trim(appl_no) = p_appl_no and patent_class='Y';
      --select count(1) into v_count from appl_catg a,spt31b b where trim(a.appl_no) = :p_appl_no and patent_class='Y' and a.appl_no=b.appl_no and substr(a.step_code,1,1)=substr(b.step_code,1,1);
      if v_count=0 then
        p_out_msg:='�D�����ȥ���u�W�ץ�A�L�k�٭�!';      
        return;
      end if;
      --resetSpt31a
      update spt31a set step_code='15',Ipc_Group_No='70014'
      where trim(appl_no) = p_appl_no;
      
      --reset Spt31b
      update spt31b set step_code='20'
      where trim(appl_no) = p_appl_no;
      
      update appl set DIVIDE_CODE = '0', FINISH_FLAG = '1'
      where trim(appl_no) = p_appl_no
      and divide_code =  '3'  -- only cancel the application from  70014
      ; 
      
      --reset Appl_Trans
      --delete Appl_Trans where trim(appl_no) = p_appl_no;
      
      --appl_trans log
      INSERT INTO appl_trans (ID, APPL_NO, TRANS_NO, STEP_CODE_PRV, STEP_CODE, OBJECT_FROM, OBJECT_TO, PROCESSOR_NO, ACCEPT_DATE, REMARK) 
      VALUES (APPL_TRANS_ID_SEQ.nextval, p_appl_no, null, '21', '15', null, null, null, SYSTIMESTAMP, 's193�u�W��ȥ��ץ�');
      --reset appl_catg
      delete appl_catg where trim(appl_no) = p_appl_no;
      
  else
    select count(1) into v_count from appl_catg  where patent_class='Y';
    if v_count=0 then
      p_out_msg:='�D�����ȥ���u�W�ץ�A�L�k�٭�!';      
      return;
    end if;

      --resetSpt31a
      update spt31a set step_code='15'--,Ipc_Group_No='70014'
      where appl_no in (select appl_no from appl_catg where patent_class='Y');
      
      --reset Spt31b
      update spt31b set step_code='20'
      where appl_no in (select appl_no from appl_catg where patent_class='Y');
      
      update appl set DIVIDE_CODE = '0', FINISH_FLAG = '1'
      where appl_no = (select appl_no from appl_catg where step_code='25' and patent_class='Y');
      
      --reset Appl_Trans
      --delete Appl_Trans where appl_no in (select appl_no from appl_catg);
      
            
      --appl_trans log
      INSERT INTO appl_trans (ID, APPL_NO, TRANS_NO, STEP_CODE_PRV, STEP_CODE, OBJECT_FROM, OBJECT_TO, PROCESSOR_NO, ACCEPT_DATE, REMARK) 
      select APPL_TRANS_ID_SEQ.nextval, appl_no, null, '21', '15', null, null, null, SYSTIMESTAMP, 's193�u�W��ȥ��ץ�'
      from appl_catg where patent_class='Y';
      
      --reset appl_catg
      delete appl_catg;
  end if;
  p_out_msg:='�u�W��ȥ��ץ� '||v_count||' ��!';
  SYS.Dbms_Output.Put_Line('�u�W��ȥ��ץ� '||v_count||' ��!');
exception
  when others then  
  rollback;
  p_out_msg:='�M�������ץ󥢱�!';
  SYS.Dbms_Output.Put_Line(p_out_msg);
end RESET_EARLY_APPLS;

/
