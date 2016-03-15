--------------------------------------------------------
--  DDL for Procedure GET_BATCH_DAY
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."GET_BATCH_DAY" (p_rec  out int
                                         ) IS
  /*
  ���ͥ~�]�妸���,�u�B�z�u�W����-�e�֤���e�@�骺�Ҧ�����
  �Ѽ�: checkdate : �e�֤��
       is_fix: �O�_�ᵲ ; (0: �դѧ妸����,�C�p�ɥ[�J�����妸��; 1: �ߤW����̫�@���妸�s�W; ����,���A�W�[����)
  
  */
BEGIN

  GET_Batch(to_char(to_number(to_char(sysdate-1,'yyyyMMdd'))-19110000),'1',p_rec);

EXCEPTION
  WHEN OTHERS THEN
  
    dbms_output.put_line('Error Code:' || SQLCODE || ' : ' || SQLERRM);
END GET_Batch_DAY;

/
