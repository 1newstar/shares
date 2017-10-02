################################################################
## Author : Suman Adhikari
## Purpose : Download the toadys share traded price from web
################################################################

## Set the temporary directory to keep downloaded file
DEST_DIR=$HOME/shares/temp

## Function to handle exception and errors while running the script
errorReport(){
       echo "########################################################"
       echo "Error during Running Scripts"
       echo "Error: $1 "
       echo "########################################################"
       exit 1
}

## If the directory doesnot exits then create it
mkdir -p $DEST_DIR

## If anything went wrong report error and exit from script
if [ $? -ne 0 ] ; then
    errorReport "Temporary directory cannot be created. Aborting...."
fi

## Change to the temporary directory
cd $DEST_DIR 

## Remove all the contents from the temporary directory
rm -f *

echo " "
echo "##############################"
echo "  Downloading Data from WEB   "
echo "##############################"
echo " "


## Download the pricelist file from web
curl "http://www.sharesansar.com/c/tod/today-share-price.html" >> todayprice.html

## If anything went wrong report error and exit from script
if [ $? -ne 0 ] ; then
    errorReport "Temporary directory cannot be created. Aborting...."
fi

## Get the current date
CURDATE=`date +%d/%m/%Y`

## Extract the useful information from the html file using sed
cat todayprice.html |  ## Cat the fine in shell
grep result--todays-share-price | sed -e '1d' | ## Gret the line containg text result--todays-share-price
sed -e 's/^.*area\"><table/<table/' | ## Replace the the all text before area\"><table with <table
sed 's/<\/table>.*/<\/table>/' |  ## Replace all the text after </table> with </table>
sed 's/^.*<tbody/<tbody/;s/<\/tbody>.*/<\/tbody>/' | ## Replace all the text before and after <tbody> with <tbody> and </tbody> with </tbody> respectively
sed '$ d;s/<\/tr>/<\/tr>\n/g;s/<[^>]*>/_/g'| ## Delete the last line and break line with end <tr> and remove all the html tags replacing with _
sed 's/__*/_/g;s/^_//' | ## Replace multiple occurance of _ with _ , delete first occurnace of _
sed 's/_$//;s/,//g' | ## Remove last occurance of _ and every , 
sed "s:[0-9]*:$CURDATE:;s:_:,:g;$ d" | ## Replace the starting numeric value with current date
sed -r 's/(([^,]+*,){8}).*/\1/' | sed 's/,$//g' > price.txt ## delete all the characters after occurnace of 8 consequence , and also remove last , 

##
## Start Uploading the data into the database
##

## Create the table if it doesnot exits
read -d '' createShareTable<< EOF
DECLARE 
                tableStmt varchar2(4000);
                tblOut number(2);
BEGIN
        select count(*) into tblOut from dba_tables where table_name='SHARESANSAR';
        IF tblOut <= 0 THEN
                tableStmt:='CREATE TABLE SHARESANSAR (
		P_DATE VARCHAR2(15), 
		C_NAME VARCHAR2(100), 
		C_SYMBOL VARCHAR2(15), 
		OPEN_PRICE VARCHAR2(10), 
		MAX_PRICE VARCHAR2(10), 
		MIN_PRICE VARCHAR2(10), 
		CLOSE_PRICE VARCHAR2(10), 
		VOL_TRADED VARCHAR2(10)
		)';
                EXECUTE IMMEDIATE tableStmt;
        END IF;
END;
/
EOF

createDB(){
${1}/bin/sqlplus -s /nolog << __EOF__ > /dev/null 2>&1
conn stock/stock@//192.168.179.113:1521/nsdb
set pagesize 0 feedback off verify off echo off;
$createShareTable
__EOF__
}

##
## Create the database
##
createDB $ORACLE_HOME

echo " "
echo "##############################"
echo "   Loading Data in Database   "
echo "##############################"

##
## Append the rows in the table from flat file to database
##
sqlldr stock/stock@//scan12c:1521/nsdb control=/home/oracle/shares/sqlldr.ctl silent=all

#echo -e "\n"
echo "##############################"
echo "     Operation Complted       "
echo "##############################"
echo " "
