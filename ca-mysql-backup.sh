#!/bin/bash

# Author: Ashley Cawley // acawley@cloudabove.com // @cloudabove

# Description: A script to backup MySQL databases to individual
#		.sql.gz files, whilst excluding the following:
#		- information_schema
#		- performance_schema
#		- sys
#		- mysql
#		Also allows the user to specify retention policy

# User Configurable Variables
BACKUP_DESTINATION="/root/scripts/backups/"
NUMBER_OF_HOURLY_BACKUPS_TO_RETAIN="5"

# Variables
MYSQL_DATABASES=$(mysql -N -s -e "show databases")
EXCLUSIONS=(information_schema performance_schema sys mysql) # Names excluded from the dump

# Functions
function DATE_AND_TIME () {
	date +%d-%m-%Y_%H-%M
}

# Main Script

for EXCLUDED_NAME in "${EXCLUSIONS[@]}"
do
	MYSQL_DATABASES=$(echo "$MYSQL_DATABASES" | sed s/"$EXCLUDED_NAME"//g)
done

array1=(`echo $MYSQL_DATABASES`)


for DBNAME in "${array1[@]}"
do
	mkdir -p $BACKUP_DESTINATION/$DBNAME
	mysqldump $DBNAME | gzip -c > $BACKUP_DESTINATION/$DBNAME/${DBNAME}-`DATE_AND_TIME`.sql.gz

	NUMBER_OF_CURRENT_BACKUPS=$(ls $BACKUP_DESTINATION/$DBNAME/ | wc -w)

	echo "Number of $DBNAME backups: $NUMBER_OF_CURRENT_BACKUPS"

	if [ "$NUMBER_OF_CURRENT_BACKUPS" -gt "$NUMBER_OF_HOURLY_BACKUPS_TO_RETAIN" ]
	then
		echo "Number of $DBNAME backups exceeds retention policy!!!!"
	
		# Loop to remove oldest backup first
		while [ "$NUMBER_OF_CURRENT_BACKUPS" -gt "$NUMBER_OF_HOURLY_BACKUPS_TO_RETAIN" ]
		do
			ARRAY_OF_BACKUP_FILES_OLDEST_FIRST=(`ls -tr $BACKUP_DESTINATION/$DBNAME/`)
			echo "Item on the list to purge: ${ARRAY_OF_BACKUP_FILES_OLDEST_FIRST[0]}"
			rm -f "$BACKUP_DESTINATION/$DBNAME/${ARRAY_OF_BACKUP_FILES_OLDEST_FIRST[0]}"
			
			# Re-calculate number of backups for while loop:
			NUMBER_OF_CURRENT_BACKUPS=$(ls $BACKUP_DESTINATION/$DBNAME/ | wc -w)
		done
	fi

done

# Exit
exit 0 
