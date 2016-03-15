--------------------------------------------------------
--  DDL for Procedure GET_BATCH_DAY
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "S193"."GET_BATCH_DAY" (p_rec  out int
                                         ) IS
  /*
  產生外包批次資料,只處理線上公文-送核日期前一日的所有公文
  參數: checkdate : 送核日期
       is_fix: 是否凍結 ; (0: 白天批次執行,每小時加入公文到批次中; 1: 晚上執行最後一次批次新增; 之後,不再增加公文)
  
  */
BEGIN

  GET_Batch(to_char(to_number(to_char(sysdate-1,'yyyyMMdd'))-19110000),'1',p_rec);

EXCEPTION
  WHEN OTHERS THEN
  
    dbms_output.put_line('Error Code:' || SQLCODE || ' : ' || SQLERRM);
END GET_Batch_DAY;

/
