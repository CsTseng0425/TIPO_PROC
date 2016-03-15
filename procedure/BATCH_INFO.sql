--------------------------------------------------------
--  DDL for Procedure BATCH_INFO
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_INFO" (p_in_batch_no  in varchar2,
                                       p_in_batch_seq in varchar2,
                                       BATCH_NO       out varchar2,
                                       BATCH_SEQ      out varchar2,
                                       STEP_CODE      out varchar2,
                                       COUNT_ALL      out varchar2,
                                       SPOT_CHECK     out varchar2,
                                       COUNT_CHECKED  out varchar2,
                                       COUNT_DEFECT   out varchar2,
                                       CHECK_DATE     out varchar2,
                                       PROCESS_DATE   out varchar2,
                                       PROCESS_RESULT out varchar2) IS
  v_step_code     varchar(2);
  v_count_all     number;
  v_count_defect  number;
  v_count_spot    number;
  v_count_checked number;
  v_result        char(1);
  v_has_checked   number;
/*
  §å¦¸²M³æ:
  104/08/21
*/
BEGIN

  select step_code
    into v_step_code
    from batch
   where batch_no = p_in_batch_no
     and batch_seq = p_in_batch_seq;

  if v_step_code = 1 then
  
    select count(receive_no),
           count(case
                   when IS_CHECK = '1' and IS_DEFECT = '1' then
                    1
                 end),
           SPOT_CHECK_QTY(count(receive_no)),
           count(case
                   when IS_CHECK = '1' then
                    1
                 end),
          count(case
                   when IS_CHECK = '2' then
                    1
                 end)
      into v_count_all, v_count_defect, v_count_spot, v_count_checked ,v_has_checked
      from BATCH_DETAIL
     where batch_no = p_in_batch_no
       and batch_seq = p_in_batch_seq;
     
    if v_count_all - v_has_checked < v_count_spot   then 
        v_count_spot := v_count_all - v_has_checked;
    end if;  
    
  
    if v_count_checked >= v_count_spot or v_count_defect > 0 then
    
      if v_count_defect = 0 then
        v_result := '1';
      elsif v_count_all > 150 and v_count_defect = 1 then
        v_result := '2';
      else
        v_result := '3';
      end if;
    
    else
      v_result := 0;
    
    end if;
    SYS.Dbms_Output.Put_Line(v_count_all || ',' || v_count_defect|| ',' || v_count_spot|| ',' || v_count_checked || ',' ||v_has_checked);
    UPDATE BATCH
       SET Process_result = v_result,
           check_date     = TO_CHAR(TO_NUMBER(TO_CHAR(SYSDATE, 'YYYYMMDD')) -
                                    19110000)
     WHERE batch.batch_seq = p_in_batch_seq
       AND batch.batch_no = p_in_batch_no;
  end if;
 SYS.Dbms_Output.Put_Line('v_result=' || v_result);
  SELECT B1.BATCH_NO,
         B1.BATCH_SEQ,
         B1.STEP_CODE,
         COUNT(D.RECEIVE_NO),
      --   SPOT_CHECK_QTY(COUNT(D.RECEIVE_NO)),
         v_count_spot ,
         COUNT(CASE
                 WHEN IS_CHECK = '1' THEN
                  1
               END),
         COUNT(CASE
                 WHEN IS_CHECK = '1' AND IS_DEFECT = '1' THEN
                  1
               END),
         B1.CHECK_DATE,
         B1.PROCESS_DATE,
         B1.PROCESS_RESULT
    INTO BATCH_NO,
         BATCH_SEQ,
         STEP_CODE,
         COUNT_ALL,
         SPOT_CHECK,
         COUNT_CHECKED,
         COUNT_DEFECT,
         CHECK_DATE,
         PROCESS_DATE,
         PROCESS_RESULT
    FROM BATCH B1
    JOIN BATCH_DETAIL D
      ON B1.BATCH_SEQ = D.BATCH_SEQ
     AND B1.BATCH_NO = D.BATCH_NO
   WHERE B1.BATCH_NO = p_in_batch_no
     AND B1.BATCH_SEQ = p_in_batch_seq
   GROUP BY B1.BATCH_NO,
            B1.STEP_CODE,
            B1.CHECK_DATE,
            B1.PROCESS_DATE,
            B1.PROCESS_RESULT,
            B1.BATCH_SEQ;

  
END BATCH_INFO;

/
