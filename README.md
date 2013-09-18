##[Tonjoo](http://tonjoo.com "Tonjoo") - Bash Backup Rotation Script

###Description
This script allow you to create a rotation backup for your files and mysql database.  

The backup will be split into 3 type of backup :

- Daily backup
- Weekly backup (default : perform every sixth day of the week)
- Monthly backup (default : perform every first day of the month)

Each type of backup will have a backup retention(copy). The default retention for every type of backup can be configured. 

The backup retention default day is :

- Daily backup : 7 Day
- Weekly backup : 30 Day
- Monthly backup : 90 Day

##Usage Instruction

1. Download the `backup_rotation.sh` script into your NIX server.
2. Open the file using your favourite editor (ex :`nano` or `vi`)

		nano backup_rotation.sh

	or
	
		vi backup_rotation.sh	 

3. Edit the configuration file. MYSQL configuration, BACKUP\_DIR, TARGET\_DIR must be filled. 

		# Edit this configuration !! 
		
		# MYSQL Configuration
		# Enter all credential within the ' ' single quote !
		
		USER='db_user'
		PASSWORD='db_password'
		DATABASE='db_database'
		HOST='127.0.0.1'
		
		# The backup directory , do not end the directory with backslash ! 
		BACKUP_DIR=/your_backup_directory_target
		
		# The directory to be backup , do not end the directory with backslash ! 
		TARGET_DIR=/folder_to_backup
		
		# Admin email
		MAIL="your_email@email.com"
		
		# Number of day the daily backup keep
		RETENTION_DAY=7
		
		# Number of day the weekly backup keep
		RETENTION_WEEK=30
		
		# Number of day the monthly backup keep
		RETENTION_MONTH=90
		
		#Backup every first day of the month (day of month)
		MONTH_DAY=1
		
		#Backup every sixth day of the week (day of week)
		WEEK_DAY=6
		
		# End configuration

4. Make the script executable

		chmod +x backup_rotation.sh

5. Run the script 

		sh backup_rotation.sh

##Contribute

Everybody is welcome to fork and contribute. If you need to pull something just post it on the message board.