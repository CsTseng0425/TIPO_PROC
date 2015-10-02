select * from spm63a where emp_code = 'E3133';
select * from spm63a where emp_code = 'E3119';

select * from spm63a where substr(processor_no,1,1) = 'D';  --emp_code = 'A1024';
select * from spm63a where substr(emp_code,1,1) = 'A'; -- = 'E3133';
select * from spm63 where processor_no = 'P1021';
update  spm63a set processor_no  = 'P1020' where emp_code = 'E3133';
update  spm63a set processor_no  = 'A1023' where emp_code = 'E3133';
update  spm63a set processor_no  = 'A1010' where emp_code = 'E3133';
update  spm63a set processor_no  = 'D0012' where emp_code = 'E3133';

04395
update  spm63a set processor_no  = '15173' where emp_code = 'E3133';
update  spm63a set processor_no  = 'P2121' where emp_code = 'E3133';
update  spm63a set processor_no  = '01172' where emp_code = 'E3133';



select * from batch_detail where batch_no = '1040807-P2122';
select * from batch where batch_no = '1040807-P2122';

select * from spm56 where receive_no = '10432085720';
select * from spm56 where form_file_a = 'B0400235.043';
select * from ap.sptd02 where form_file_a = 'B0400235.043';
select * from spm56 where form_file_a = 'B0400235.042';
select * from ap.sptd02 where form_file_a = 'B0400235.042';


select * from ap.spm72 where dept_no = '70012';