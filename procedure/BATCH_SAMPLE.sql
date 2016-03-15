--------------------------------------------------------
--  DDL for Procedure BATCH_SAMPLE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_SAMPLE" (p_in_batch_no  in varchar2,
                                         p_in_batch_seq in number
                                        ) IS

BEGIN
/*
 Desc: random check
 ModifyDate : 104/07/14
 104/07/14 : cancel to get the receive which has been rejected
*/
  update batch_detail a
     set is_check = '1'
   where exists (select 1
            from (select *
                    from (select *
                            from batch_detail
                           where batch_no = p_in_batch_no
                             and batch_seq = p_in_batch_seq
                             and is_check = '0'
                           order by dbms_random.random)
                   where rownum <= (select spot_check_qty(count(1)) --應抽數量
                                      from batch_detail
                                     where  batch_no = p_in_batch_no
                                       and batch_seq = p_in_batch_seq) -
                         (select count(1) --已抽數量 
                                      from batch_detail
                                     where batch_no = p_in_batch_no
                                       and batch_seq = p_in_batch_seq
                                       and is_check = '1')) b
           where a.batch_no = b.batch_no
             and a.batch_seq = b.batch_seq
             and a.receive_no = b.receive_no
             and A.Is_Rejected = '0'
             );
             
     

END BATCH_SAMPLE;

/
