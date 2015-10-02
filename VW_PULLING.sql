
  CREATE OR REPLACE FORCE VIEW "S193"."VW_PULLING" ("APPL_NO", "RECEIVE_NO", "SKILL", "RETURN_NO") AS 
  select receive.appl_no, receive.receive_no ,
       case 
            when spt21.type_no = '10000' and substr(receive.receive_no ,4,1)='2' then 'INVENTION'
            when spt21.type_no = '10002' and substr(receive.receive_no ,4,1)='2' then 'UTILITY'
            when spt21.type_no = '10003' and substr(receive.receive_no ,4,1)='2' then 'DESIGN' 
            when spt21.type_no = '10007' and substr(receive.receive_no ,4,1)='2' then 'DERIVATIVE'
         --   when spt21.type_no in ('15000','15002','21100','21300','21302','25100','25102') then 'IMPEACHMENT'
            when (spt21.type_no between '27000' and '27050' 
              or spt21.type_no between '27502' and '28224' 
              or spt21.type_no between '28302' and '28600' 
              or spt21.type_no between '28800' and '28804'
              or spt21.type_no between '29094' and '29205'
              or spt21.type_no between '38300' and '38804'
              or spt21.type_no between '39206' and '39220') then 'REMEDY'
            when spt21.type_no in ('30100','30104','30500') then  'PETITION'
            when spt21.type_no in ('12000','11092')  and substr(receive.receive_no ,4,1)='2' then 'DIVIDING'
            when spt21.type_no in ('11000','11002','11003','11007','11010') and substr(receive.receive_no,4,1) = '2' then  'CONVERTING'
            when ( select count(1) from spt32  where spt32.PRIORITY_NATION_ID = 'TW' and spt32.appl_no = receive.appl_no ) > 0
                  and substr(receive.receive_no,4,1) = '2' then  'MISC_AMEND'
             when substr(receive.receive_no,4,1) = '3' then  'MISC_AMEND'
             else 'ALL'
      end skill , RETURN_NO
from receive 
join spt21 on receive.receive_no = spt21.receive_no
where step_code = '0'
and doc_complete = '1'
and return_no not in ('4','A','B','C','D');
