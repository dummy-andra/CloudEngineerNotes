#!/bin/bash

#Confluence has a built-in access logging mechanism, you can enable it and send all user actions to a log file ${catalina.home}/logs/atlassian-confluence-access.log
#This file can get hard to read
#This script will parse the log file and has the following output:
# each user has a various number of action, each action can be done numerous times
# so this script is counting every action done by user and print them by date sorted in reverse
#      13 2017-08-10 AGNecula /rest/mywork/latest/status/notification/count
#      3  2017-08-10 AGNecula /rest/analytics/1.0/publish/bulk
#      2  2017-08-10 AGNecula /admin/viewgeneralconfig.action
#      2  2017-08-10 AGNecula /rest/supportHealthCheck/1.0/check/AGNecula
#      1  2017-08-10 AGNecula /authenticate.action
#      1  2017-08-10 AGNecula /doauthenticate.action
#      1  2017-08-10 AGNecula /download/attachments/1146926/user-avatar
#      1  2017-08-10 AGNecula /rest/supportHealthCheck/1.0/dismissNotification

LOG_FILE=logs/users/atlassian-confluence-access.log

#Create log file for each user
DATADIR=logs/users
USERS=$(awk '{print $6}' $LOG_FILE | sort | uniq | grep -v "-")

# For each user will create a log file.
#In each log file we will have: no. of actions done by the user, date and the specific action

for user in $USERS 
do
   grep $user $LOG_FILE | awk '{print $1" "$8}' | sed 's/https:\/\/confluence.bandainamcoent.ro//g' | sort | uniq -c | sort -k1nr >> $DATADIR/${user}.log
done

#empty the log
>$LOG_FILE
