#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
MYSQL_HOST=mysql.harishbalike.online

VALIDATE(){
   if [ $1 -ne 0 ]
   then
        echo -e "$2...$R FAILURE $N"
        exit 1
    else
        echo -e "$2...$G SUCCESS $N"
    fi
}

if [ $USERID -ne 0 ]
then
    echo "Please run this script with root access."
    exit 1 # manually exit if error comes.
else
    echo "You are super user."
fi


dnf install maven -y &>> $LOG_FILE
VALIDATE $? "Installing Maven"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]
then
    useradd roboshop &>> $LOG_FILE
    VALIDATE $? "Adding roboshop user"
else
    echo -e "roboshop user already exist...$Y SKIPPING $N"
fi

rm -rf /app &>> $LOG_FILE
VALIDATE $? "clean up existing directory"

mkdir -p /app &>> $LOG_FILE
VALIDATE $? "Creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-builds.s3.amazonaws.com/shipping.zip &>> $LOG_FILE
VALIDATE $? "Downloading shipping application"

cd /app  &>> $LOG_FILE
VALIDATE $? "Moving to app directory"

unzip /tmp/shipping.zip &>> $LOG_FILE
VALIDATE $? "Extracting shipping application"

mvn clean package &>> $LOG_FILE
VALIDATE $? "Packaging shipping"

mv target/shipping-1.0.jar shipping.jar &>> $LOG_FILE
VALIDATE $? "Renaming the artifact"

cp /home/ec2-user/roboshop-shell/shipping.service /etc/systemd/system/shipping.service &>> $LOG_FILE
VALIDATE $? "Copying service file"

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "Daemon reload"

systemctl enable shipping  &>> $LOG_FILE
VALIDATE $? "Enabling shipping"

systemctl start shipping &>> $LOG_FILE
VALIDATE $? "Starting shipping"

dnf install mysql -y &>> $LOG_FILE
VALIDATE $? "Installing MySQL"

sed -i 's/FLUSH PRIVILEGES/-- FLUSH PRIVILEGES/' /app/schema/shipping.sql &>> $LOG_FILE


mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e "use cities" &>> $LOG_FILE
if [ $? -ne 0 ]
then
    echo "Schema is ... LOADING"
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/schema/shipping.sql &>> $LOG_FILE  
    VALIDATE $? "Loading schema"
else
    echo -e "Schema already exists... $Y SKIPPING $N"
fi

systemctl restart shipping
VALIDATE $? "Restarted Shipping"