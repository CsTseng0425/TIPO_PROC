--------------------------------------------------------
--  DDL for Function BATCH_FORMLIST
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."BATCH_FORMLIST" (p_batch_no in varchar2, p_batch_seq in number)
  return varchar2 is
  l_receive_no varchar2(2000);
  v_receive_no varchar2(12);
  CURSOR batch_cursor IS
      select bd.receive_no 
     from batch_detail bd
      join spm56 on bd.receive_no = spm56.receive_no 
      where  bd.batch_no =  p_batch_no
     and bd.batch_seq = p_batch_seq
     and spm56.issue_flag != '2'
     and spm56.form_file_a = (select max(form_file_a) from spm56 s56 where s56.receive_no = spm56.receive_no)
    union all 
      select bd.receive_no 
     from batch_detail bd
     where  bd.batch_no =  p_batch_no
     and bd.batch_seq = p_batch_seq
     and not exists (select 1 from spm56 where  bd.receive_no = spm56.receive_no )
    ;
begin
/*
Desc: check if there are forms exist in spm56 for receives in batch_no
return recive list  which hasn't form or form issue_flag != '1' --發文

*/

  OPEN batch_cursor;
  LOOP
    FETCH batch_cursor
      INTO v_receive_no;
    EXIT WHEN batch_cursor%NOTFOUND;
    l_receive_no := l_receive_no || v_receive_no || ';';
   -- SYS.Dbms_Output.Put_Line('l_receive_no='||l_receive_no);
  END LOOP;
  CLOSE batch_cursor;
  SYS.Dbms_Output.Put_Line('l_receive_no='||l_receive_no);
   if length(l_receive_no)> 0 then
        return substr(l_receive_no,1,600) || ' ...etc 公文未送核';
   else 
        return '';
   end if;
exception
  when others then
    return '';
end batch_FormList;

/
