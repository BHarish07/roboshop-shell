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

dnf install python3.11 gcc python3-devel -y &>> $LOG_FILE
VALIDATE $? "Install python"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]
then
    useradd roboshop &>> $LOG_FILE
    VALIDATE $? "Adding roboshop user.."
else
    echo -e "roboshop user already added.. $Y SKIPPING $N"
fi


rm -rf /app &>> $LOGFILE
VALIDATE $? "clean up existing directory"

mkdir /app  &>> $LOG_FILE
VALIDATE $? "Creating app directory"

curl -L -o /tmp/payment.zip https://roboshop-builds.s3.amazonaws.com/payment.zip &>> $LOG_FILE
VALIDATE $? "Downloading the payment application"

cd /app  &>> $LOG_FILE
VALIDATE $? "Moving to app directory"

unzip /tmp/payment.zip &>> $LOG_FILE
VALIDATE $? "Extracting payment application"

pip3.11 install -r requirements.txt  &>> $LOG_FILE
VALIDATE $? "Installing dependencies"

cp /home/ec2-user/roboshop-shell/payment.service /etc/systemd/system/payment.service &>> $LOG_FILE
VALIDATE $? "Copying the service file"

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "Daemon reload"

systemctl enable payment &>> $LOG_FILE
VALIDATE $? "Enabling Payment"

systemctl start payment &>> $LOG_FILE
VALIDATE $? "Starting Payment"
