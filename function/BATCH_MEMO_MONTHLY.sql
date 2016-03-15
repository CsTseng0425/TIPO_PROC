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
