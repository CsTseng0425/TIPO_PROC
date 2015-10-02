
  CREATE OR REPLACE FORCE VIEW "S193"."WORKDAYS" ("YEAR", "JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC") AS 
  select "YEAR","JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC" from (
    select extract(year from to_date(DATE_BC, 'yyyymmdd')) as year , extract(month from to_date(DATE_BC, 'yyyymmdd')) as month, sum(DATE_FLAG) as workday　
      from spmff
      group by extract(year from to_date(DATE_BC, 'yyyymmdd')), extract(month from to_date(DATE_BC, 'yyyymmdd'))
      order by month
)
pivot
(
   sum(workday)
   for month in ('01' AS JAN, '02' AS FEB, '03' AS MAR, '04' AS APR, '05' AS MAY,
    '06' AS JUN, '07' AS JUL, '08' AS AUG, '09' AS SEP, '10' AS OCT, '11' AS NOV, '12' AS DEC)
);
