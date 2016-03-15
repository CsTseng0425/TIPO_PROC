--------------------------------------------------------
--  DDL for Function BATCH_STATUS
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."BATCH_STATUS" (p_batch_no in varchar2)
  return varchar2 is
  v_batch_status varchar2(200);
  l_batch_status varchar2(200);
  CURSOR batch_cursor IS
    select batch_seq || ' ' || process_date || case
             when check_date is null then
              ''
             else
              '/' || check_date || '/' || case
                when process_result = 1 then
                 '通過'
                when process_result = 2 then
                 '允收'
                when process_result = 3 then
                 '拒收'
              end
           end
      from batch
     where batch_no = p_batch_no
     order by batch_seq;
begin

  OPEN batch_cursor;
  LOOP
    FETCH batch_cursor
      INTO v_batch_status;
    EXIT WHEN batch_cursor%NOTFOUND;
    l_batch_status := l_batch_status || v_batch_status || chr(13) ||
                      chr(10);
  
  END LOOP;
  CLOSE batch_cursor;
  return l_batch_status;
exception
  when others then
    return '';
end batch_status;

/
