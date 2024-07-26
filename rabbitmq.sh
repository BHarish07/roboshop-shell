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


curl -s https://packagecloud.io/install/repositories/rabbitmq/erlang/script.rpm.sh | bash &>> $LOG_FILE
VALIDATE $? "Erlang script installation"

curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | bash &>> $LOG_FILE
VALIDATE $? "Server script installation"

dnf install rabbitmq-server -y  &>> $LOG_FILE
VALIDATE $? "RabbitMQ installting "

systemctl enable rabbitmq-server  &>> $LOG_FILE
VALIDATE $? "Enabling RabbitMQ"

systemctl start rabbitmq-server &>> $LOG_FILE
VALIDATE $? "Starting RabbitMQ"

sudo rabbitmqctl list_users | grep roboshop

if [ $? -ne 0 ]
then
rabbitmqctl add_user roboshop roboshop123 &>> $LOG_FILE
VALIDATE $? "Adding RabbitMQ user"
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $LOG_FILE
VALIDATE $? "Setting Permissions"
else
  echo -e "User already exists...$Y SKIPPING $N"
fi