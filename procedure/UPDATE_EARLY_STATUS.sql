--------------------------------------------------------
--  DDL for Procedure UPDATE_EARLY_STATUS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."UPDATE_EARLY_STATUS" AS 

BEGIN

      INSERT INTO appl_trans (ID, APPL_NO, TRANS_NO, STEP_CODE_PRV, STEP_CODE, OBJECT_FROM, OBJECT_TO, PROCESSOR_NO, ACCEPT_DATE, REMARK) 
			select APPL_TRANS_ID_SEQ.nextval, a.appl_no, null, a.step_code, '33', null, a.processor_no, a.processor_no, sysdate, 's193執行完成公開前審查'
      from appl_catg a,spt41 b,spt31b c
      where a.appl_no=b.appl_no and a.process_result=b.issue_type
      and a.process_result in ('49221','49223','49225','49273','49275')
      and FILE_D_FLAG='*' and a.step_code='27'
      and a.appl_no=c.appl_no and c.step_code ='60';
     
			update appl_catg set step_code='33',complete_date=sysdate
			where appl_no in (select a.appl_no
      from appl_catg a,spt41 b,spt31b c
      where a.appl_no=b.appl_no and a.process_result=b.issue_type
      and a.process_result in ('49221','49223','49225','49273','49275')
      and FILE_D_FLAG='*' and a.step_code='27'
      and a.appl_no=c.appl_no and c.step_code ='60' );
 

      INSERT INTO appl_trans (ID, APPL_NO, TRANS_NO, STEP_CODE_PRV, STEP_CODE, OBJECT_FROM, OBJECT_TO, PROCESSOR_NO, ACCEPT_DATE, REMARK) 
			select APPL_TRANS_ID_SEQ.nextval, a.appl_no, null, a.step_code, '70', null, a.processor_no, a.processor_no, sysdate, 's193執行不予公開'
      from appl_catg a,spt41 b,spt31b c
      where a.appl_no=b.appl_no and a.process_result=b.issue_type
      and a.process_result in ('49221','49223','49225','49273','49275')
      and FILE_D_FLAG='*' and a.step_code='27'
      and a.appl_no=c.appl_no and c.step_code ='70';
     
			update appl_catg set step_code='70',complete_date=sysdate
			where appl_no in (select a.appl_no
      from appl_catg a,spt41 b,spt31b c
      where a.appl_no=b.appl_no and a.process_result=b.issue_type
      and a.process_result in ('49221','49223','49225','49273','49275')
      and FILE_D_FLAG='*' and a.step_code='27'
      and a.appl_no=c.appl_no and c.step_code ='70' );


      /*
        ModifyDate:104/10/09
        --如果spt31b.step_code=70 AND appl_catg.step_code<70,則將appl_catg.step_code更變為70
      */
      /*
      INSERT INTO appl_trans (ID, APPL_NO, TRANS_NO, STEP_CODE_PRV, STEP_CODE, OBJECT_FROM, OBJECT_TO, PROCESSOR_NO, ACCEPT_DATE, REMARK) 
			select APPL_TRANS_ID_SEQ.nextval, a.appl_no, null, a.step_code, '70', null, a.processor_no, a.processor_no, null, 's193執行有不予公開'
      from appl_catg a, spt31b b
			where a.appl_no=b.appl_no 
			and b.step_code ='70' and a.step_code<'70';
     
      update appl_catg set step_code='70'
			where appl_no in (select a.appl_no
			from appl_catg a, spt31b b
			where a.appl_no=b.appl_no 
			and b.step_code ='70' and a.step_code<'70');
      */
      /*
        ModifyDate:104/10/09
        --如果spt31b.step_code=60 AND appl_catg.step_code='27' AND appl_catg.FILE_D_FLAG='*'
        ,則將appl_catg.step_code更變為33
      */
      /*
      INSERT INTO appl_trans (ID, APPL_NO, TRANS_NO, STEP_CODE_PRV, STEP_CODE, OBJECT_FROM, OBJECT_TO, PROCESSOR_NO, ACCEPT_DATE, REMARK) 
			select APPL_TRANS_ID_SEQ.nextval, a.appl_no, null, a.step_code, '33', null, a.processor_no, a.processor_no, null, 's193執行完成公開前審查'
      from appl_catg a,spt41 b,spt31b c
      where a.appl_no=b.appl_no and a.process_result=b.issue_type
      and a.process_result in ('49221','49223','49225','49273','49275')
      and FILE_D_FLAG='*' and a.step_code='27'
      and c.step_code ='60';
     
			update appl_catg set step_code='33'
			where appl_no in (select a.appl_no
      from appl_catg a,spt41 b,spt31b c
      where a.appl_no=b.appl_no and a.process_result=b.issue_type
      and a.process_result in ('49221','49223','49225','49273','49275')
      and FILE_D_FLAG='*' and a.step_code='27'
      and c.step_code ='60' );
      */
      /*
        ModifyDate:104/10/09
        --如果spt31b.step_code>=10 AND spt31b.step_code<=50 AND appl_catg.step_code='27' AND appl_catg.FILE_D_FLAG='*'
        ,則將appl_catg.step_code更變為70
      */
      /*
      INSERT INTO appl_trans (ID, APPL_NO, TRANS_NO, STEP_CODE_PRV, STEP_CODE, OBJECT_FROM, OBJECT_TO, PROCESSOR_NO, ACCEPT_DATE, REMARK) 
			select APPL_TRANS_ID_SEQ.nextval, a.appl_no, null, a.step_code, '70', null, a.processor_no, a.processor_no, null, 's193執行有不予公開'
      from appl_catg a,spt41 b,spt31b c
      where a.appl_no=b.appl_no and a.process_result=b.issue_type
      and a.process_result in ('49221','49223','49225','49273','49275')
      and FILE_D_FLAG='*' and a.step_code='27'
      and c.step_code>='10' and c.step_code<='50';
      
      update appl_catg set step_code='70',complete_date=sysdate
			where appl_no in (select a.appl_no
			from appl_catg a,spt41 b,spt31b c
			where a.appl_no=b.appl_no and a.process_result=b.issue_type
			and a.process_result in ('49221','49223','49225','49273','49275')
			and FILE_D_FLAG='*' and a.step_code='27'
			and c.step_code>='10' and c.step_code<='50');
      
      update spt31b set step_code='70'
			where appl_no in (select a.appl_no
			from appl_catg a,spt41 b,spt31b c
			where a.appl_no=b.appl_no and a.process_result=b.issue_type
			and a.process_result in ('49221','49223','49225','49273','49275')
			and FILE_D_FLAG='*' and a.step_code='27'
			and c.step_code>='10' and c.step_code<='50');
      */
END UPDATE_EARLY_STATUS;

/
