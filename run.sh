#! /bin/bash
# Docker container version
if [ -z "$1" ]; then
        export VERSION="latest";
else
        export VERSION=$1;
fi
echo "Using version: $VERSION"

# Default application name
if [ -z "$2" ]; then
        export APP_NAME="AD-Capital";
else
        export APP_NAME=$2;
fi
echo "Application Name: $APP_NAME"

echo -n "adcapitaldb: "; docker run --name adcapitaldb -e MYSQL_ROOT_PASSWORD=welcome1 -p 3306:3306 -d mysql
echo -n "rabbitmq: "; docker run -d --name rabbitmq -e RABBITMQ_DEFAULT_USER=guest -e RABBITMQ_DEFAULT_PASS=guest -p 5672:5672 -p 15672:15672 rabbitmq:3.5.4-management
sleep 10

echo -n "rest: "; docker run --name rest -h ${APP_NAME}-rest -e create_schema=true -e rest=true -p 8081:8080\
	-e ACCOUNT_NAME=${ACCOUNT_NAME} -e ACCESS_KEY=${ACCESS_KEY} -e EVENT_ENDPOINT=${EVENT_ENDPOINT} \
	-e CONTROLLER=${CONTR_HOST} -e APPD_PORT=${CONTR_PORT} \
	-e NODE_NAME=${APP_NAME}_REST_NODE -e APP_NAME=$APP_NAME -e TIER_NAME=Authentication-Service \
	-e MACHINE_PATH_1=${MACHINE_PATH_1} -e MACHINE_PATH_2=${MACHINE_PATH_2} \
	--link adcapitaldb:adcapitaldb -d appdynamics/adcapital-tomcat:$VERSION
sleep 10

echo -n "portal: "; docker run --name portal -h ${APP_NAME}-portal -e portal=true -p 8082:8080\
	-e ACCOUNT_NAME=${ACCOUNT_NAME} -e ACCESS_KEY=${ACCESS_KEY} -e EVENT_ENDPOINT=${EVENT_ENDPOINT} \
	-e CONTROLLER=${CONTR_HOST} -e APPD_PORT=${CONTR_PORT} \
	-e NODE_NAME=${APP_NAME}_PORTAL_NODE -e APP_NAME=$APP_NAME -e TIER_NAME=Portal-Services \
	-e MACHINE_PATH_1=${MACHINE_PATH_1} -e MACHINE_PATH_2=${MACHINE_PATH_2} \
	--link rest:rest --link rabbitmq:rabbitmq -d appdynamics/adcapital-tomcat:$VERSION
sleep 10

echo -n "verification: "; docker run --name verification -h ${APP_NAME}-verification -p 8083:8080\
	-e ACCOUNT_NAME=${ACCOUNT_NAME} -e ACCESS_KEY=${ACCESS_KEY} -e EVENT_ENDPOINT=${EVENT_ENDPOINT} \
	-e CONTROLLER=${CONTR_HOST} -e APPD_PORT=${CONTR_PORT} \
	-e NODE_NAME=${APP_NAME}_VERIFICATION_NODE -e APP_NAME=$APP_NAME -e TIER_NAME=ApplicationProcessor-Services \
	-e MACHINE_PATH_1=${MACHINE_PATH_1} -e MACHINE_PATH_2=${MACHINE_PATH_2} \
	--link adcapitaldb:adcapitaldb --link rabbitmq:rabbitmq -d appdynamics/adcapital-applicationprocessor:$VERSION
sleep 10

echo -n "processor: "; docker run --name processor -h ${APP_NAME}-processor -e processor=true -p 8084:8080\
	-e ACCOUNT_NAME=${ACCOUNT_NAME} -e ACCESS_KEY=${ACCESS_KEY} -e EVENT_ENDPOINT=${EVENT_ENDPOINT} \
	-e CONTROLLER=${CONTR_HOST} -e APPD_PORT=${CONTR_PORT} \
	-e NODE_NAME=${APP_NAME}_PROCESSOR_NODE -e APP_NAME=$APP_NAME -e TIER_NAME=LoanProcessor-Services \
	-e MACHINE_PATH_1=${MACHINE_PATH_1} -e MACHINE_PATH_2=${MACHINE_PATH_2} \
	--link adcapitaldb:adcapitaldb --link rabbitmq:rabbitmq -d appdynamics/adcapital-tomcat:$VERSION
sleep 10

echo -n "queuereader: "; docker run --name queuereader -h ${APP_NAME}-queuereader -p 8085:8080\
  	-e ACCOUNT_NAME=${ACCOUNT_NAME} -e ACCESS_KEY=${ACCESS_KEY} -e EVENT_ENDPOINT=${EVENT_ENDPOINT} \
  	-e CONTROLLER=${CONTR_HOST} -e APPD_PORT=${CONTR_PORT} \
  	-e NODE_NAME=${APP_NAME}_QUEUEREADER_NODE -e APP_NAME=$APP_NAME -e TIER_NAME=QueueReader-Services \
	-e MACHINE_PATH_1=${MACHINE_PATH_1} -e MACHINE_PATH_2=${MACHINE_PATH_2} \
  	--link rabbitmq:rabbitmq -d appdynamics/adcapital-queuereader:$VERSION
	sleep 10

echo -n "adcapitalload: "; docker run --name=adcapitalload --link portal:portal --link processor:processor -d appdynamics/adcapital-load

