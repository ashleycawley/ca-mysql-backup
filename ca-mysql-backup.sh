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

# Strip out excluded databases from the list of database names
for EXCLUDED_NAME in "${EXCLUSIONS[@]}"
do
	MYSQL_DATABASES=$(echo "$MYSQL_DATABASES" | sed s/"$EXCLUDED_NAME"//g)
done

# Switches list of databases from a variable to an array for easier handling
array1=(`echo $MYSQL_DATABASES`)

# Loop for handling each database backup and purging of obsolete backups
for DBNAME in "${array1[@]}"
do
	# Creates destination folder specific to individual database and backs-up into it
	mkdir -p $BACKUP_DESTINATION/$DBNAME
	mysqldump $DBNAME | gzip -c > $BACKUP_DESTINATION/$DBNAME/${DBNAME}-`DATE_AND_TIME`.sql.gz

	# Takes note of the number of backups within that folder
	NUMBER_OF_CURRENT_BACKUPS=$(ls $BACKUP_DESTINATION/$DBNAME/ | wc -w)

	echo "Number of $DBNAME backups: $NUMBER_OF_CURRENT_BACKUPS"

	# Checks to see if the number of backups exceeds that of the retention policy
	if [ "$NUMBER_OF_CURRENT_BACKUPS" -gt "$NUMBER_OF_HOURLY_BACKUPS_TO_RETAIN" ]
	then
		echo "Number of $DBNAME backups exceeds retention policy!!!!"
	
		# If the number of backups exceeds then initiates loop to remove old backups
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
