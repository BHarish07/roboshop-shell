#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
MYSQL_HOST="mysql.harishbalike.online"


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

dnf install maven -y &>> $LOG_FILE
VALIDATE $? "Installing Maven"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]
then 
    useradd roboshop  &>> $LOG_FILE
    VALIDATE $? "Adding roboshop user"
else
    echo -e "roboshop user already exists..$Y SKIPPING $N"
fi

rm -rf /app &>> $LOG_FILE
VALIDATE $? "Clean up the app directory"

mkdir /app  &>> $LOG_FILE
VALIDATE $? "Creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-builds.s3.amazonaws.com/shipping.zip  &>> $LOG_FILE
VALIDATE $? "Downloading shipping applocation"

cd /app  &>> $LOG_FILE
VALIDATE $? "Moving to the app directory"

unzip /tmp/shipping.zip  &>> $LOG_FILE
VALIDATE $? "Extracting shipping application"

mvn clean package  &>> $LOG_FILE
VALIDATE $? "Packaging Shipping"

mv target/shipping-1.0.jar shipping.jar  &>> $LOG_FILE
VALIDATE $? "Renaming the artifact"

cp /home/ec2-user/roboshop-shell/shipping.service /etc/systemd/system/shipping.service &>> $LOG_FILE
VALIDATE $? "Copying the service file "

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "Daemon reload"

systemctl enable shipping  &>> $LOG_FILE
VALIDATE $? "Enabling Shipping"

systemctl start shipping  &>> $LOG_FILE
VALIDATE $? "Starting Shipping"

dnf install mysql -y  &>> $LOG_FILE
VALIDATE $? "Installing MYSQL"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e "use cities" &>> $LOG_FILE
if [ $? -ne 0 ]
then
    echo "Schema is Loading...."
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/schema/shipping.sql  &>> $LOG_FILE
    VALIDATE $? "Loading Schema" #if loading schema failed-->login to mysql server and use FLUSH HOSTS; and run the script
else
    echo -e "Schema is already exists..$Y SKIPPING $N"
fi


systemctl restart shipping &>> $LOG_FILE
VALIDATE $? "Restarting shipping"

