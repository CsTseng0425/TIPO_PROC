--------------------------------------------------------
--  DDL for Function CASE_VALID_PROCESS
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."CASE_VALID_PROCESS" (p_no in char)
return number
is
  v_state         number  := 1;
  v_is_receive_no boolean := false;
  v_is_appl_no    boolean := false;
  v_appl_no       char(15);
  v_sc_flag       spt31.sc_flag%type;
  v_count         number;
begin
  if v_state = 1 then
    begin
      select appl_no
        into v_appl_no
        from spt21
       where receive_no = p_no;
      v_is_receive_no := true;
      v_state := 0;
    exception
      when no_data_found then null;
    end;
  end if;
  if v_state = 1 then
    begin
      select appl_no
        into v_appl_no
        from spt31
       where appl_no = p_no;
      v_is_appl_no := true;
      v_state := 0;
    exception
      when no_data_found then null;
    end;
  end if;
  if v_state = 0 then
    select sc_flag
      into v_sc_flag
      from spt31
     where appl_no = v_appl_no;
    if v_sc_flag = 1 then
      v_state := 2;
    end if;
  end if;
  -----------------------------
  -- 2015/12/12 逕予審查: 
  -- 指定案件中: 線上公文需全部已監印; 紙本公文需全部已銷號
  -- 調高線上公文已監印的條件
  -- 106/01/27: 辦理結果為40307併辦的文,不用檢核是否已監印
  -- 106/03/09: 調整未監印條件
  -----------------------------
  if v_state = 0 and v_is_appl_no then
    select count(1)
      into v_count
      from spt21 left join spt41 on spt21.receive_no = spt41.receive_no
     where spt21.appl_no = v_appl_no
         and (( spt21.process_result is null and  spt21.online_flg = 'N')
         or  ( online_flg='Y' 
                 and (spt21.process_result != '40307' or spt21.process_result is null)
         and   (spt41.check_datetime is  null or spt41.receive_no is null)
          )
       );
       
    if v_count > 0 then
      v_state := 3;
    end if;
  end if;
  
  return v_state;
end case_valid_process;

/
