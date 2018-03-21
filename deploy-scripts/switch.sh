#!/bin/bash

echo "> check current running port:"
CURRENT_PROFILE=$(curl -s http://localhost/profile)

if [ $CURRENT_PROFILE == set1 ]
then
    IDLE_PORT = 8082
elif [ $CURRENT_PROFILE == set2]
then
    IDLE_PORT = 8081

else
    echo "> No Matching Profile available."
    echo "> assign port 8081"
    IDLE_PORT = 8081

fi

echo "> switching proxy port to $IDLE_PORT."
echo "set \$service_url http://127.0.0.1:${IDLE_PORT};" | sudo tee /etc/nginx/conf.d/print-service-url.inc
echo "> Reload Nginx. All things good to go!"

sudo service nginx reload