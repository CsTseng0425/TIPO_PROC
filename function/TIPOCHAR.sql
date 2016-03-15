--------------------------------------------------------
--  DDL for Function TIPOCHAR
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."TIPOCHAR" (p_data in varchar2) RETURN VARCHAR2 AS 
i long;
v_char_tipo ap.spm77.char_tipo%type;
v_char_unicode ap.spm77.char_unicode%type;
v_data varchar2(2000):='';
BEGIN
   For i In 1..length(trim(p_data)) Loop
     --
     v_char_tipo:=substr(p_data,i,1);
     v_char_unicode:=null;
     
     begin
       --將可能包含自造字之文字轉換為標準UNICODE文字
       SELECT char_unicode INTO v_char_unicode FROM ap.spm77
       WHERE char_tipo=v_char_tipo
       AND trim(char_unicode) is not null
       and rownum=1
       ;     
        v_data:=v_data||v_char_unicode;
     exception
     when no_data_found then    
        v_data:=v_data||substr(p_data,i,1);
     end;
   End Loop;
   --SYS.Dbms_Output.Put_Line(''''||v_date||'''');
  RETURN v_data;
/*
exception
when others then
  RETURN p_data;
   --raise_application_error (-20002,'An error has occurred converting tipo char to unicode char.');
*/
END TIPOCHAR;

/
