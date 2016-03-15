--------------------------------------------------------
--  DDL for Procedure SEND_APPL_TO_PROCEDURE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SEND_APPL_TO_PROCEDURE" (
  p_PROCESSOR_NO VARCHAR2, --[in ]�ӿ�H�N�X
  p_APPL_NO VARCHAR2,      --[in ]�ӽЮ׸�
  p_REMARK VARCHAR2,       --[in ]�h��{�ǲz��
  P_OUT_MSG OUT NUMBER) --[out]���\(>0)/����(else)
AS

  ----------------------------------------
  --�h��{�� �s�W�Χ�s�{�Ǯץ�
  -- update 104/09/17 ����h���,�Y�̫�@��P03-1�ӿ�H�� �~�]����¾�H�� ,�h�i�����
  ----------------------------------------
  procedure insert_proc_appl
  as
   l_processor_no char(5);
   l_cnt number;
   begin
      select  (select processor_no from spm63 where processor_no =  spm56.processor_no and dept_no = '70012'  and quit_date is null) 
          into l_processor_no
                from spm56 
                where trim(appl_no) = trim(p_APPL_NO)
                 and form_file_a = (select max(form_file_a) from spm56 s56 where spm56.appl_no = s56.appl_no)
                 and form_id = 'P03-1'
                 ;
        
        select count(1) into l_cnt from appl where trim(appl_no) =  trim(p_APPL_NO);
        
      --�s�W
      if l_cnt = 0 then
      insert into appl(APPL_NO,STEP_CODE,DIVIDE_CODE,DIVIDE_REASON,FINISH_FLAG,
                       RETURN_NO,IS_OVERTIME,PROCESS_DATE,PROCESSOR_NO)
        select appl_catg.APPL_NO,
               spt31a.step_code STEP_CODE,
               '3' DIVIDE_CODE,
               p_REMARK DIVIDE_REASON,
               '0' FINISH_FLAG,
               '0' RETURN_NO,
               '0' IS_OVERTIME,
               TO_CHAR(TO_NUMBER(TO_CHAR(SYSDATE, 'YYYYMMDD')) - 19110000) PROCESS_DATE,
               case when l_processor_no  is null or substr(l_processor_no,1,1) = 'P' then
                ( select processor_no   from skill where auto_shift = '1'
                                  and processor_no > ( select trim(para_no)  from appl_para where sys = 'OVERTIME' and subsys = 'TAKETURN')
                                  and rownum =1 ) 
                   else l_processor_no
                  
               end
               PROCESSOR_NO -- last P03-1 maker or take turn processor_no
          from appl_catg,spt31a
         where appl_catg.appl_no=spt31a.appl_no(+) 
           and trim(appl_catg.appl_no)=trim(p_APPL_NO)
           and appl_catg.step_code in ('22','24','26','27','28','29');   
       else
          update appl set DIVIDE_CODE='3',
                        DIVIDE_REASON=p_REMARK,
                        PROCESS_DATE=TO_CHAR(TO_NUMBER(TO_CHAR(SYSDATE, 'YYYYMMDD')) - 19110000)  ,
                        processor_no =  case when l_processor_no   is null or substr(l_processor_no,1,1) = 'P' then
                                ( select processor_no   from skill where auto_shift = '1'
                                  and processor_no > ( select trim(para_no)  from appl_para where sys = 'OVERTIME' and subsys = 'TAKETURN')
                                  and rownum =1 ) 
                          else
                             l_processor_no
                       end
         where trim(appl_no)=trim(p_APPL_NO);
       end if;
         --- 
         -- ���s�]�w����
         -------
           IF l_processor_no is null or substr(l_processor_no,1,1) = 'P' THEN
               update appl_para 
               set para_no = ( select processor_no   from skill where auto_shift = '1'
                                  and processor_no > ( select trim(para_no)  from appl_para where sys = 'OVERTIME' and subsys = 'TAKETURN')
                                  and rownum =1 ) 
               where sys = 'OVERTIME' and subsys = 'TAKETURN'
               ;
           END IF;

  
        
  end;
  ----------------------------------------
  --�h��{�� ��s�������A
  ----------------------------------------
  procedure update_early_status
  as
  begin

    insert into appl_trans
      select APPL_TRANS_ID_SEQ.nextval ID,
             appl_no, 
             '1' trans_no,
             step_code step_code_prv,
            '25' step_code, 
             PROCESSOR_NO object_from,
             '70012' object_to,
             p_PROCESSOR_NO PROCESSOR_NO,
             sysdate TRANS_DATE,
             sysdate ACCEPT_DATE,
             '�h��{��:'||p_REMARK remark
        from appl_catg
        where trim(appl_no)=trim(p_APPL_NO);
        
    update appl_catg set step_code='25',send_date=null /*���C�J���*/
      where trim(appl_no)=trim(p_APPL_NO);

  end;
  
----------------------------------------
--�h��{�� �D�{��
----------------------------------------
BEGIN
  
  --�s�W�Χ�s�{�Ǯץ�
  insert_proc_appl;

  --��s�������A
  update_early_status;

/*
  if SQL%ROWCOUNT>0 then
    --��s�������A
    update_early_status;
  end if;
*/  
  --�^�ǧ�s����
  P_OUT_MSG:=1;
  
  exception
    WHEN OTHERS THEN
      P_OUT_MSG:=0;
END SEND_APPL_TO_PROCEDURE;

/
