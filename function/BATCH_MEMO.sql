--------------------------------------------------------
--  DDL for Function BATCH_MEMO
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."BATCH_MEMO" (p_batch_no in varchar2,p_batch_seq in varchar2)
  return varchar2 is
  v_batch_memo varchar2(200);
  l_batch_memo varchar2(200);
  CURSOR batch_cursor IS
    select '第' || appl_no || '號已於' || CHECK_DATE || '再次查驗合格'
      from batch 
      left join  batch_detail on batch.batch_no = batch_detail.batch_no
     where batch.batch_no = p_batch_no
     and batch.batch_seq = p_batch_seq 
     and batch_detail.batch_seq = p_batch_seq-1
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
end batch_memo;

/
