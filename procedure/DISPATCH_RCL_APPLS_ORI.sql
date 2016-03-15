--------------------------------------------------------
--  DDL for Procedure DISPATCH_RCL_APPLS_ORI
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."DISPATCH_RCL_APPLS_ORI" (P_OUT_MSG out number,p_out_list     out sys_refcursor) 
is
l_rcl_version_no CHAR(6):=null;

/*更新SPM21B*/
PROCEDURE UPDATE_SPM21B
AS
BEGIN
  --刪除公開版IPC
  delete from spm21b
  where ROWID in (
    select spm21b.ROWID
      from spm21b,IPC_TRACE
     where IPC_TRACE.VERSION_NO=l_rcl_version_no
       and spm21b.appl_no=IPC_TRACE.appl_no
       and spm21b.step_code='B'
       and Ipc_Trace.Processor_No='A6119' and IPC_TRACE.NOTICE_STATUS ='7')
    ;
  --刪除公告版IPC
  delete from spm21b
  where ROWID in (
    select spm21b.ROWID
      from spm21b,IPC_TRACE
     where IPC_TRACE.VERSION_NO=l_rcl_version_no
       and spm21b.appl_no=IPC_TRACE.appl_no
       and spm21b.step_code='V'
       and Ipc_Trace.Processor_No='A6119' and IPC_TRACE.NOTICE_STATUS ='8')
    ;
  --更新公開版IPC
  insert into spm21b
  select s.appl_no,'B' step_code,s.DATA_SEQ,s.DATA_SEQ SORT_ID,s.IPC_CODE_MS_NEW IPC_CODE_MS,s.IPC_CODE_DT_NEW IPC_CODE_DT,VERSION_NO_NEW VERSION_NO,s.IPC_REF_TYPE
    from IPC_TRACE_LIST s,IPC_TRACE t
   where s.VERSION_NO=l_rcl_version_no and s.VERSION_NO=t.VERSION_NO
     and s.appl_no=t.appl_no
     and t.Processor_No='A6119' and t.NOTICE_STATUS = '7' /*and s.DEL_FLAG='1'*/
     and t.S_FLAG='0'
     ;
  --更新公告版IPC
  insert into spm21b
  select s.appl_no,'V' step_code,s.DATA_SEQ,s.DATA_SEQ SORT_ID,s.IPC_CODE_MS_NEW IPC_CODE_MS,s.IPC_CODE_DT_NEW IPC_CODE_DT,VERSION_NO_NEW VERSION_NO,s.IPC_REF_TYPE
    from IPC_TRACE_LIST s,IPC_TRACE t
   where s.VERSION_NO=l_rcl_version_no and s.VERSION_NO=t.VERSION_NO
     and s.appl_no=t.appl_no
     and t.Processor_No='A6119' and t.NOTICE_STATUS = '8' /*and s.DEL_FLAG='1'*/
     and t.S_FLAG='0'
     ;      
END;

/*更新SPM21*/
PROCEDURE UPDATE_SPM21
AS
BEGIN
  merge into spm21 d
     using (
        select s.APPL_NO,
               s.DATA_SEQ,
               s.IPC_CODE_MS_NEW,
               s.IPC_CODE_DT_NEW,
               s.VERSION_NO_NEW
          from IPC_TRACE_LIST s,IPC_TRACE t
         where s.VERSION_NO=l_rcl_version_no 
           and s.VERSION_NO=t.VERSION_NO
           and s.appl_no=t.appl_no
           and t.Processor_No='A6119' and t.NOTICE_STATUS in ('7','8')
           and t.S_FLAG='0' and s.DEL_FLAG='1') s
        on ( d.appl_no=s.appl_no and d.DATA_SEQ=s.DATA_SEQ)
  when Matched then
  update set 
       d.IPC_CODE_MS_PRV=s.IPC_CODE_MS_NEW,
       d.IPC_CODE_DT_PRV=s.IPC_CODE_DT_NEW,
       d.VERSION_NO_PRV=s.VERSION_NO_NEW,
       d.IPC_CODE_MS=s.IPC_CODE_MS_NEW,
       d.IPC_CODE_DT=s.IPC_CODE_DT_NEW,
       d.VERSION_NO=s.VERSION_NO_NEW
    ;
END;
/*更新SPM21C*/
PROCEDURE UPDATE_SPM21C
AS
BEGIN
  merge into spm21c d
     using (
        select s.APPL_NO,
               s.DATA_SEQ,
               s.DATA_SEQ SORT_ID,
               s.IPC_CODE_MS_NEW,
               s.IPC_CODE_DT_NEW,
               s.VERSION_NO_NEW
          from IPC_TRACE_LIST s,IPC_TRACE t
         where s.VERSION_NO=l_rcl_version_no 
           and s.VERSION_NO=t.VERSION_NO
           and s.appl_no=t.appl_no
           and t.NOTICE_STATUS='9'
           and t.S_FLAG='1' and s.DEL_FLAG='1') s
        on ( d.appl_no=s.appl_no and d.DATA_SEQ=s.DATA_SEQ)
  when Matched then
  update set 
       d.IPC_CODE_MS=s.IPC_CODE_MS_NEW,
       d.IPC_CODE_DT=s.IPC_CODE_DT_NEW,
       d.VERSION_NO=s.VERSION_NO_NEW
    ;
END;

/*備份IPC*/
PROCEDURE BACKUP_IPC
AS
BEGIN
  delete from tmp_spm21;  --TRUNCATE table tmp_spm21;
  delete from tmp_spm21b; --TRUNCATE table tmp_spm21b;
  delete from tmp_spm21c; --TRUNCATE table tmp_spm21c;
  
  insert into tmp_spm21
  select spm21.*
    from spm21,IPC_TRACE
   where IPC_TRACE.VERSION_NO=l_rcl_version_no
     and spm21.appl_no=IPC_TRACE.appl_no
     ;
  
  insert into tmp_spm21b
  select spm21b.*
    from spm21b,IPC_TRACE
   where IPC_TRACE.VERSION_NO=l_rcl_version_no
     and spm21b.appl_no=IPC_TRACE.appl_no
     --and spm21b.step_code='B'
     ;
  
  
  insert into tmp_spm21c
  select spm21c.*
    from spm21c,IPC_TRACE
   where IPC_TRACE.VERSION_NO=l_rcl_version_no
     and spm21c.appl_no=IPC_TRACE.appl_no
     ;
END;

/*建立回溯清單大項*/
PROCEDURE BUILD_IPC_TRACE
as
begin
  insert into IPC_TRACE
  with spm22_t as ((
      select spm22.IPC_CODE_MS,spm22.IPC_CODE_DT,spm22.VERSION_NO from spm22
      left join rcl_detail on rcl_detail.VERSION_NO=l_rcl_version_no 
                          and spm22.IPC_CODE_MS=rcl_detail.IPC_CODE_MS_PRV 
                          and spm22.IPC_CODE_DT=rcl_detail.IPC_CODE_DT_PRV
      where M_FLAG is not null 
      and spm22.VERSION_NO<l_rcl_version_no
      and rcl_detail.VERSION_NO is null
      and spm22.VERSION_NO is not null
    )union(
      select IPC_CODE_MS_PRV IPC_CODE_MS,IPC_CODE_DT_PRV IPC_CODE_DT,'0' VERSION_NO from rcl_detail
      where VERSION_NO=l_rcl_version_no
      and IPC_CODE_MS_PRV is not null
      and IPC_CODE_DT_PRV is not null
    )
  ),ipc_rcl_appl as( --找尋回溯案件
    select appl_no,ipc_processor_no,FIRST_DEPT_NO,PATENT_CLASS,PRV_FLAG,PHYSICAL_FLAG,NOTICE_STATUS,IPC_TYPE,S_FLAG,M_VERSION_NO from(
      select spt31.appl_no,
             spt31.ipc_processor_no,
             spt31.FIRST_DEPT_NO,
             case when spt31.PATENT_CLASS in ('1','2','4','5','6') then spt31.PATENT_CLASS else null end PATENT_CLASS,
             case when substr(spt31a.step_code,1,1) in ('2','4','6') and spt41.issue_no is null then 1 else 0 end PHYSICAL_FLAG, --實審未發審定書
             case when spt31b.STEP_CODE<='60' and (spt82.NOTICE_NO_2 is null or spt82.NOTICE_NO_2='0'  or spt82.NOTICE_DATE_2>TODAY) then appl_21.PRV_FLAG --待公開
                  when (spt31b.STEP_CODE>='50' or substr(spt31.appl_no,4,1)='2') and (spt82.NOTICE_NO is null or spt82.NOTICE_NO='0' or spt82.NOTICE_DATE>TODAY) then appl_21.PRV_FLAG --待公告
                  when (spt31b.STEP_CODE>='50' and spt82.NOTICE_NO_2 >'0' or substr(spt31.appl_no,4,1)='2') and spt82.NOTICE_NO >'0'  then nvl(appl_21c.PRV_FLAG,appl_21.PRV_FLAG) --已公開已公告
                  else null end PRV_FLAG,
             case when spt31b.STEP_CODE<='60' and (spt82.NOTICE_NO_2 is null or spt82.NOTICE_NO_2='0'  or spt82.NOTICE_DATE_2>TODAY) then '0' --待公開
                  when (spt31b.STEP_CODE>='50' or substr(spt31.appl_no,4,1)='2') and (spt82.NOTICE_NO is null or spt82.NOTICE_NO='0' or spt82.NOTICE_DATE>TODAY) then '1' --待公告
                  when (spt31b.STEP_CODE>='50' and spt82.NOTICE_NO_2 >'0' or substr(spt31.appl_no,4,1)='2') and spt82.NOTICE_NO >'0' then '2' --已公開已公告
                  else null end NOTICE_STATUS,
             case when spm21c.appl_no is not null then substr(spm21c.IPC_CODE_MS,1,1)
                  when spm21.appl_no is not null then substr(spm21.IPC_CODE_MS_PRV,1,1)
                  else null end IPC_TYPE,
             case when appl_21.appl_no is not null and (nvl(NOTICE_NO_2,'0')='0' or nvl(NOTICE_NO,'0')='0' or NOTICE_NO >'0' and (NOTICE_NO_2 >'0' or substr(spt31.appl_no,4,1)='2') and appl_21c.appl_no is null) then '0'
                  when NOTICE_NO >'0' and (NOTICE_NO_2 >'0' or substr(spt31.appl_no,4,1)='2') and appl_21c.appl_no is not null then '1'
                  else null end S_FLAG,
             case when appl_21.appl_no is not null and (nvl(NOTICE_NO_2,'0')='0' or nvl(NOTICE_NO,'0')='0' or NOTICE_NO >'0' and (NOTICE_NO_2 >'0' or substr(spt31.appl_no,4,1)='2') and appl_21c.appl_no is null) then (
                       select max(version_no_prv) from spm21 where appl_no=spt31.appl_no)
                  when NOTICE_NO >'0' and (NOTICE_NO_2 >'0' or substr(spt31.appl_no,4,1)='2') and appl_21c.appl_no is not null then (
                       select max(version_no) from spm21c where appl_no=spt31.appl_no)
                  else null end M_VERSION_NO,
             row_number() over (partition by spt31.appl_no order by spt41.FORM_FILE_A desc) as rn
        from spt31
        left join spt31b on spt31.APPL_NO=spt31b.APPL_NO
        left join spt82 on spt31.APPL_NO=spt82.APPL_NO
        left join (
                select APPL_NO,PRV_FLAG
                from(
                  select APPL_NO,PRV_FLAG ,row_number() over (partition by APPL_NO order by PRV_FLAG) as rn
                  from(
                           select distinct APPL_NO,decode(spm22_t.VERSION_NO,'0',0,1) PRV_FLAG 
                             from spm21c,spm22_t
                            where substr(appl_no,4,1) in ('1','2')
                              and spm21c.IPC_CODE_MS=spm22_t.IPC_CODE_MS 
                              and spm21c.IPC_CODE_DT=spm22_t.IPC_CODE_DT 
                              and (spm22_t.VERSION_NO='0' or spm21c.VERSION_NO=spm22_t.VERSION_NO)
                              and spm21c.VERSION_NO<l_rcl_version_no
                  )
                )where rn=1
             ) appl_21c on spt31.APPL_NO=appl_21c.APPL_NO
        left join (
               select APPL_NO,PRV_FLAG
               from(
                  select APPL_NO,PRV_FLAG ,row_number() over (partition by APPL_NO order by PRV_FLAG) as rn
                  from(
                         select distinct APPL_NO,decode(spm22_t.VERSION_NO,'0',0,1) PRV_FLAG 
                           from spm21,spm22_t
                          where substr(appl_no,4,1) in ('1','2')
                            and (      spm21.IPC_CODE_MS_PRV=spm22_t.IPC_CODE_MS 
                                   and spm21.IPC_CODE_DT_PRV=spm22_t.IPC_CODE_DT 
                                   and (spm22_t.VERSION_NO='0' or spm21.VERSION_NO_PRV=spm22_t.VERSION_NO)
                                   and spm21.VERSION_NO_PRV<l_rcl_version_no
                                or     spm21.IPC_CODE_MS=spm22_t.IPC_CODE_MS 
                                   and spm21.IPC_CODE_DT=spm22_t.IPC_CODE_DT 
                                   and (spm22_t.VERSION_NO='0' or spm21.VERSION_NO=spm22_t.VERSION_NO)
                                   and spm21.VERSION_NO<l_rcl_version_no)
                  )
               )where rn=1      
             ) appl_21 on spt31.APPL_NO=appl_21.APPL_NO
        left join spm21c on spt31.appl_no=spm21c.appl_no and spm21c.DATA_SEQ='1'
        left join spm21 on spt31.appl_no=spm21.appl_no and spm21.DATA_SEQ='1'
        left join spt31a on spt31.appl_no=spt31a.APPL_NO 
        left join spt41 on spt31a.APPL_NO=spt41.APPL_NO and spt41.process_result in ('56001','56003','56097') and (trim(spt41.file_d_flag) is null  or spt41.file_d_flag<>'9') /*已發審定書*/
        left join (select TO_CHAR(TO_NUMBER(TO_CHAR(sysdate, 'YYYYMMDD')) - 19110000) TODAY from dual) on 1=1
      where (spt31b.STEP_CODE>='30' and spt31b.STEP_CODE<='60' or substr(spt31.appl_no,4,1)='2' and spt31a.step_code >='15' and spt31a.step_code<'70')
        and (appl_21.appl_no is not null and (nvl(NOTICE_NO_2,'0')='0' or nvl(NOTICE_NO,'0')='0' or NOTICE_NO >'0' and (NOTICE_NO_2 >'0' or substr(spt31.appl_no,4,1)='2') and appl_21c.appl_no is null) 
             or NOTICE_NO >'0' and (NOTICE_NO_2 >'0' or substr(spt31.appl_no,4,1)='2') and appl_21c.appl_no is not null)
        and spt31.BACK_CODE is null and spt31.sc_flag='0' and spt31.PUBLIC_FLAG is null
      )where rn=1 
  ), tmp_appl as( --找尋1-1回溯案件
    select appl_no
    from(
      select APPL_NO,M_VERSION_NO
             ,count(case when IPC_CODE_MS_NEW is not null then 1 else null end) m_count
             ,count(case when IPC_CODE_MS_NEW is null and M_FLAG is not null then 1 else null end) d_count
      from (
        select 
        a.APPL_NO,
        a.M_VERSION_NO,
        decode(a.s_flag,'1',spm21c.DATA_SEQ,spm21.DATA_SEQ) DATA_SEQ_PRV,
        decode(a.s_flag,'1',spm21c.IPC_CODE_MS,spm21.IPC_CODE_MS_PRV) IPC_CODE_MS_PRV,
        decode(a.s_flag,'1',spm21c.IPC_CODE_DT,spm21.IPC_CODE_DT_PRV) IPC_CODE_DT_PRV,
        decode(a.s_flag,'1',spm21c.VERSION_NO,spm21.VERSION_NO_PRV) VERSION_NO_PRV,
        rcl_detail.IPC_CODE_MS_NEW,
        spm22.M_FLAG
        from ipc_rcl_appl a
        left join spm21c on a.appl_no=spm21c.appl_no and a.s_flag='1'
        left join spm21 on a.appl_no=spm21.appl_no and a.s_flag='0'
        left join rcl_detail on rcl_detail.VERSION_NO=l_rcl_version_no and (spm21c.IPC_CODE_MS=rcl_detail.IPC_CODE_MS_PRV 
                                and spm21c.IPC_CODE_DT=rcl_detail.IPC_CODE_DT_PRV 
                                and spm21c.VERSION_NO<l_rcl_version_no 
                                or
                                spm21.IPC_CODE_MS_PRV=rcl_detail.IPC_CODE_MS_PRV 
                                and spm21.IPC_CODE_DT_PRV=rcl_detail.IPC_CODE_DT_PRV 
                                and spm21.VERSION_NO_PRV<l_rcl_version_no)
        left join spm22 on spm22.M_FLAG is not null and (spm21c.IPC_CODE_MS=spm22.IPC_CODE_MS
                                and spm21c.IPC_CODE_DT=spm22.IPC_CODE_DT 
                                and spm21c.VERSION_NO=spm22.VERSION_NO
                                or
                                spm21.IPC_CODE_MS_PRV=spm22.IPC_CODE_MS
                                and spm21.IPC_CODE_DT_PRV=spm22.IPC_CODE_DT
                                and spm21.VERSION_NO_PRV=spm22.VERSION_NO)
        where (spm21c.appl_no is not null or spm21.appl_no is not null)
      )
      group by APPL_NO,M_VERSION_NO,DATA_SEQ_PRV,IPC_CODE_MS_PRV,IPC_CODE_DT_PRV,VERSION_NO_PRV
    )group by APPL_NO,M_VERSION_NO having sum(d_count)=0 
                                      and count(case when m_count =1 then 1 else null end) =count(case when m_count >0 then 1 else null end) 
                                      and (M_VERSION_NO>'07' or count(case when m_count =1 then 1 else null end)=count(*))
  ),person_skills as ( --承辦人專長
    select processor_no,skill,row_number() over (partition by skill order by dbms_random.random) as rn
    from((
      select authority.processor_no,'0' skill
      from authority,spm63 
      where  BITAND(skills,1) >0 and substr(group_id,2,1)='B'
      and authority.processor_no=spm63.processor_no and substr(authority.processor_no,1,1)<>'P'
      and spm63.DEPT_NO='70014' and spm63.QUIT_DATE is null
    )union(
      select authority.processor_no,'1' skill
      from authority,spm63 
      where  BITAND(skills,1) >0 and nvl(substr(group_id,2,1),'A')='A'
      and authority.processor_no=spm63.processor_no and substr(authority.processor_no,1,1)<>'P'
      and spm63.DEPT_NO='70014' and spm63.QUIT_DATE is null
    )union(
      select authority.processor_no,'2' skill
      from authority,spm63 
      where  BITAND(skills,2) >0
      and authority.processor_no=spm63.processor_no and substr(authority.processor_no,1,1)<>'P'
      and spm63.DEPT_NO='70014' and spm63.QUIT_DATE is null
    )union(
      select authority.processor_no,'3' skill
      from authority,spm63 
      where  BITAND(skills,4) >0
      and authority.processor_no=spm63.processor_no and substr(authority.processor_no,1,1)<>'P'
      and spm63.DEPT_NO='70014' and spm63.QUIT_DATE is null
    )union(
      select authority.processor_no,'4' skill
      from authority,spm63 
      where  BITAND(skills,8) >0
      and authority.processor_no=spm63.processor_no and substr(authority.processor_no,1,1)<>'P'
      and spm63.DEPT_NO='70014' and spm63.QUIT_DATE is null
    )union(
      select authority.processor_no,'5' skill
      from authority,spm63 
      where  BITAND(skills,16) >0
      and authority.processor_no=spm63.processor_no and substr(authority.processor_no,1,1)<>'P'
      and spm63.DEPT_NO='70014' and spm63.QUIT_DATE is null
    )union(
      select authority.processor_no,'6' skill
      from authority,spm63 
      where  BITAND(skills,32) >0
      and authority.processor_no=spm63.processor_no and substr(authority.processor_no,1,1)<>'P'
      and spm63.DEPT_NO='70014' and spm63.QUIT_DATE is null
    )union(
      select '70014' processor_no,'*' skill from dual
    ))    
  )
  (   --待公開、待公告、外包已公開已公告、實審未核發審定書
      select a.APPL_NO,
      l_rcl_version_no VERSION_NO,
      nvl(spm63.processor_no,'70014') PROCESSOR_NO,
      sysdate ASSIGN_DATE,
      null COMPLETE_DATE,
      a.PATENT_CLASS,
      case when a.physical_flag=0 or a.NOTICE_STATUS in ('2') then to_char(a.NOTICE_STATUS+a.PRV_FLAG*4) else to_char(a.NOTICE_STATUS+7) end NOTICE_STATUS,
      a.IPC_TYPE,
      a.S_FLAG
      from ipc_rcl_appl a
      left join tmp_appl on a.appl_no=tmp_appl.appl_no
      left join spm63 on a.ipc_processor_no=spm63.processor_no and dept_no='70014' and spm63.quit_date is null
      where tmp_appl.appl_no is null and (a.NOTICE_STATUS in ('0','1') or a.NOTICE_STATUS in ('2') and IS_PROCESSOR_P(spm63.processor_no)>0)
  )union( --已公開 已公告(不含外包)
      select a.APPL_NO,
      l_rcl_version_no VERSION_NO,
      nvl(b.processor_no,'70014') PROCESSOR_NO,
      sysdate ASSIGN_DATE,
      null COMPLETE_DATE,
      a.PATENT_CLASS,
      to_char(a.NOTICE_STATUS+a.PRV_FLAG*4) NOTICE_STATUS,
      a.IPC_TYPE,
      a.S_FLAG
      from (
        select x.*, row_number() over (partition by skill order by dbms_random.random) as rn from (
          select y.* , 
                 case when PATENT_CLASS='1' and FIRST_DEPT_NO ='70025' then '0'
                      when PATENT_CLASS='1' then '1' --FIRST_DEPT_NO ='70026'
                      when PATENT_CLASS>='2' and PATENT_CLASS<='6' then PATENT_CLASS
                      else null end skill
            from 
                (select ipc_rcl_appl.APPL_NO,ipc_rcl_appl.PATENT_CLASS,ipc_rcl_appl.FIRST_DEPT_NO,
                   ipc_rcl_appl.NOTICE_STATUS,ipc_rcl_appl.PRV_FLAG,
                   ipc_rcl_appl.IPC_TYPE,
                   ipc_rcl_appl.S_FLAG
                   from ipc_rcl_appl
                   left join tmp_appl on ipc_rcl_appl.appl_no=tmp_appl.appl_no
                   left join spm63 on IS_PROCESSOR_P(ipc_rcl_appl.ipc_processor_no)>0 and ipc_rcl_appl.ipc_processor_no=spm63.processor_no and dept_no='70014' and spm63.quit_date is null
                   where tmp_appl.appl_no is null and ipc_rcl_appl.NOTICE_STATUS in ('2') and spm63.processor_no is null) y
        ) x
      )a
      left join (select skill,count(*) max_cnt from person_skills group by skill) c on nvl(a.skill,'*')=c.skill
      left join person_skills b on nvl(a.skill,'*')=b.skill
      left join tmp_appl on a.appl_no=tmp_appl.appl_no
      where mod(a.rn,c.max_cnt)+1 = b.rn and tmp_appl.appl_no is null
  )union(
      select a.APPL_NO,
      l_rcl_version_no VERSION_NO,
      'A6119' PROCESSOR_NO,
      sysdate ASSIGN_DATE,
      null COMPLETE_DATE,
      a.PATENT_CLASS,
      to_char(a.NOTICE_STATUS+7) NOTICE_STATUS,
      a.IPC_TYPE,
      a.S_FLAG
      from ipc_rcl_appl a,tmp_appl 
      where a.appl_no=tmp_appl.appl_no
  )
  ;
end;

/*建立回溯清單細項*/
PROCEDURE BUILD_IPC_TRCE_LIST
as
BEGIN
  insert into IPC_TRACE_LIST 
  select IPC_TRACE_LIST_ID_SEQ.nextval ID,
        l_rcl_version_no VERSION_NO,
        a.APPL_NO,
        case when a.s_flag ='1' then spm21c.DATA_SEQ else spm21.DATA_SEQ end DATA_SEQ,
        null SOIRT_ID,
        decode(a.s_flag,'1',spm21c.IPC_CODE_MS,spm21.IPC_CODE_MS_PRV) IPC_CODE_MS_PRV,
        decode(a.s_flag,'1',spm21c.IPC_CODE_DT,spm21.IPC_CODE_DT_PRV) IPC_CODE_DT_PRV,
        decode(a.s_flag,'1',spm21c.VERSION_NO,spm21.VERSION_NO_PRV) VERSION_NO_PRV,
        nvl(rcl_detail.IPC_CODE_MS_NEW,decode(a.s_flag,'1',spm21c.IPC_CODE_MS,spm21.IPC_CODE_MS_PRV)) IPC_CODE_MS_NEW,
        nvl(rcl_detail.IPC_CODE_DT_NEW,decode(a.s_flag,'1',spm21c.IPC_CODE_DT,spm21.IPC_CODE_DT_PRV)) IPC_CODE_DT_NEW,
        case when rcl_detail.attribute_new='t' then (
                  select max(spm22.version_no)
                    from spm22 
                   where spm22.IPC_CODE_MS=rcl_detail.IPC_CODE_MS_NEW
                     and spm22.IPC_CODE_DT=rcl_detail.IPC_CODE_DT_NEW
                     and spm22.VERSION_NO<l_rcl_version_no
                     and spm22.M_FLAG is null
                  )
             when rcl_detail.attribute_new is null then decode(a.s_flag,'1',spm21c.VERSION_NO,spm21.VERSION_NO_PRV)
             else to_char(l_rcl_version_no) end  VERSION_NO_NEW,
        decode(a.s_flag,'1',spm21c.IPC_REF_TYPE,spm21.IPC_REF_TYPE) IPC_REF_TYPE,
        case when a.processor_no='A6119' then '1'
             when rcl_detail.attribute_new is null then '0'
             else '2' end DEL_FLAG
    from IPC_TRACE a
    left join spm21c on a.appl_no=spm21c.appl_no and a.S_FLAG='1'
    left join spm21 on a.appl_no=spm21.appl_no and a.S_FLAG='0'
    left join RCL_DETAIL on RCL_DETAIL.VERSION_NO=l_rcl_version_no and 
                            (RCL_DETAIL.IPC_CODE_MS_PRV=spm21.IPC_CODE_MS_PRV and RCL_DETAIL.IPC_CODE_DT_PRV=spm21.IPC_CODE_DT_PRV
                             or RCL_DETAIL.IPC_CODE_MS_PRV=spm21c.IPC_CODE_MS and RCL_DETAIL.IPC_CODE_DT_PRV=spm21c.IPC_CODE_DT)
  where (spm21c.appl_no is not null or spm21.appl_no is not null) and a.VERSION_NO=l_rcl_version_no
  ;
end;


/*初始化*/
PROCEDURE INIT
AS
BEGIN
  delete from IPC_TRACE where version_no=l_rcl_version_no;
  delete from IPC_TRACE_LIST where version_no=l_rcl_version_no;
END;

begin
  P_OUT_MSG:=0;
  
  --選取 RCL 版本
  select min(version_no) into l_rcl_version_no
  from rcl_ver 
  where COMPLETE_DATE is null 
  and START_DATE is not null;
  
  begin
    --找到RCL版本
    if l_rcl_version_no > '07' then
      INIT;
      BUILD_IPC_TRACE;      --建立回溯清單大項
      BUILD_IPC_TRCE_LIST;  --建立回溯清單細項
      --BACKUP_IPC;           --備份IPC
      UPDATE_SPM21B;        --更新SPM21B
      UPDATE_SPM21;         --更新SPM21
      UPDATE_SPM21C;        --更新SPM21C
      
      --更新COMPLETE_DATE
      update rcl_ver set COMPLETE_DATE=sysdate where version_no=l_rcl_version_no and COMPLETE_DATE is null and START_DATE is not null;
      
      select count(*) into P_OUT_MSG
	    from IPC_TRACE
	    where VERSION_NO=l_rcl_version_no
	    and NOTICE_STATUS < '7'
	    ;
      
    end if;
  exception
    WHEN OTHERS THEN
      P_OUT_MSG:=0;
      --RESET_ALL;
  end;
  
  open p_out_list for
  select a.appl_no, a.processor_No, b.patent_Name_C,
         TO_CHAR(TO_NUMBER(TO_CHAR(a.complete_date, 'YYYYMMDD')) - 19110000) complete_date,
			   b. APPL_DATE  
	from IPC_TRACE a, spt31 b
	where a.VERSION_NO=l_rcl_version_no
	and a.NOTICE_STATUS <'7'
  and a.appl_no=b.appl_no	
  ;
  
end DISPATCH_RCL_APPLS_ORI;

/
