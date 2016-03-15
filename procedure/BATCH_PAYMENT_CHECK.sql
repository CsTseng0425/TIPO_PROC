--------------------------------------------------------
--  DDL for Procedure BATCH_PAYMENT_CHECK
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."BATCH_PAYMENT_CHECK" (p_in_processor_no in char,
                                                p_in_ym           in varchar2,
                                                p_in_count        out int) is

begin

  select count(1)
    into p_in_count
    from batch
   where substr(process_date, 1, 5) = p_in_ym
     and step_code < '3'
     and outsourcing = p_in_processor_no
     and batch_seq = (select max(batch_seq)
                        from batch b
                       where batch.batch_no = b.batch_no);

end BATCH_PAYMENT_CHECK;

/
