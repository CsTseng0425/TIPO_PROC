--------------------------------------------------------
--  DDL for Procedure LIST_SECTION_UNSIGN
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."LIST_SECTION_UNSIGN" (p_out_list out sys_refcursor) is
begin
  /*
  DESC: 紙本未簽-全科統計
   Modify Date : 105/02/03
  
  */
  OPEN p_out_list FOR
    SELECT spm63.processor_no,
           spm63.NAME_C,
           COUNT(CASE
                   WHEN SUBSTR(spt21.RECEIVE_NO, 4, 1) = '2' THEN
                    1
                   ELSE
                    NULL
                 END) AS UNSIGN_NEW_P,
           COUNT(CASE
                   WHEN SUBSTR(spt21.RECEIVE_NO, 4, 1) = '3' THEN
                    1
                   ELSE
                    NULL
                 END) AS UNSIGN_APPEND_P
      FROM SPT21
      JOIN spt23
        ON spt21.receive_no = spt23.receive_no
       AND spt21.trans_seq = spt23.data_seq
      LEFT JOIN SPM63
        on spm63.processor_no = spt23.object_to
     WHERE spt23.TRANS_NO = '912'
       AND spt23.ACCEPT_DATE IS NULL
       AND spt23.OBJECT_TO IN (SELECT PROCESSOR_NO
                                 FROM SPM63
                                WHERE DEPT_NO = '70012'
                                  AND QUIT_DATE IS NULL)
       AND (spt21.process_result = '57001' or spt21.process_result is null)
     group by spm63.processor_no, spm63.NAME_C
     order by spm63.processor_no;

end List_section_UNSIGN;

/
