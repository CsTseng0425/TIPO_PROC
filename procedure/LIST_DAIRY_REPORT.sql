--------------------------------------------------------
--  DDL for Procedure LIST_DAIRY_REPORT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."LIST_DAIRY_REPORT" (
  p_date in varchar2,
  p_type in varchar2,
  p_list out sys_refcursor
) 
is
  v_date_tab varchar2_tab;
begin
  
  select date_bc
    bulk collect
    into v_date_tab
    from spmff
   where date_chinese >= (
             select max(date_chinese)
               from spmff
              where date_chinese <= p_date
                and date_flag = '1'
         )
     and date_chinese <= p_date;
  if v_date_tab.count = 0 then
    v_date_tab.extend;
    v_date_tab(v_date_tab.last) := p_date + 19110000;
  end if;
  
  if p_type in ('TRANSRDC_SUCCESS', 'TRANSRDC_FAILURE', 'TRANSRDC_SKIP') then
    open p_list for
      select a.receive_no,
             a.appl_no,
             c.receive_date,
             c.type_no || ' ' || d.type_name
        from transrdc_log a
        join (select receive_no, 
                     max(import_date) over (partition by receive_no) as import_date,
                     max(import_time) over (partition by receive_no, import_date) as import_time
                from transrdc_log
               where import_date in (
                       select column_value as query_date
                         from table(v_date_tab)
                     )
             ) b
          on a.receive_no = b.receive_no
             and a.import_date = b.import_date
             and a.import_time = b.import_time
        left join spt21 c
          on a.receive_no = c.receive_no 
             and a.appl_no = c.appl_no
        left join spm75 d
          on c.type_no = d.type_no
       where a.flag = case p_type 
                        when 'TRANSRDC_SUCCESS' then 'Y'
                        when 'TRANSRDC_FAILURE' then 'N'
                        when 'TRANSRDC_SKIP' then 'D'
                        else null
                      end
       order by c.receive_date, a.receive_no;
    return;
  elsif p_type = 'UNCOLLECTED' then
    open p_list for
      select a.receive_no,
             a.appl_no,
             c.receive_date,
             c.type_no || ' ' || d.type_name as type_name
        from receive a, spt21 c, spm75 d
       where a.receive_no = c.receive_no
         and c.type_no = d.type_no(+)
         and not exists (
               select ''
                 from doc b
                where a.appl_no = b.appl_no
                  and a.receive_no = b.receive_no
             )
       order by c.receive_date, a.receive_no;
    return;
  end if;
  raise_application_error(-20001,
                          'please check your p_type parameter, maybe not in list_dairy_report procedure!');
end list_dairy_report;

/
