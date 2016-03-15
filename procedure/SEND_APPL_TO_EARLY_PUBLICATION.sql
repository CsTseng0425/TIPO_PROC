--------------------------------------------------------
--  DDL for Procedure SEND_APPL_TO_EARLY_PUBLICATION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."SEND_APPL_TO_EARLY_PUBLICATION" (
  p_PROCESSOR_NO VARCHAR2, --[in ]承辦人代碼
  p_APPL_NO VARCHAR2,      --[in ]申請案號
  p_FUNC_CODE VARCHAR2,    --[in ]功能代碼 0:程序已撤回該案 1:程序回覆成功 2:程序退辦它科(早期)
  p_PROCESS_RESULT VARCHAR2,       --[in ]退辦程序理由
  P_OUT_MSG OUT NUMBER) --[out]成功(>0)/失敗(else)
AS

----------------------------------------
--程序回覆成功 早期處理邏輯
----------------------------------------
PROCEDURE appl_trans_success
as
begin
	  insert into appl_trans
	  select APPL_TRANS_ID_SEQ.nextval ID,
           appl_no, 
	         p_FUNC_CODE trans_no,
		       step_code step_code_prv,
          '26' step_code, 
		       p_PROCESSOR_NO object_from,
		       PROCESSOR_NO object_to,
		       p_PROCESSOR_NO PROCESSOR_NO,
           sysdate TRANS_DATE,
           sysdate ACCEPT_DATE,
		       '程序回覆:'||p_PROCESS_RESULT remark
    from appl_catg
	  where trim(appl_no)=trim(p_APPL_NO) and step_code='25';
	
	  --更新狀態
    update appl_catg set step_code=26,send_date=sysdate /*重新列入本月*/
    where trim(appl_no)=trim(p_APPL_NO) 
      and step_code='25';
end;
----------------------------------------
--程序回覆撤回 早期處理邏輯
----------------------------------------
PROCEDURE appl_trans_reject
as
begin
	  insert into appl_trans
	  select APPL_TRANS_ID_SEQ.nextval ID,
           appl_no, 
	         p_FUNC_CODE trans_no,
           step_code step_code_prv,
		       '20' step_code, 
		       PROCESSOR_NO object_from,
		       null object_to,
		       p_PROCESSOR_NO PROCESSOR_NO,
           sysdate TRANS_DATE,
           sysdate ACCEPT_DATE,
		       '程序撤回:'||p_PROCESS_RESULT remark
    from appl_catg
	  where trim(appl_no)=trim(p_APPL_NO) and step_code='25';
	
	  --更新狀態
    update appl_catg set step_code=20
                       --,processor_no=null,supervisor_no=null,SEND_BACK_CNT=0, SEND_DATE=null,ACCEPT_DATE=null,ASSIGN_DATE=null
    where trim(appl_no)=trim(p_APPL_NO) 
      and step_code='25';
end;
----------------------------------------
--程序退辦給70014 早期處理邏輯
----------------------------------------
PROCEDURE appl_trans_send
as
l_APPL_NO	CHAR(15):=null;
l_PROCESSOR_NO	CHAR(5):=null;
l_STEP_CODE	CHAR(2):=null;
begin
	  --更新狀態
    begin
    select appl_no, PROCESSOR_NO,STEP_CODE
    into l_appl_no, l_PROCESSOR_NO,l_STEP_CODE
    from appl_catg 
    where trim(appl_no)=trim(p_APPL_NO);
    exception  
      WHEN OTHERS THEN
        dbms_output.put_line(l_appl_no);
        l_appl_no := null;
    end ;
 
    if(l_appl_no is null) then /*人工分派*/
         INSERT into appl_catg (
            APPL_NO,PROCESSOR_NO,ASSIGN_DATE,STEP_CODE,SEND_BACK_CNT,
            PROCESSOR_NO_PRV,PROCESSOR_NO_PRV_2
            )
		      VALUES (
            p_APPL_NO,'70014',sysdate,'21',3, 
            p_PROCESSOR_NO,'70012'
            );
         l_PROCESSOR_NO:='70014';
    else 
      if (l_STEP_CODE='25') then /*程序回覆*/
            update appl_catg set step_code='26', send_date=sysdate /*重新列入本月*/
            where trim(appl_no)=trim(p_APPL_NO);
      else 
        if (l_step_code<='20' or l_step_code>='30') then /*非早期公開階段*/
              UPDATE appl_catg 
              SET step_code='21',
                  send_back_cnt=3,
                  ASSIGN_DATE=sysdate,
                  processor_no='70014',
                  supervisor_no=null,
                  processor_no_prv=l_processor_no,
                  PROCESSOR_NO_PRV_2='70012'
              where trim(appl_no)=trim(p_APPL_NO);
             l_PROCESSOR_NO:='70014';
        end if;
      end if;
    end if;

	  insert into appl_trans
	  select APPL_TRANS_ID_SEQ.nextval ID,
           appl_no, 
	         p_FUNC_CODE trans_no,
		       step_code step_code_prv,
          case when l_STEP_CODE='25' then '26' 
               when l_step_code>'20' and l_step_code<'30' then l_step_code 
               else '21' end step_code,  ---?
		       trim(p_PROCESSOR_NO) object_from,
		       l_PROCESSOR_NO object_to,
		       trim(p_PROCESSOR_NO) PROCESSOR_NO,
           sysdate TRANS_DATE,
           sysdate ACCEPT_DATE,
		       '程序移它科:'||p_PROCESS_RESULT remark
    from appl
	  where trim(appl_no)=trim(p_APPL_NO);

end;
----------------------------------------
--程序回覆 主程式
----------------------------------------
BEGIN
  if p_FUNC_CODE = '1' then --程序回覆成功
    appl_trans_success;
  else --程序已撤回
    if p_FUNC_CODE = '2' then --程序退辦
      appl_trans_send;
    else
      appl_trans_reject;
    end if;
  end if;
  --回傳更新筆數
  P_OUT_MSG := sql%rowcount;
END SEND_APPL_TO_EARLY_PUBLICATION;

/
