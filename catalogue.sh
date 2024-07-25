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


dnf module disable nodejs -y &>> $LOG_FILE
VALIDATE $? "Disabling nodejs"

dnf module enable nodejs:20 -y  &>> $LOG_FILE
VALIDATE $? "Enabling nodejs20"

dnf install nodejs -y &>> $LOG_FILE
VALIDATE $? "Installing NodeJS"

useradd roboshop &>> $LOG_FILE
VALIDATE $? "Adding user "

mkdir /app &>> $LOG_FILE
VALIDATE $? "Creating directory"

curl -o /tmp/catalogue.zip https://roboshop-builds.s3.amazonaws.com/catalogue.zip  &>> $LOG_FILE
VALIDATE $? "Downloading the source code"

cd /app  &>> $LOG_FILE
VALIDATE $? "switching to the directory"

unzip /tmp/catalogue.zip &>> $LOG_FILE
VALIDATE $? "Unzipping the files"

npm install  &>> $LOG_FILE
VALIDATE $? "Installing NPM"

cp catalogue.service /etc/systemd/system/catalogue.service &>> $LOG_FILE
VALIDATE $? "Copying the service"

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "Daemon-reload"

systemctl enable catalogue &>> $LOG_FILE
VALIDATE $? "Enabling catalogue"

systemctl start catalogue &>> $LOG_FILE
VALIDATE $? "Starting the Catalogue"

cp mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOG_FILE
VALIDATE $? " copying the mongo repo"

dnf install -y mongodb-mongosh &>> $LOG_FILE
VALIDATE $? "Installing mongodb client"
 
mongosh --host mongodb.harishbalike.online </app/schema/catalogue.js &>> $LOG_FILE
VALIDATE $? " Loading the data"

