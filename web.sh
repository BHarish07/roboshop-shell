#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

VALIDATE(){
    if [ $1 -ne 0 ]
    then 
      echo -e "$2....$R FAILURE $N"
      exit 1
    else
      echo -e "$2....$G SUCCESS $N"
    fi 

}

if [ $USERID -ne 0 ]
then
 echo "Please run this script with root access..."
 exit 1
else
  echo "You are super user.."
fi


dnf install nginx -y &>> $LOG_FILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>> $LOG_FILE
VALIDATE $? "Enabling Nginx"

systemctl start nginx &>> $LOG_FILE
VALIDATE $? "Starting Nginx"

rm -rf /usr/share/nginx/html/* &>> $LOG_FILE
VALIDATE $? "Removing the default site"

curl -o /tmp/web.zip https://roboshop-builds.s3.amazonaws.com/web.zip &>> $LOG_FILE
VALIDATE $? "Downloading web application"

cd /usr/share/nginx/html &>> $LOG_FILE
VALIDATE $? "Moving to html directory"

unzip /tmp/web.zip &>> $LOG_FILE
VALIDATE $? "Extracting web application"

cp /home/ec2-user/roboshop-shell/roboshop.conf /etc/nginx/default.d/roboshop.conf  &>> $LOG_FILE
VALIDATE $? "Copying roboshop conf"

systemctl restart nginx  &>> $LOG_FILE
VALIDATE $? "Restarting Nginx"