#!/bin/bash

echo "Welcome to Wheejuni Tech Automated Deploy Agent v0.1"
echo "> Deploy initiated at : $(date)"

BASE_PATH=/home/ubuntu/app/nonstop
BUILD_PATH=$(ls $BASE_PATH/build/printboard/target/*.jar)
JAR_NAME=$(basename $BUILD_PATH)

echo "> Copy .jar file..."
DEPLOY_PATH=$BASE_PATH/printboard-jar/
cp $BUILD_PATH $DEPLOY_PATH

echo "> Check currently running profile..."
CURRENT_PROFILE=$(curl -s http://localhost/profile)
echo "> current set is : $CURRENT_PROFILE"

if [ $CURRENT_PROFILE == set1 ]
then
    IDLE_PROFILE=set2
    IDLE_PORT=8082
elif [ $CURRENT_PROFILE == set2 ]
then
    IDLE_PROFILE=set1
    IDLE_PORT=8081

else
    echo "> None of profile options identical with current running profile."
    IDLE_PROFILE=set1
    IDLE_PORT=8081

fi

echo "> substitute application.jar to newest version"
IDLE_APPLICATION=$IDLE_PROFILE-printboard.jar
IDLE_APPLICATION_PATH=$DEPLOY_PATH$IDLE_APPLICATION

ln -Tfs $DEPLOY_PATH$JAR_NAME $IDLE_APPLICATION_PATH

echo "> $IDLE_PROFILE 에서 구동중인 애플리케이션 PID 확인"
IDLE_PID=$(pgrep -f $IDLE_APPLICATION)

if [ -z $IDLE_PID]
then   
    echo "> 현재 구동중인 애플리케이션이 없으므로 종료하지 않습니다."
else
    echo "> kill -15 $IDLE_PID"
    kill -15 $IDLE_PID
    sleep 5

fi

echo "> $IDLE_PROFILE 배포"
nohup java -jar -Dspring.profiles.active=$IDLE_PROFILE $IDLE_APPLICATION_PATH &

echo "> $IDLE_PROFILE 10초 후 헬스 체크 시작."
sleep 10

for retry_count in {1..10}
do
    response=$(curl -s http://localhost:$IDLE_PORT/actuator/health)
    up_count=$(echo $response | grep 'UP' | wc -l)

    if [ $up_count -ge 1 ]
    then
        echo "> Health Check Successful"
        break

    else
        echo "> health check failed."
        echo "> result: $response"

    fi

    if [ $retry_count -eq 10]
    then
        echo "> Health Check failed."
        echo "> terminate process without contacting Nginx."
        exit 1

    fi

    echo "> Health Check failed. Try for another attempt..."
    sleep 10

done

echo "> Switch Ports...."
sleep 10

/home/ubuntu/app/nonstop/switch.sh


