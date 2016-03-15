--------------------------------------------------------
--  DDL for Procedure DASHBOARD_DAIRY_REPORT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."DASHBOARD_DAIRY_REPORT" (
  p_date in out varchar2,
  p_transrdc_success_count out varchar2,
  p_transrdc_failure_count out varchar2,
  p_transrdc_skip_count out varchar2,
  p_uncollected_count out varchar2
) 
is
  v_date_tab varchar2_tab;
begin
  
  p_date := nvl(p_date, to_char(systimestamp - 1, 'yyyymmdd') - 19110000);
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
  
  select count(decode(flag, 'Y', 1, null)),
         count(decode(flag, 'N', 1, null)),
         count(decode(flag, 'D', 1, null))
    into p_transrdc_success_count,
         p_transrdc_failure_count,
         p_transrdc_skip_count
    from transrdc_log a, (
           select receive_no, 
                  max(import_date) over (partition by receive_no) as import_date,
                  max(import_time) over (partition by receive_no, import_date) as import_time
             from transrdc_log
            where import_date in (
                    select column_value as query_date
                      from table(v_date_tab)
                  )
         ) b
   where a.receive_no = b.receive_no
     and a.import_date = b.import_date
     and a.import_time = b.import_time;
  
  select count(distinct receive_no)
    into p_uncollected_count
    from receive
   where not exists (
           select ''
             from doc
            where receive.appl_no = doc.appl_no
              and receive.receive_no = doc.receive_no
         );
  
end dashboard_dairy_report;

/
