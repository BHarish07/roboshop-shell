#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
MONGODB_HOST="mongodb.harishbalike.online"  


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

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]
then
  useradd roboshop &>> $LOG_FILE
  VALIDATE $? "Adding user "
else
  echo -e "roboshop user already exists...$Y SKIPPING $N"
fi

rm -rf /app $>> $LOG_FILE
VALIDATE $? "clean up existing directory"

mkdir /app &>> $LOG_FILE
VALIDATE $? "Creating app directory"

curl -L -o /tmp/cart.zip https://roboshop-builds.s3.amazonaws.com/cart.zip  &>> $LOG_FILE
VALIDATE $? "Downloading the cart application"

cd /app  &>> $LOG_FILE
VALIDATE $? "Moving to the app directory"

unzip /tmp/cart.zip &>> $LOG_FILE
VALIDATE $? "Extracting the cart"

npm install  &>> $LOG_FILE
VALIDATE $? "Installing dependencies"

cp /home/ec2-user/roboshop-shell/cart.service /etc/systemd/system/cart.service &>> $LOG_FILE
VALIDATE $? "Copying the cart service"

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "Daemon-reload"

systemctl enable cart &>> $LOG_FILE
VALIDATE $? "Enabling cart"

systemctl start cart &>> $LOG_FILE
VALIDATE $? "Starting the cart"
