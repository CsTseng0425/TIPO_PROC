--------------------------------------------------------
--  DDL for Procedure LIST_PERFORMANCE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."LIST_PERFORMANCE" (
  p_in_year in varchar2,
  p_in_processor_no in varchar2,
  p_out_list out sys_refcursor) 
is
  l_yyyymm varchar2(6);
/* desc: 年度績效 Performance Yearly
   ModifyDate : 104/10/16
   ModityItem: online receive dated by close date of form signed ( receive.sign_date)
   104/10/16: add ALL_ACC
   104/02/01: change minimum year 
*/
begin    

  select min(yyyy||mm) into l_yyyymm from quota;
  
  if l_yyyymm is null then 
       l_yyyymm  := '201601';
  end if;
  
  OPEN p_out_list FOR  
  SELECT  A.PROCESSOR_NO, A.NAME_C,
          (A.JAN || '*' || NVL(B.JAN,0)) AS T1 ,
          (A.FEB || '*' || NVL(B.FEB,0) ) AS T2 ,
          (A.MAR || '*' || NVL(B.MAR,0) ) AS T3 ,
          (A.APR || '*' || NVL(B.APR,0) ) AS T4 ,
          (A.MAY || '*' || NVL(B.MAY,0) ) AS T5 ,
          (A.JUN || '*' || NVL(B.JUN,0) ) AS T6 ,
          (A.JUL || '*' || NVL(B.JUL,0) ) AS T7 ,
          (A.AUG || '*' || NVL(B.AUG,0) ) AS T8 ,
          (A.SEP || '*' || NVL(B.SEP,0) ) AS T9 ,
          (A.OCT || '*' || NVL(B.OCT,0)) AS T10,
          (A.NOV || '*' || NVL(B.NOV,0)) AS T11,
          (A.DEC || '*' || NVL(B.DEC,0)) AS T12,
          nvl(C.ALL_ACC,0) ALL_ACC
  FROM (
    SELECT TRIM(PROCESSOR_NO) AS PROCESSOR_NO, NAME_C, "JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC" FROM (
      SELECT A.PROCESSOR_NO, S.NAME_C, A.YYYY , A.MM, (BASE * WORKDAY + FACTOR) AS QUOTA
      FROM QUOTA A, QUOTA_BASE B, SPM63 S,
        (
          SELECT SUBSTR(DATE_BC,1,4) AS YYYY, SUBSTR(DATE_BC,5,2) AS MM, SUM(DATE_FLAG) AS WORKDAY
          FROM SPMFF
          GROUP BY SUBSTR(DATE_BC,1,4), SUBSTR(DATE_BC,5,2)
        ) W
      WHERE A.PROCESSOR_NO=B.PROCESSOR_NO AND A.YYYY=B.YYYY
            AND A.PROCESSOR_NO=S.PROCESSOR_NO
            AND A.YYYY=W.YYYY AND A.MM=W.MM
            AND A.YYYY=p_in_year
      ORDER BY A.MM
    )
    PIVOT
    (
       SUM(QUOTA)
       FOR MM IN ('01' AS JAN, '02' AS FEB, '03' AS MAR, '04' AS APR, '05' AS MAY,
        '06' AS JUN, '07' AS JUL, '08' AS AUG, '09' AS SEP, '10' AS OCT, '11' AS NOV, '12' AS DEC)
    )
  ) A
  LEFT JOIN
  (
    SELECT TRIM(PROCESSOR_NO) AS PROCESSOR_NO, NAME_C, "JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC" FROM (
      SELECT W.PROCESSOR_NO, S.NAME_C, W.YYYY , W.MM,  QUOTA
      FROM  SPM63 S
      LEFT JOIN
        (
          select processor_no,
                substr(to_char(to_number(sign_date) + 19110000),1,4) YYYY,
                substr(to_char(to_number(sign_date) + 19110000),5,2) MM,
                count(1)  AS QUOTA
            from receive 
            where receive.step_code = '8'
            group by  substr(to_char(to_number(sign_date) + 19110000),1,4) ,
              substr(to_char(to_number(sign_date) + 19110000),5,2) ,
              processor_no 
        ) W
        ON  W.PROCESSOR_NO=S.PROCESSOR_NO
      WHERE  W.YYYY=p_in_year
      ORDER BY W.MM
    )
    PIVOT
    (
       SUM(QUOTA)
       FOR MM IN ('01' AS JAN, '02' AS FEB, '03' AS MAR, '04' AS APR, '05' AS MAY,
        '06' AS JUN, '07' AS JUL, '08' AS AUG, '09' AS SEP, '10' AS OCT, '11' AS NOV, '12' AS DEC)
    )
  ) B   ON A.PROCESSOR_NO = B.PROCESSOR_NO
  LEFT JOIN
  (
    SELECT  r.processor_no,  nvl(c.s,0) -  nvl(r.d,0)  as  ALL_ACC -- 迄今累計
      FROM (
           SELECT a.processor_no,  sum(nvl(b.base, 0) * nvl(mday.days, 0) + nvl(a.factor, 0)) d
            FROM quota a
            JOIN quota_base b
              on a.processor_no = b.processor_no
             AND a.yyyy = b.yyyy
            LEFT JOIN (SELECT substr(date_bc, 1, 6) yyyymm, count(1) days
                        FROM spmff
                       WHERE date_flag = 1
                       group by substr(date_bc, 1, 6)) mday
              on mday.yyyymm = b.yyyy || a.mm
           where  a.yyyy || a.mm >=  l_yyyymm
            and a.yyyy || a.mm <= (case when p_in_year <  to_char(sysdate,'yyyy') then p_in_year || '12' else to_char(sysdate,'yyyyMM')  end  )
            and trim(a.processor_no) in (select processor_no from spm63 where dept_no = '70012' and quit_date is  null)
            group by a.processor_no
            ) r
          left join 
          (
        select processor_no,  nvl(sum(1),0) s
        from receive
        where step_code = '8'
         AND substr(to_char(to_number(sign_date) + 19110000),1,6) >=  l_yyyymm
         AND substr(to_char(to_number(sign_date) + 19110000),1,6)  <= (case when p_in_year <  to_char(sysdate,'yyyy') then p_in_year || '12' else to_char(sysdate,'yyyyMM')  end  )
        AND not exists ( select 1 from spt21 where spt21.receive_no = RECEIVE.receive_no and spt21.process_result = '57001') 
        group by processor_no
          )  c  on trim(r.processor_no) = trim(c.processor_no)
  
  ) C  on  trim(A.PROCESSOR_NO) = trim(C.PROCESSOR_NO)
  WHERE  A.PROCESSOR_NO = NVL(p_in_processor_no, A.PROCESSOR_NO)      
  ORDER BY A.PROCESSOR_NO;
  
end LIST_PERFORMANCE;

/
