--------------------------------------------------------
--  DDL for Function GET_RELATION_APPL_NO
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "S193"."GET_RELATION_APPL_NO" (p_appl_no in char)
return varchar2_tab 
is
  v_relation_appl_no_tab varchar2_tab;
begin
/*
  Last Modify Date: 104/09/18
  Desc: Object Browser- relative application list
  104/09/10: ��Х��� �����u�d�o ��
  104/09/18: �l�ͮץ���
*/
 select trim(c.appl_no)
   bulk collect
    into v_relation_appl_no_tab
   from (
   select a.appl_no
   from 
   (
      select distinct a.priority_appl_no as appl_no--�ꤺ�u���v�e��
        from spt32 a
       where a.appl_no = p_appl_no
         and a.priority_nation_id = 'TW'
         and length(trim(a.priority_appl_no)) in (9, 12)
       union
      select distinct appl_no as appl_no--�ꤺ�u���v�l��
        from spt32 a
       where a.priority_appl_no = p_appl_no
         and a.priority_nation_id = 'TW'
       union 
      select a.appl_no as appl_no--�|�o����
        from spt31 a
       where a.appl_no like substr(trim(p_appl_no),1,9) || '%'
         and length(trim(a.appl_no)) > 9
       union
      select distinct a.dep_appl_no as appl_no--��Х���
        from spt31 a, spt21 b
       where a.dep_appl_no is not null 
         and a.appl_no = b.appl_no
         and b.appl_no = p_appl_no
       --  and substr(b.appl_no, 4, 1) = '1' 
         and b.type_no in ('11000', '11002', '11003', '11007', '11010')
       union
      select distinct b.appl_no as appl_no--��Фl��
        from spt31 a, spt21 b 
       where a.dep_appl_no = p_appl_no
         and a.appl_no = b.appl_no
         and b.type_no in ('11000', '11002', '11003', '11007', '11010')
       union
      select distinct a.dep_appl_no as appl_no--���Υ���
        from spt31 a, spt21 b
       where a.dep_appl_no is not null
         and a.appl_no = b.appl_no
         and b.appl_no = p_appl_no
         and b.type_no in ('12000', '11092')
       union
      select distinct b.appl_no as appl_no--���Τl��
        from spt31 a, spt21 b
       where a.dep_appl_no = p_appl_no
         and a.appl_no = b.appl_no
         and b.type_no in ('12000', '11092')
      union 
      select appl_no  as appl_no--����
      from spt31 
      where substr(p_appl_no,10,1) in ('D','N')
       and trim(appl_no) = substr(p_appl_no,1,9)
    )a, spt31 b
   where trim(a.appl_no) != trim(p_appl_no)
     and b.appl_no = rpad(a.appl_no, 15, ' ')
     and b.sc_flag = '0'
       order by a.appl_no
       ) c
   group by c.appl_no;
  return v_relation_appl_no_tab;
end get_relation_appl_no;

/
