--------------------------------------------------------
--  DDL for Procedure GET_ANNEX
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."GET_ANNEX" (
  p_in_appl_no in char, 
  p_in_online_flg in char, 
  p_out_annex_code out char, 
  p_out_annex_desc out char)
is
begin
  if p_in_online_flg = 'Y' then
    begin
      select pre_exam_list
        into p_out_annex_code
        from appl
       where appl_no = p_in_appl_no;
    exception
      when no_data_found then null;
    end;
    begin
      select annex_desc
        into p_out_annex_desc
        from appl50
       where appl_no = p_in_appl_no
         and series_no = '38';
    exception
      when no_data_found then null;
    end;
  else
    begin
      select annex_code
        into p_out_annex_code
        from spt50a
       where appl_no = p_in_appl_no;
    exception
      when no_data_found then null;
    end;
    begin
      select annex_desc
        into p_out_annex_desc
        from spt50
       where appl_no = p_in_appl_no
         and series_no = '38';
    exception
      when no_data_found then null;
    end;
  end if;
end get_annex;

/
