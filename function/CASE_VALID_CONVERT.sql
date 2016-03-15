--------------------------------------------------------
--  DDL for Function CASE_VALID_CONVERT
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."CASE_VALID_CONVERT" (p_in_receive_no   in char,
                                              p_in_processor_no in char)
  return varchar2 is
  v_count number;
begin
/*
 Desc : check the receive is valid
 ModifyDate: 104/09/2
 104/07/31: change condition if the receive has accepted
*/

  SELECT COUNT(1)
    INTO v_count
    FROM SPT21
   WHERE SPT21.OBJECT_ID = p_in_processor_no
     AND SPT21.RECEIVE_NO = p_in_receive_no;

  if v_count > 0 then
    --是持有人
     SELECT COUNT(1)
      INTO v_count
      FROM  SPT23 
     WHERE SPT23.OBJECT_TO = p_in_processor_no
       AND SPT23.RECEIVE_NO =  p_in_receive_no
       AND data_seq = (select max(data_seq) from spt23 s23 where spt23.receive_no = s23.receive_no)  
       AND SPT23.ACCEPT_DATE IS NULL
       AND SPT23.OBJECT_TO !=  '98888'
       ;
     
  
    if v_count > 0 then
      return '文未簽收';
    end if;
  
  else
    --不是持有人
    SELECT COUNT(1)
      INTO v_count
      FROM  SPT72
     WHERE SPT72.trans_seq = (select max(trans_seq) from spt72 s72 where s72.appl_no = SPT72.appl_no)
       AND SPT72.ACCEPT_DATE IS NULL
       AND SPT72.OBJECT_TO =  p_in_processor_no
       AND SPT72.APPL_NO = (select appl_no from spt21 where receive_no =   p_in_receive_no
       )
       ;
  
    if v_count > 0 then
      return '卷未簽收';
    end if;
  
   
  end if;

  SELECT COUNT(1)
    INTO v_count
    FROM SPT21
   WHERE RECEIVE_NO = p_in_receive_no
     AND PROCESS_RESULT IS NOT NULL;

  if v_count > 0 then
    return '文已辦結';
  end if;

  return '';
end case_valid_convert;

/
