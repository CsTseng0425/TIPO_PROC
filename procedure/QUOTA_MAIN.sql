--------------------------------------------------------
--  DDL for Procedure QUOTA_MAIN
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."QUOTA_MAIN" (p_in_year      in number,
                                       p_out_years    out sys_refcursor,
                                       p_out_workdays out sys_refcursor,
                                       p_out_list     out sys_refcursor) is
  g_year number(4);
begin

/*
DESC :计砞﹚
Modify Date : 105/02/01
  --眔さぱ
*/
  open p_out_years for
    SELECT YEAR FROM WORKDAYS 
    WHERE YEAR between  EXTRACT(YEAR FROM SYSDATE) -1 and  EXTRACT(YEAR FROM SYSDATE) +1
    ORDER BY YEAR
    ;

  --  块璝ぃ絛瞅ず玥ㄏノ程(さ)

  SELECT CASE
           WHEN p_in_year BETWEEN MIN(YEAR) AND MAX(YEAR) THEN
            p_in_year
           ELSE
            MIN(YEAR)
         END
    INTO g_year
    FROM WORKDAYS
   WHERE YEAR between  EXTRACT(YEAR FROM SYSDATE) -1 and  EXTRACT(YEAR FROM SYSDATE) +1
   ;

  if g_year is null then
  
    raise_application_error(-20001,
                            'workdays can not be empty , please checkout SPMFF table!');
  end if;

  --  眔ぱ

  open p_out_workdays for
    SELECT YEAR, JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC
      FROM WORKDAYS
     WHERE YEAR = g_year;

  -- preload

  insert into quota
    select processor_no, mm, factor, yyyy
      from spm63,
           (select g_year as yyyy,
                   trim(to_char(level, '00')) mm,
                   0 as factor
              from dual
            connect by level <= 12)
     where dept_no = '70012'
       and quit_date is null
       and yyyy = g_year
       and processor_no not in
           (select distinct processor_no from quota where yyyy = g_year)
      union all
      select processor_no, mm, factor, yyyy
      from spm63,
           (select g_year+1 as yyyy,
                   trim(to_char(level, '00')) mm,
                   0 as factor
              from dual
            connect by level <= 12)
     where dept_no = '70012'
       and quit_date is null
       and yyyy = g_year+1
       and processor_no not in
           (select distinct processor_no from quota where yyyy = g_year+1)
      ;

  insert into quota_base
    select processor_no, 0, g_year as yyyy
      from spm63
     where dept_no = '70012'
       and quit_date is null
       and processor_no not in
           (select distinct processor_no from quota_base where yyyy = g_year)
    union all
    select processor_no, 0, g_year+1 as yyyy
      from spm63
     where dept_no = '70012'
       and quit_date is null
       and processor_no not in
           (select distinct processor_no from quota_base where yyyy = g_year+1)
    ;

  --莱快ン计           

  open p_out_list for
    SELECT PROCESSOR_NO,
           NAME_C,
           BASE,
           "JAN",
           "FEB",
           "MAR",
           "APR",
           "MAY",
           "JUN",
           "JUL",
           "AUG",
           "SEP",
           "OCT",
           "NOV",
           "DEC"
      FROM (SELECT S.PROCESSOR_NO, S.NAME_C, A.YYYY, A.MM, B.BASE, FACTOR
             FROM QUOTA A
              JOIN  QUOTA_BASE B ON  A.PROCESSOR_NO = B.PROCESSOR_NO 
               AND A.YYYY = B.YYYY
              JOIN SPM63 S ON  A.PROCESSOR_NO = S.PROCESSOR_NO
              LEFT JOIN
               (SELECT SUBSTR(DATE_BC, 1, 4) AS YYYY,
                           SUBSTR(DATE_BC, 5, 2) AS MM,
                           SUM(DATE_FLAG) AS WORKDAY
                      FROM SPMFF
                     GROUP BY SUBSTR(DATE_BC, 1, 4), SUBSTR(DATE_BC, 5, 2)) W
                    ON  A.YYYY = W.YYYY   AND A.MM = W.MM
                 WHERE A.YYYY = g_year) PIVOT(SUM(FACTOR) FOR MM IN('01' AS JAN,
                                                                '02' AS FEB,
                                                                '03' AS MAR,
                                                                '04' AS APR,
                                                                '05' AS MAY,
                                                                '06' AS JUN,
                                                                '07' AS JUL,
                                                                '08' AS AUG,
                                                                '09' AS SEP,
                                                                '10' AS OCT,
                                                                '11' AS NOV,
                                                                '12' AS DEC))
     ORDER BY PROCESSOR_NO;

end quota_main;

/
