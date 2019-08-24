#!/bin/bash

## todo: Test if service 80,3306,8080 are running
## todo: Warning if current user is not in group www-data on host
## todo: Warning if BASE_URL is defined on host
## todo: Add the redis.patch
## todo: Save magento access key in /home/${USER}/.composer/auth.json
## todo: Update README.md
## todo: Add support for XDebug
## todo: Add a mail catcher

## Test and import .env file

if [[ -f .env ]]
then
    export $(cat .env | sed 's/#.*//g' | xargs)
else
    echo ".env file is missing. See the .env.dist file for a template."
    exit 1
fi

## Check existing Magento2 Folder

if [[ ! -f magento2_archive/${ARCHIVE} ]]
then
    echo "$ARCHIVE is missing..."
    exit 1
fi

if [[ -d magento2 ]]
then
    echo "magento2/ folder already exists, if you want to reinstall, please remove it.";
    exit 1
fi

## Copy Magento2 Archive

mkdir magento2
cp magento2_archive/${ARCHIVE} magento2/
if [[ $? -ne 0 ]]; then
	echo "Unable to copy /magento2_archive/${ARCHIVE} to magento2/"
	exit 1
fi

## Compile & Launch docker

docker-compose up -d
if [[ $? -ne 0 ]]; then
	echo "An error occurred while launching the docker stack."
	exit 1
fi

## Unpack Magento Archive
echo "Unpacking your Magento2 Archive."
docker exec --user ${USER_NAME} apache2 tar xzf ${ARCHIVE}
docker exec --user ${USER_NAME} apache2 rm ${ARCHIVE}
docker exec --user ${USER_NAME} apache2 find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
docker exec --user ${USER_NAME} apache2 find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
docker exec apache2 chown -R :www-data .
docker exec apache2 chmod u+x bin/magento

## Sleeping 30 seconds

echo "Sleeping 30 seconds to wait for all containers to fully initialize."
sleep 30

## Install Magento

docker exec --user ${USER_NAME} apache2 bin/magento setup:install \
--base-url="http://${BASE_URL}" \
--db-host='db' \
--db-name="${MYSQL_DATABASE}" \
--db-user="${MYSQL_USER}" \
--db-password="${MYSQL_PASSWORD}" \
--backend-frontname='admin' \
--admin-firstname='admin' \
--admin-lastname='admin' \
--admin-email='admin@admin.com' \
--admin-user='admin' \
--admin-password='admin123' \
--language="${LANGUAGE}" \
--currency='EUR' \
--timezone="${TIMEZONE}" \
--use-rewrites=1 \
 \

if [ $? -ne 0 ]; then
	echo "An error occured installing Magento2."
	exit 1
fi

# Set developer mode

docker exec -it --user ${USER_NAME} apache2 bin/magento deploy:mode:set developer
docker exec -it --user ${USER_NAME} apache2 rm -rf generated/code/* generated/metadata/*

# Magento 2 french language pack

docker exec -it --user ${USER_NAME} apache2 composer require mageplaza/magento-2-french-language-pack:dev-master
docker exec -it --user ${USER_NAME} apache2 bin/magento cache:clean
docker exec -it --user ${USER_NAME} apache2 bin/magento cache:flush

# Enable all cache

docker exec -it --user ${USER_NAME} apache2 bin/magento cache:enable

# Create and enable cron
docker exec -it apache2 service cron start
docker exec -it --user ${USER_NAME} apache2 bin/magento cron:install

