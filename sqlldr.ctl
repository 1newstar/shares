LOAD DATA
INFILE '/home/oracle/shares/temp/price.txt'
BADFILE '/home/oracle/shares/temp/error.txt'
APPEND
INTO TABLE SHARESANSAR
FIELDS TERMINATED BY ","
(
P_DATE, 		
C_NAME,		
C_SYMBOL,		
OPEN_PRICE,		
MAX_PRICE,		
MIN_PRICE,		
CLOSE_PRICE,	
VOL_TRADED
)
