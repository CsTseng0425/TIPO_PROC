--------------------------------------------------------
--  DDL for Procedure CHECK_UNPOSTPONE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."CHECK_UNPOSTPONE" ( p_rec out int)
is
    ecode            number;
    ap_code          varchar2(10);
    p_msg            varchar2(100);
    l_receive_no     receive.receive_no%type;
    l_processor_no   receive.processor_no%type;
    l_is_postpone    receive.is_postpone%type;
    l_exist          number;
    cnt              number;
    CURSOR receive_cursor IS
    select receive_no, processor_no ,is_postpone
      from receive
     where  receive.is_postpone in ( '1','2','3')
     order by receive_no;
 
 /* ModifyDate : 201/01/21
 201/01/21: 針對緩辦項目進行判斷移-來文:1, 等規費:2, 等圖:3
 */
 ---------------------------
 -- 移除緩辦- 等後續文
 ---------------------------------
PROCEDURE Check_Case1(p_receive_no in char,p_processor_no in char, p_is_exist out number)
  -- 
  is

BEGIN
     ap_code := 'case1';
   
     select count(1) into p_is_exist
     from receive
     where appl_no = ( select appl_no from receive where receive_no = p_receive_no)
     and receive_no > p_receive_no
     and step_code = '2'
     and processor_no = p_processor_no
     ;
  
 --   dbms_output.put_line('新案,逾期:');
 
END Check_Case1;
  
 ---------------------------
 -- 移除緩辦- 等規費
 ---------------------------------
   
  PROCEDURE Check_Case2(p_receive_no in char, p_is_exist out number)
  --
  is

  BEGIN
   ap_code := 'case2';
  
     select count(1) into p_is_exist
     from spt13
     where NUMBER_TYPE = 'A' -- 收文
     and receive_no = p_receive_no;
 
  END Check_Case2;
 
 -------------------------
 -- wait for document
 -------------------------
  PROCEDURE Check_Case3(p_receive_no in char, p_is_exist out number)
  --
  is

  BEGIN
   ap_code := 'case3';
   
     select count(1) into p_is_exist from DOC_IMPORT_LOG
     where import_date > (select to_number(nvl(para_no,'0')) - 19110000   from appl_para where sys = 'POSTPONE' and (subsys) = trim(p_receive_no) )
     and (receive_no) = trim(p_receive_no)
     ;
   
  END Check_Case3;    

BEGIN

  p_rec :=0;
 
  OPEN receive_cursor;
  LOOP
    FETCH receive_cursor
      INTO l_receive_no , l_processor_no , l_is_postpone;
    EXIT WHEN receive_cursor%NOTFOUND;
      -- initial
       l_exist :=0;
       cnt :=0;
      
       if l_is_postpone = '1' then
           check_case1(l_receive_no,l_processor_no,l_exist);
          if nvl(l_exist,0) > 0 then
              update receive set  is_postpone  = '0' ,	POST_REASON	 = '等來文可移除' where receive_no =l_receive_no   ;
              p_rec := SQL%RowCount;
          end if;
       end if;
       
       if l_is_postpone = '2' then
           check_case2(l_receive_no,l_exist);
          if nvl(l_exist,0) > 0 then
              update receive set  is_postpone  = '0' ,	POST_REASON	 = '等規費可移除' where receive_no =l_receive_no   ;
              p_rec := SQL%RowCount;
          end if;
       end if;
       
      if l_is_postpone = '3' then
           
           check_case3(l_receive_no,l_exist);
           
          if nvl(l_exist,0) > 0 then
                update receive set  is_postpone  = '0' ,	POST_REASON	 = '等圖檔可移除' where receive_no =l_receive_no   ;
                 p_rec := SQL%RowCount;
          end if;
       end if;
       
             
      
  END LOOP;
  CLOSE receive_cursor;
  
  
     
        
   commit;
  
   dbms_output.put_line('Finish!!' || p_rec);
EXCEPTION
  WHEN OTHERS THEN
   ecode := SQLCODE;
   p_msg := ap_code || ':' || SQLCODE || ':' || SQLERRM; 
    dbms_output.put_line('Error Code:' || ecode || '; Error Message:' || p_msg);
END CHECK_UNPOSTPONE;

/
