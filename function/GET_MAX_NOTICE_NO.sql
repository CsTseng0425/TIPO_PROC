--------------------------------------------------------
--  DDL for Function GET_MAX_NOTICE_NO
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."GET_MAX_NOTICE_NO" (p_notice_data in date) RETURN VARCHAR2 AS 
v_Notice_No_E ap.spt81a.Notice_No_E%type;
BEGIN
    select nvl(max(Notice_No_E),
               to_char(p_notice_data,'YYYY')||'00000') max_notice_no into v_Notice_No_E
    from spt81a 
    where substr(notice_date,1,3)=to_char(to_char(p_notice_data,'YYYY')-1911)
    ;
  RETURN v_Notice_No_E;
END get_max_notice_no;

/
