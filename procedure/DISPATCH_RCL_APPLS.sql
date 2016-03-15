--------------------------------------------------------
--  DDL for Procedure DISPATCH_RCL_APPLS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."DISPATCH_RCL_APPLS" (P_OUT_MSG out number,p_out_list     out sys_refcursor) 
is
l_rcl_version_no CHAR(6):=null;
start_time  number;  end_time   number;
begin
/*
IPC_TRACE_LIST
DEL_FLAG��0:�����^�� 1:�@��@ 2:�@��h 3:��IPC���ʵ��O�@4~12:�@��@�۰ʧ����@16:���o�f�w��
SORT_ID=1:�ݤ��} 	2:�ݤ��i 	4:�w���} 	8:�w���i	16:B��	32:V��	64:SPM21C
*/
  --��� RCL ����
  select min(version_no) into l_rcl_version_no
  from rcl_ver 
  where COMPLETE_DATE is null 
  and START_DATE is not null;

  --���RCL����
  if l_rcl_version_no > '07' then  
    begin
      --��l��
      delete from IPC_TRACE where version_no=l_rcl_version_no;
      delete from IPC_TRACE_LIST where version_no=l_rcl_version_no;
      
      Start_time := DBMS_UTILITY.get_time;
      
      --����1-1�B1-N�^��
      insert into Ipc_Trace_List  
      with spm22t as (
            (
            --�@��@�B�@��h
            select x.VERSION_NO,x.IPC_CODE_MS_PRV,x.IPC_CODE_DT_PRV,x.IPC_CODE_MS_NEW,x.IPC_CODE_DT_NEW,
                  (case when x.attribute_new='t' then
                    (select max(version_no) 
                      from spm22 
                     where spm22.ipc_code_ms=x.ipc_code_ms_new 
                       and spm22.ipc_code_dt=x.ipc_code_dt_new
                       and spm22.version_no<=l_rcl_version_no)
                   else x.version_no end) VERSION_NO_NEW,b.DEL_FLAG
             from rcl_detail x,
                  (select ipc_code_ms_prv,ipc_code_dt_prv,version_no,
                    case when count(1)>1 then 2 else 1 end  DEL_FLAG
                    from rcl_detail
                    where version_no =l_rcl_version_no
                    group by ipc_code_ms_prv,ipc_code_dt_prv,version_no) b
            where x.ipc_code_ms_prv=b.ipc_code_ms_prv 
              and x.ipc_code_dt_prv=b.ipc_code_dt_prv
              and x.version_no=b.version_no
            )union(
              --��IPC���ʵ��O
              select to_char(l_rcl_version_no) VERSION_NO,IPC_CODE_MS IPC_CODE_MS_PRV,IPC_CODE_DT IPC_CODE_DT_PRV,
                      IPC_CODE_MS IPC_CODE_MS_NEW,IPC_CODE_DT IPC_CODE_DT_NEW,
                      x.version_no VERSION_NO_NEW,3 DEL_FLAG 
              from spm22 x
              where x.M_FLAG is not null
              and not exists (select 1 
                              from rcl_detail z 
                              where z.ipc_code_ms_prv=x.ipc_code_ms 
                              and z.ipc_code_dt_prv=x.ipc_code_dt
                              and z.version_no=l_rcl_version_no)
            )
      )
      select IPC_TRACE_LIST_ID_SEQ.nextval ID,x.*
      from((
          --SPM21
          select l_rcl_version_no VERSION_NO,a.APPL_NO,a.DATA_SEQ,
            (case when (b.appl_no is null or (b.Notice_No_2 is null or b.Notice_No_2=0)) and substr(a.appl_no,4,1)='1' then 1
                  when b.Notice_No_2>0 and substr(a.appl_no,4,1)='1' then 4 else 0 end) + 
            (case when (b.appl_no is null and substr(a.appl_no,4,1)='2' or (b.Notice_No is null or b.Notice_No='0')) then 2
                  when b.Notice_No>'0' and substr(a.appl_no,4,1) in ('1','2') then 8 else 0 end) SORT_ID,
            a.IPC_CODE_MS_PRV, a.IPC_CODE_DT_PRV, a.VERSION_NO_PRV,
            nvl(c.IPC_CODE_MS_NEW,a.IPC_CODE_MS_PRV) IPC_CODE_MS_NEW, nvl(c.IPC_CODE_DT_NEW,a.IPC_CODE_DT_PRV) IPC_CODE_DT_NEW, nvl(c.VERSION_NO_NEW,a.VERSION_NO_PRV) VERSION_NO_NEW,
            a.IPC_REF_TYPE, c.DEL_FLAG 
          from spm21 a
          left join spt82 b on a.appl_no=b.appl_no
          inner join spm22t c on a.ipc_code_ms_prv=c.ipc_code_ms_prv
             and a.ipc_code_dt_prv=c.ipc_code_dt_prv
             and (a.version_no_prv=c.version_no_new and c.del_flag=3 or c.del_flag in (1,2) and a.version_no_prv<c.version_no)
           where (
                     b.appl_no is null 
                  or (b.Notice_No_2 is null or b.Notice_No_2=0) and substr(a.appl_no,4,1)='1' and (b.Notice_No is null or b.Notice_No='0')  ----�����} �����i
                  or (b.Notice_No is null or b.Notice_No='0') --�����i
                  or b.Notice_No>'0' and not exists(select 1 from spm21c where spm21c.appl_no=a.appl_no)  --�w���i �B ���bspm21C
                ) 
                and substr(a.appl_no,4,1) in ('1','2')�@--�o���סB�s����
      )union(
          --B��
          select l_rcl_version_no VERSION_NO,a.APPL_NO,a.DATA_SEQ,
            (case when (b.appl_no is null or (b.Notice_No_2 is null or b.Notice_No_2=0)) and substr(a.appl_no,4,1)='1' then 1
                  when b.Notice_No_2>0 and substr(a.appl_no,4,1)='1' then 4 else 0 end) + 
            (case when (b.appl_no is null and substr(a.appl_no,4,1)='2' or (b.Notice_No is null or b.Notice_No='0')) then 2
                  when b.Notice_No>'0' and substr(a.appl_no,4,1) in ('1','2') then 8 else 0 end)+16 SORT_ID,�@--�@SORT_ID=17:�Ъ��ݤ��} 	18:�Ъ��ݤ��i 	20:�Ъ��w���} 	24:�Ъ��w���i
            a.IPC_CODE_MS IPC_CODE_MS_PRV, a.IPC_CODE_DT IPC_CODE_DT_PRV, a.VERSION_NO VERSION_NO_PRV,
            nvl(c.IPC_CODE_MS_NEW,a.IPC_CODE_MS) IPC_CODE_MS_NEW, nvl(c.IPC_CODE_DT_NEW,a.IPC_CODE_DT) IPC_CODE_DT_NEW, nvl(c.VERSION_NO_NEW,a.VERSION_NO) VERSION_NO_NEW,
            a.IPC_REF_TYPE, c.DEL_FLAG
          from spm21b a
          left join spt82 b on a.appl_no=b.appl_no
          inner join spm22t c on a.ipc_code_ms=c.ipc_code_ms_prv
             and a.ipc_code_dt=c.ipc_code_dt_prv
             and (a.version_no=c.version_no_new and c.del_flag=3 or c.del_flag in (1,2) and a.version_no<c.version_no)
          where ( b.appl_no is null or (b.Notice_No_2 is null or b.Notice_No_2=0) and (b.Notice_No is null or b.Notice_No='0'))--�����} �����i
            and substr(a.appl_no,4,1)='1' and a.step_code='B'�@--B���o����
      )union(
          --V��
          select l_rcl_version_no VERSION_NO,a.APPL_NO,a.DATA_SEQ,
          (case when (b.appl_no is null or (b.Notice_No_2 is null or b.Notice_No_2=0)) and substr(a.appl_no,4,1)='1' then 1
                when b.Notice_No_2>0 and substr(a.appl_no,4,1)='1' then 4 else 0 end) + 
          (case when (b.appl_no is null and substr(a.appl_no,4,1)='2' or (b.Notice_No is null or b.Notice_No='0')) then 2
                when b.Notice_No>'0' and substr(a.appl_no,4,1) in ('1','2') then 8 else 0 end)+32 SORT_ID,--�@SORT_ID=33:V���ݤ��} 	34:V���ݤ��i 36:V���w���} 	40:V���w���i
            a.IPC_CODE_MS IPC_CODE_MS_PRV, a.IPC_CODE_DT IPC_CODE_DT_PRV, a.VERSION_NO VERSION_NO_PRV,
            nvl(c.IPC_CODE_MS_NEW,a.IPC_CODE_MS) IPC_CODE_MS_NEW, nvl(c.IPC_CODE_DT_NEW,a.IPC_CODE_DT) IPC_CODE_DT_NEW, nvl(c.VERSION_NO_NEW,a.VERSION_NO) VERSION_NO_NEW,
            a.IPC_REF_TYPE, c.DEL_FLAG 
          from spm21b a
          left join spt82 b on a.appl_no=b.appl_no
          inner join spm22t c on a.ipc_code_ms=c.ipc_code_ms_prv
             and a.ipc_code_dt=c.ipc_code_dt_prv
             and (a.version_no=c.version_no_new and c.del_flag=3 or c.del_flag in (1,2) and a.version_no<c.version_no)
          where ( b.appl_no is null and substr(a.appl_no,4,1)='2' or (b.Notice_No is null or b.Notice_No='0') and substr(a.appl_no,4,1) in ('1','2'))
             and a.step_code='V'
      )union(
          --SPM21C
          select l_rcl_version_no VERSION_NO,a.APPL_NO,a.DATA_SEQ,
          (case when (b.appl_no is null or (b.Notice_No_2 is null or b.Notice_No_2=0)) and substr(a.appl_no,4,1)='1' then 1
                when b.Notice_No_2>0 and substr(a.appl_no,4,1)='1' then 4 else 0 end) + 
          (case when (b.appl_no is null and substr(a.appl_no,4,1)='2' or (b.Notice_No is null or b.Notice_No='0')) then 2
                when b.Notice_No>'0' and substr(a.appl_no,4,1) in ('1','2') then 8 else 0 end)+64 SORT_ID,--�@SORT_ID=65:C���ݤ��} 	66:C���ݤ��i 68:C���w���} 	72:C���w���i
            a.IPC_CODE_MS IPC_CODE_MS_PRV, a.IPC_CODE_DT IPC_CODE_DT_PRV, a.VERSION_NO VERSION_NO_PRV,
            nvl(c.IPC_CODE_MS_NEW,a.IPC_CODE_MS) IPC_CODE_MS_NEW, nvl(c.IPC_CODE_DT_NEW,a.IPC_CODE_DT) IPC_CODE_DT_NEW, nvl(c.VERSION_NO_NEW,a.VERSION_NO) VERSION_NO_NEW,
            a.IPC_REF_TYPE, c.DEL_FLAG 
          from spm21c a
          left join spt82 b on a.appl_no=b.appl_no
          inner join spm22t c on a.ipc_code_ms=c.ipc_code_ms_prv
             and a.ipc_code_dt=c.ipc_code_dt_prv
             and (a.version_no=c.version_no_new and c.del_flag=3 or c.del_flag in (1,2) and a.version_no<c.version_no)
          where b.Notice_No>'0' and substr(a.appl_no,4,1) in ('1','2') --�w���i
      )) x  
      ;
  
      end_time := DBMS_UTILITY.get_time;
      DBMS_OUTPUT.PUT_LINE('1:'||to_char((end_time-start_time)/100));  
      
      --�ɤW��LIPC
      insert into Ipc_Trace_List  
      select IPC_TRACE_LIST_ID_SEQ.nextval ID,x.*
      from((
          select l_rcl_version_no VERSION_NO,
                a.APPL_NO,
                a.DATA_SEQ,
                b.SORT_ID,
                a.IPC_CODE_MS_PRV, a.IPC_CODE_DT_PRV, a.VERSION_NO_PRV,
                a.IPC_CODE_MS_PRV IPC_CODE_MS_NEW, a.IPC_CODE_DT_PRV IPC_CODE_DT_NEW, a.VERSION_NO_PRV VERSION_NO_NEW,
                a.IPC_REF_TYPE, 0 DEL_FLAG
          from spm21 a,(
            select appl_no, bitand(min(SORT_ID),15) SORT_ID
            from Ipc_Trace_List
            where Version_No=l_rcl_version_no and bitand(sort_id,64+32+16)=0 and del_flag>0
            group by appl_no
          ) b
          where a.appl_no=b.appl_no
          and not exists (select 1 from Ipc_Trace_List c where c.Version_No=l_rcl_version_no and a.appl_no=c.appl_no and a.data_seq=c.data_seq and bitand(c.sort_id,64+32+16)=0)
      )union(--B��
          select l_rcl_version_no VERSION_NO,
                a.APPL_NO,
                a.DATA_SEQ,
                b.SORT_ID,
                a.IPC_CODE_MS IPC_CODE_MS_PRV, a.IPC_CODE_DT IPC_CODE_DT_PRV, a.VERSION_NO VERSION_NO_PRV,
                a.IPC_CODE_MS IPC_CODE_MS_NEW, a.IPC_CODE_DT IPC_CODE_DT_NEW, a.VERSION_NO VERSION_NO_NEW,
                a.IPC_REF_TYPE, 0 DEL_FLAG
          from spm21b a,(
            select distinct appl_no,SORT_ID
            from Ipc_Trace_List
            where Version_No=l_rcl_version_no and bitand(sort_id,16)>0 and del_flag>0
          ) b
          where a.appl_no=b.appl_no and a.step_code='B'
          and not exists (select 1 from Ipc_Trace_List c where c.Version_No=l_rcl_version_no and a.appl_no=c.appl_no and a.data_seq=c.data_seq and bitand(c.sort_id,16)>0)
      )union(--V��
          select l_rcl_version_no VERSION_NO,
                a.APPL_NO,
                a.DATA_SEQ,
                b.SORT_ID,
                a.IPC_CODE_MS IPC_CODE_MS_PRV, a.IPC_CODE_DT IPC_CODE_DT_PRV, a.VERSION_NO VERSION_NO_PRV,
                a.IPC_CODE_MS IPC_CODE_MS_NEW, a.IPC_CODE_DT IPC_CODE_DT_NEW, a.VERSION_NO VERSION_NO_NEW,
                a.IPC_REF_TYPE, 0 DEL_FLAG
          from spm21b a,(
            select distinct appl_no,SORT_ID
            from Ipc_Trace_List a
            where Version_No=l_rcl_version_no and bitand(sort_id,32)>0 and del_flag>0
          ) b
          where a.appl_no=b.appl_no and a.step_code='V'
          and not exists (select 1 from Ipc_Trace_List c where c.Version_No=l_rcl_version_no and a.appl_no=c.appl_no and a.data_seq=c.data_seq and bitand(c.sort_id,32)>0)
      )union(--C��
          select l_rcl_version_no VERSION_NO,
                a.APPL_NO,
                a.DATA_SEQ,
                b.SORT_ID,
                a.IPC_CODE_MS IPC_CODE_MS_PRV, a.IPC_CODE_DT IPC_CODE_DT_PRV, a.VERSION_NO VERSION_NO_PRV,
                a.IPC_CODE_MS IPC_CODE_MS_NEW, a.IPC_CODE_DT IPC_CODE_DT_NEW, a.VERSION_NO VERSION_NO_NEW,
                a.IPC_REF_TYPE, 0 DEL_FLAG
          from spm21c a,(
            select distinct appl_no,SORT_ID
            from Ipc_Trace_List a
            where Version_No=l_rcl_version_no and bitand(sort_id,64)>0 and del_flag>0
          ) b
          where a.appl_no=b.appl_no
          and not exists (select 1 from Ipc_Trace_List c where c.Version_No=l_rcl_version_no and a.appl_no=c.appl_no and a.data_seq=c.data_seq and bitand(c.sort_id,64)>0)
      ))x
      ;  
  
      end_time := DBMS_UTILITY.get_time;
      DBMS_OUTPUT.PUT_LINE('2:'||to_char((end_time-start_time)/100));  
  
      --�Хܤ@��@�۰ʦ^��
      update Ipc_Trace_List set del_flag=4
      where id in (
        select a.id 
        from Ipc_Trace_List a
        left join (
          --IPC�ӼƤ��@�P or ���Ǥ��@�P
          select distinct c.appl_no
          from Ipc_Trace_List c,
          (
              -- �p��@��@�ץ�IPC�Ӽ�
              select appl_no,
                       (select count(1) from spm21 y where y.appl_no=x.appl_no) cnt_21,
                       (select count(1) from spm21b y where y.appl_no=x.appl_no and step_code='B') cnt_21b,
                       (select count(1) from spm21b y where y.appl_no=x.appl_no and step_code='V') cnt_21v,
                       (select count(1) from spm21c y where y.appl_no=x.appl_no) cnt_21c
              from(
                select distinct appl_no --����@��@�׸�
                from Ipc_Trace_List
                where Version_No=l_rcl_version_no and Del_Flag=1
              ) x
          ) d
          where Version_No=l_rcl_version_no and Del_Flag=1 
            and c.appl_no=d.appl_no
            and (
                 --B��IPC�ӼƤ��@�P or ���Ǥ��@�P
                 bitand(sort_id,8+1)=1 and cnt_21b>0 and (--�����}(���t�w���i)
                     cnt_21<>cnt_21b 
                 or  exists(select 1 
                            from spm21 x,spm21b y 
                            where c.appl_no=x.appl_no 
                            and c.appl_no=y.appl_no 
                            and x.data_seq=y.data_seq
                            and y.step_code='B'
                            and not (
                                    x.ipc_code_ms_prv=y.ipc_code_ms and x.ipc_code_dt_prv=y.ipc_code_dt --and d.version_no_prv=c.version_no
                                 or x.ipc_code_ms_prv=c.ipc_code_ms_prv and x.ipc_code_dt_prv=c.ipc_code_dt_prv and y.ipc_code_ms=c.ipc_code_ms_new and y.ipc_code_dt=c.ipc_code_dt_new
                                 or x.ipc_code_ms_prv=c.ipc_code_ms_new and x.ipc_code_dt_prv=c.ipc_code_dt_new and y.ipc_code_ms=c.ipc_code_ms_prv and y.ipc_code_dt=c.ipc_code_dt_prv
                              )
                           )
                )
                 --V��IPC�ӼƤ��@�P or ���Ǥ��@�P
             or bitand(sort_id,2)>0 and cnt_21v>0 and (--�����i
                     cnt_21<>cnt_21v 
                 or  exists(select 1 
                            from spm21 x,spm21b y 
                            where c.appl_no=x.appl_no 
                            and c.appl_no=y.appl_no 
                            and x.data_seq=y.data_seq
                            and y.step_code='V'
                            and not (
                                    x.ipc_code_ms_prv=y.ipc_code_ms and x.ipc_code_dt_prv=y.ipc_code_dt --and d.version_no_prv=c.version_no
                                 or x.ipc_code_ms_prv=c.ipc_code_ms_prv and x.ipc_code_dt_prv=c.ipc_code_dt_prv and y.ipc_code_ms=c.ipc_code_ms_new and y.ipc_code_dt=c.ipc_code_dt_new
                                 or x.ipc_code_ms_prv=c.ipc_code_ms_new and x.ipc_code_dt_prv=c.ipc_code_dt_new and y.ipc_code_ms=c.ipc_code_ms_prv and y.ipc_code_dt=c.ipc_code_dt_prv
                              )
                           )
                )
                 --C��IPC�ӼƤ��@�P or ���Ǥ��@�P
             or bitand(sort_id,4+8)>0 and cnt_21c>0 and (--�w���}�����i(���t�����}�w���})
                     cnt_21<>cnt_21c
                  or exists(
                            select 1 
                            from spm21 x,spm21c y 
                            where c.appl_no=x.appl_no 
                            and c.appl_no=y.appl_no 
                            and x.data_seq=y.data_seq
                            and not (
                                    x.ipc_code_ms_prv=y.ipc_code_ms and x.ipc_code_dt_prv=y.ipc_code_dt --and d.version_no_prv=c.version_no
                                 or x.ipc_code_ms_prv=c.ipc_code_ms_prv and x.ipc_code_dt_prv=c.ipc_code_dt_prv and y.ipc_code_ms=c.ipc_code_ms_new and y.ipc_code_dt=c.ipc_code_dt_new
                                 or x.ipc_code_ms_prv=c.ipc_code_ms_new and x.ipc_code_dt_prv=c.ipc_code_dt_new and y.ipc_code_ms=c.ipc_code_ms_prv and y.ipc_code_dt=c.ipc_code_dt_prv
                              )
                          )
                )
            )
        ) b on a.appl_no=b.appl_no
        where Version_No=l_rcl_version_no and Del_Flag=1 -- �@��@
        and not exists (select 1 from Ipc_Trace_List x where x.Version_No=l_rcl_version_no and x.appl_no=a.appl_no and (x.Del_Flag in (2,3) or x.Del_Flag=0 and x.Version_No_New<'200601') ) -- ���t�@��h,�ª�
        and b.appl_no is null --�ư�IPC�ӼƤ��@�P or ���Ǥ��@�P
      )
      ;
  
      end_time := DBMS_UTILITY.get_time;
      DBMS_OUTPUT.PUT_LINE('3:'||to_char((end_time-start_time)/100));  
  
      --�ư����o�f�w��
      update Ipc_Trace_List set del_flag=del_flag+16-bitand(del_flag,16)
      where appl_no in (
        select a.appl_no 
        from Ipc_Trace_List a
        where Version_No=l_rcl_version_no
        and exists (select 1 from spt31a where spt31a.appl_no=a.appl_no and substr(spt31a.step_code,1,1) in ('2','4','6'))
        and not exists (select 1 from spt41 where spt41.appl_no=a.appl_no and spt41.process_result in ('56001','56003','56097') and nvl(spt41.file_d_flag,'0')<>'9')
        --and bitand(sort_id,8+2+1) in (1,2,3)
        and del_flag<4
        and not exists (select 1 from Ipc_Trace_List b where b.Version_No=l_rcl_version_no and a.appl_no=b.appl_no and b.del_flag=4)
      ) and Version_No=l_rcl_version_no
      ;
  
      end_time := DBMS_UTILITY.get_time;
      DBMS_OUTPUT.PUT_LINE('4:'||to_char((end_time-start_time)/100));  
  
      --�۰ʤ���
      insert into IPC_TRACE
      with person_skills as ( 
          --�ӿ�H�M��
          select processor_no,skill,row_number() over (partition by skill order by dbms_random.random) as rn
          from((
            select authority.processor_no,'B' skill --�ƾǥͧ�B
            from authority,spm63 
            where  BITAND(skills,1) >0 and substr(group_id,2,1)='B'
            and authority.processor_no=spm63.processor_no
            and spm63.DEPT_NO='70014' and spm63.QUIT_DATE is null
          )union(
            select authority.processor_no,'1' skill --�ƾǥͧ�A
            from authority,spm63 
            where  BITAND(skills,1) >0 and nvl(substr(group_id,2,1),'A')='A'
            and authority.processor_no=spm63.processor_no
            and spm63.DEPT_NO='70014' and spm63.QUIT_DATE is null
          )union(
            select authority.processor_no,'2' skill
            from authority,spm63 
            where  BITAND(skills,2) >0
            and authority.processor_no=spm63.processor_no
            and spm63.DEPT_NO='70014' and spm63.QUIT_DATE is null
          )union(
            select authority.processor_no,'3' skill
            from authority,spm63 
            where  BITAND(skills,4) >0
            and authority.processor_no=spm63.processor_no
            and spm63.DEPT_NO='70014' and spm63.QUIT_DATE is null
          )union(
            select authority.processor_no,'4' skill --�q�l�q��
            from authority,spm63 
            where  BITAND(skills,8) >0
            and authority.processor_no=spm63.processor_no
            and spm63.DEPT_NO='70014' and spm63.QUIT_DATE is null
          )union(
            select authority.processor_no,'5' skill
            from authority,spm63 
            where  BITAND(skills,16) >0
            and authority.processor_no=spm63.processor_no
            and spm63.DEPT_NO='70014' and spm63.QUIT_DATE is null
          )union(
            select authority.processor_no,'6' skill
            from authority,spm63 
            where  BITAND(skills,32) >0
            and authority.processor_no=spm63.processor_no
            and spm63.DEPT_NO='70014' and spm63.QUIT_DATE is null
          )union(
            select '70014' processor_no,'*' skill from dual
          ))    
      )
      (--�ݤ��} or �ݤ��i
              select distinct a.APPL_NO,
                     l_rcl_version_no VERSION_NO,
                     nvl(spm63.processor_no,'70014') PROCESSOR_NO,
                     sysdate ASSIGN_DATE,
                     null COMPLETE_DATE,
                     spt31.PATENT_CLASS,
                     case when bitand(a.sort_id,9)=1 then '0' --�ݤ��}
                          when bitand(a.sort_id,2)>0 then '1' --�ݤ��i
                          when bitand(a.sort_id,8)>0 then '2' --�w���}�w���i
                          else null end NOTICE_STATUS,
                     case when bitand(sort_id,64)=0 then (select substr(spm21.IPC_CODE_MS_PRV,1,1) from spm21 where spm21.appl_no=a.appl_no and rownum=1)
                          when bitand(sort_id,64)>0 then (select substr(spm21c.IPC_CODE_MS,1,1) from spm21c where spm21c.appl_no=a.appl_no and rownum=1)
                          else null end IPC_TYPE,
                     substr(spt31b.step_code,1,1) S_FLAG --���}
              from Ipc_Trace_List a 
              inner join spt31 on a.appl_no=spt31.appl_no
              left join spt31b on spt31.APPL_NO=spt31b.APPL_NO
              left join spm63 on spt31.ipc_processor_no=spm63.processor_no and dept_no='70014' and spm63.quit_date is null
              where a.version_no=l_rcl_version_no 
                and a.del_flag >=0 and a.del_flag <16
                and a.sort_id=(select min(y.sort_id) from Ipc_Trace_List y where y.Version_No=l_rcl_version_no and y.appl_no=a.appl_no)
                and bitand(a.sort_id,32+16)=0-- �DB���BV��
                and (
                      bitand(a.sort_id,9)=1--�ݤ��}
                   or bitand(a.sort_id,2)=2--�ݤ��i
                   or substr(spm63.processor_no,1,1)='P' and bitand(a.sort_id,8)>0--�w���i
                )
                and (spt31b.STEP_CODE>='30' and spt31b.STEP_CODE<'70' or trim(spt31b.STEP_CODE) is null)
                and not exists (select 1 from Ipc_Trace_List b where a.appl_no=b.appl_no and bitand(b.del_flag,12)>0 and b.version_no=l_rcl_version_no )--�ư�1-1

      )union(-- �w���i
          select a.APPL_NO,
            l_rcl_version_no VERSION_NO,
            nvl(b.processor_no,'70014') PROCESSOR_NO,
            sysdate ASSIGN_DATE,
            null COMPLETE_DATE,
            a.PATENT_CLASS,
            a.NOTICE_STATUS,
            case when bitand(sort_id,64)=0 then (select substr(spm21.IPC_CODE_MS_PRV,1,1) from spm21 where spm21.appl_no=a.appl_no and rownum=1)
                 when bitand(sort_id,64)>0 then (select substr(spm21c.IPC_CODE_MS,1,1) from spm21c where spm21c.appl_no=a.appl_no and rownum=1)
                 else null end IPC_TYPE,
            a.S_FLAG
          from (
            select x.*, row_number() over (partition by skill order by dbms_random.random) as rn from (
              select distinct a.appl_no,
                     spt31.patent_class,
                     case when bitand(a.sort_id,9)=1 then '0' --�ݤ��}
                          when bitand(a.sort_id,2)>0 then '1' --�ݤ��i
                          when bitand(a.sort_id,8)>0 then '2' --�w���i
                          else null end NOTICE_STATUS,
                     substr(spt31b.step_code,1,1) S_FLAG,
                     case when PATENT_CLASS='1' and FIRST_DEPT_NO ='70025' then 'B'
                          when PATENT_CLASS='1' then '1' --FIRST_DEPT_NO ='70026'
                          when PATENT_CLASS>='2' and PATENT_CLASS<='6' then PATENT_CLASS
                          else null end skill,
                     sort_id
              from Ipc_Trace_List a
              inner join spt31 on a.appl_no=spt31.appl_no
              left join spt31b on spt31.APPL_NO=spt31b.APPL_NO
              left join spm63 on spt31.ipc_processor_no=spm63.processor_no and dept_no='70014' and spm63.quit_date is null
              where a.version_no=l_rcl_version_no 
                and a.del_flag >=0 and a.del_flag <16
                and (spt31b.STEP_CODE>='30' and spt31b.STEP_CODE<'70' or trim(spt31b.STEP_CODE) is null)
                and bitand(a.sort_id,32+16)=0 and bitand(a.sort_id,8)>0 --�w���i
                and substr(spm63.processor_no,1,1) in ('0','1','2')--�ư��~�]
                and not exists (select 1 from Ipc_Trace_List b where a.appl_no=b.appl_no and bitand(b.del_flag,12)>0 and b.version_no=l_rcl_version_no )--�ư�1-1
            )x
          ) a
          left join (select skill,count(*) max_cnt from person_skills group by skill) c on nvl(a.skill,'*')=c.skill
          left join person_skills b on nvl(a.skill,'*')=b.skill
          where (mod(a.rn,c.max_cnt)+1 = b.rn or b.processor_no is null)
      )
    ;
  
      end_time := DBMS_UTILITY.get_time;
      DBMS_OUTPUT.PUT_LINE('5:'||to_char((end_time-start_time)/100));  
  
      --��s�@��@���O(5 for spm21b/B, 6 for spm21b/V, 12 for spm21c )
      update ipc_trace_list set Del_Flag=Del_Flag+1
      where id in(
        select a.id
        from ipc_trace_list a
        where a.version_no=l_rcl_version_no and bitand(del_flag,12)>0
        and bitand(a.sort_id,64+32+16+8+1)=1
        and not exists(select 1 from spm21b where spm21b.appl_no=a.appl_no and step_code='B')
      );
      
      update ipc_trace_list set del_flag=del_flag+2
      where id in(
        select a.id
        from ipc_trace_list a
        where a.version_no=l_rcl_version_no and bitand(del_flag,12)>0
        and bitand(a.sort_id,64+32+16+2)=2
        and not exists(select 1 from spm21b where spm21b.appl_no=a.appl_no and step_code='V')
      );
      
      update ipc_trace_list set del_flag=del_flag+4
      where id in(
        select a.id
        from ipc_trace_list a
        where a.version_no=l_rcl_version_no and bitand(del_flag,12)>0
        and bitand(a.sort_id,64+32+16+8+4) in (4,8,12)
        and not exists(select 1 from spm21c where spm21c.appl_no=a.appl_no)
        --and not exists (select 1 from Ipc_Trace_List x where x.Version_No=l_rcl_version_no and x.appl_no=a.appl_no and (x.Del_Flag in ('2','3') or x.Del_Flag='0' and x.Version_No_New<'200601') ) -- ���t�@��h,�ª�
      );
  
      end_time := DBMS_UTILITY.get_time;
      DBMS_OUTPUT.PUT_LINE('6:'||to_char((end_time-start_time)/100));  
/*
      --��sspm21,spm21b,spm21c
     MERGE INTO spm21 d
     USING (
      select distinct APPL_NO,DATA_SEQ,IPC_CODE_MS_NEW,IPC_CODE_DT_NEW,VERSION_NO_NEW,IPC_REF_TYPE 
        from ipc_trace_list
        where appl_no in (
            select distinct appl_no
            from ipc_trace_list
            where version_no=l_rcl_version_no and bitand(sort_id,64+32+16+1+2)in(1,2,3) and bitand(del_flag,12)>0
          )            
     ) s
     ON (d.appl_no = s.appl_no and s.data_seq=d.data_seq)
     WHEN MATCHED THEN 
     UPDATE SET d.sort_id = d.data_seq,
                d.IPC_CODE_MS_PRV=s.IPC_CODE_MS_NEW,
                d.IPC_CODE_DT_PRV=s.IPC_CODE_DT_NEW,
                d.VERSION_NO_PRV=VERSION_NO_NEW,
                d.IPC_CODE_MS=s.IPC_CODE_MS_NEW,
                d.IPC_CODE_DT=s.IPC_CODE_DT_NEW,
                d.VERSION_NO=VERSION_NO_NEW,
                d.IPC_REF_TYPE=s.IPC_REF_TYPE
                where d.IPC_CODE_MS_PRV<>s.IPC_CODE_MS_NEW
                   or d.IPC_CODE_DT_PRV<>s.IPC_CODE_DT_NEW
                   or d.VERSION_NO_PRV<>s.VERSION_NO_NEW
                   or d.IPC_CODE_MS<>s.IPC_CODE_MS_NEW
                   or d.IPC_CODE_DT<>s.IPC_CODE_DT_NEW
                   or d.VERSION_NO<>s.VERSION_NO_NEW
                   or d.IPC_REF_TYPE<>s.IPC_REF_TYPE
     WHEN NOT MATCHED THEN 
     INSERT (APPL_NO,DATA_SEQ,SORT_ID,IPC_CODE_MS_PRV,IPC_CODE_DT_PRV,VERSION_NO_PRV,IPC_CODE_MS,IPC_CODE_DT,VERSION_NO,IPC_REF_TYPE)
     VALUES (s.appl_no,s.data_seq,s.data_seq,
             s.IPC_CODE_MS_NEW,
             s.IPC_CODE_DT_NEW,
             s.VERSION_NO_NEW,
             s.IPC_CODE_MS_NEW,
             s.IPC_CODE_DT_NEW,
             s.VERSION_NO_NEW,
             s.IPC_REF_TYPE)
  ;
  
     MERGE INTO spm21b d
     USING (
       (
          select distinct APPL_NO,'B' STEP_CODE,DATA_SEQ,IPC_CODE_MS_NEW,IPC_CODE_DT_NEW,VERSION_NO_NEW,IPC_REF_TYPE 
          from ipc_trace_list
          where appl_no in (
            select distinct appl_no
            from ipc_trace_list
            where version_no=l_rcl_version_no and bitand(sort_id,16+1)>16 and bitand(del_flag,12)>0
          )
        )union(
          select distinct APPL_NO,'V' STEP_CODE,DATA_SEQ,IPC_CODE_MS_NEW,IPC_CODE_DT_NEW,VERSION_NO_NEW,IPC_REF_TYPE 
          from ipc_trace_list
          where appl_no in (
            select distinct appl_no
            from ipc_trace_list
            where version_no=l_rcl_version_no and bitand(sort_id,32+2)>32 and bitand(del_flag,12)>0
          )
        )
     ) s
     ON (d.appl_no = s.appl_no and s.data_seq=d.data_seq and d.step_code=s.STEP_CODE)
     WHEN MATCHED THEN 
     UPDATE SET d.sort_id = d.data_seq,
                d.IPC_CODE_MS=s.IPC_CODE_MS_NEW,
                d.IPC_CODE_DT=s.IPC_CODE_DT_NEW,
                d.VERSION_NO=VERSION_NO_NEW,
                d.IPC_REF_TYPE=s.IPC_REF_TYPE
                where d.IPC_CODE_MS<>s.IPC_CODE_MS_NEW
                   or d.IPC_CODE_DT<>s.IPC_CODE_DT_NEW
                   or d.VERSION_NO<>s.VERSION_NO_NEW
                   or d.IPC_REF_TYPE<>s.IPC_REF_TYPE
     WHEN NOT MATCHED THEN 
     INSERT (APPL_NO,STEP_CODE,DATA_SEQ,SORT_ID,IPC_CODE_MS,IPC_CODE_DT,VERSION_NO,IPC_REF_TYPE)
     VALUES (s.appl_no,s.STEP_CODE,s.data_seq,s.data_seq,
             s.IPC_CODE_MS_NEW,
             s.IPC_CODE_DT_NEW,
             s.VERSION_NO_NEW,
             s.IPC_REF_TYPE)
  ;
  
     MERGE INTO spm21c d
     USING (
      select distinct APPL_NO,DATA_SEQ,IPC_CODE_MS_NEW,IPC_CODE_DT_NEW,VERSION_NO_NEW,IPC_REF_TYPE 
        from ipc_trace_list
        where appl_no in (
            select distinct appl_no
            from ipc_trace_list
            where version_no=l_rcl_version_no and bitand(sort_id,64+4+8)>64 and bitand(del_flag,12)>0
          )            
     ) s
     ON (d.appl_no = s.appl_no and s.data_seq=d.data_seq)
     WHEN MATCHED THEN 
     UPDATE SET d.sort_id = d.data_seq,
                d.IPC_CODE_MS=s.IPC_CODE_MS_NEW,
                d.IPC_CODE_DT=s.IPC_CODE_DT_NEW,
                d.VERSION_NO=VERSION_NO_NEW,
                d.IPC_REF_TYPE=s.IPC_REF_TYPE
                where d.IPC_CODE_MS<>s.IPC_CODE_MS_NEW
                   or d.IPC_CODE_DT<>s.IPC_CODE_DT_NEW
                   or d.VERSION_NO<>s.VERSION_NO_NEW
                   or d.IPC_REF_TYPE<>s.IPC_REF_TYPE
     WHEN NOT MATCHED THEN 
     INSERT (APPL_NO,DATA_SEQ,SORT_ID,IPC_CODE_MS,IPC_CODE_DT,VERSION_NO,IPC_REF_TYPE)
     VALUES (s.appl_no,s.data_seq,s.data_seq,
             s.IPC_CODE_MS_NEW,
             s.IPC_CODE_DT_NEW,
             s.VERSION_NO_NEW,
             s.IPC_REF_TYPE)
  ;
      
      end_time := DBMS_UTILITY.get_time;
      DBMS_OUTPUT.PUT_LINE('7:'||to_char((end_time-start_time)/100));  
  
      --�s�Wspm21b, spm21c
      insert into spm21b
      (
      select APPL_NO,'B' STEP_CODE,DATA_SEQ,DATA_SEQ SORT_ID,IPC_CODE_MS_NEW IPC_CODE_MS,IPC_CODE_DT_NEW IPC_CODE_DT,VERSION_NO_NEW VERSION_NO,IPC_REF_TYPE 
      from ipc_trace_list
      where appl_no in(
        select a.appl_no
        from ipc_trace_list a
        where a.version_no=l_rcl_version_no and del_flag in (5,7,9,11)
      ) and version_no=l_rcl_version_no and bitand(sort_id,64+32+16+8+1)=1
      )union(
      select APPL_NO,'V' STEP_CODE,DATA_SEQ,DATA_SEQ SORT_ID,IPC_CODE_MS_NEW IPC_CODE_MS,IPC_CODE_DT_NEW IPC_CODE_DT,VERSION_NO_NEW VERSION_NO,IPC_REF_TYPE 
      from ipc_trace_list
      where appl_no in(
        select a.appl_no
        from ipc_trace_list a
        where a.version_no=l_rcl_version_no and del_flag in (6,7,10,11)
      ) and version_no=l_rcl_version_no and bitand(sort_id,64+32+16+2)=2
      );
      
      insert into spm21c
      select APPL_NO,DATA_SEQ,DATA_SEQ SORT_ID,IPC_CODE_MS_NEW IPC_CODE_MS,IPC_CODE_DT_NEW IPC_CODE_DT,VERSION_NO_NEW VERSION_NO,IPC_REF_TYPE 
      from ipc_trace_list
      where appl_no in(
      select a.appl_no
      from ipc_trace_list a
      where a.version_no=l_rcl_version_no and del_flag in (8,9,10,11)
      ) and version_no=l_rcl_version_no and bitand(sort_id,64+32+16+8+4) in (4,8,12)
      ;
*/  
      end_time := DBMS_UTILITY.get_time;
      DBMS_OUTPUT.PUT_LINE('8:'||to_char((end_time-start_time)/100));  
      
      --��sCOMPLETE_DATE
      update rcl_ver set COMPLETE_DATE=sysdate where version_no=l_rcl_version_no and COMPLETE_DATE is null and START_DATE is not null;

    exception
      WHEN OTHERS THEN
        --P_OUT_MSG:=0;
        rollback;
        DBMS_OUTPUT.PUT_LINE('IPC�^���۰ʤ������~�G'||SQLERRM);  
        raise_application_error(-20001,'IPC�^���۰ʤ������~�G'||SQLERRM);
    end;
  end if;

end DISPATCH_RCL_APPLS;

/
