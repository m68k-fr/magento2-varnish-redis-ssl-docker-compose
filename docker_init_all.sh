#!/bin/bash

## todo: Add support for custom php.ini
## todo: Add support for XDebug
## todo: Add a mailhog
## todo: Add SSL support
## todo: Add ElasticSearch
## todo: Add the redis.patch

## todo: Warning if not launched from an Ubuntu distribution
## todo: Warning if no auth.json is available in the user home folder
## todo: Warning if current user is not in group www-data on host
## todo: Warning if BASE_URL is defined on host
## todo: Error if service 80,3306,8080 are running
## todo: Error if .env file is missing
## todo: Update README.md

## Test and import .env file

if [[ -f .env ]]
then
    export $(cat .env | sed 's/#.*//g' | xargs)
else
    echo ".env file is missing. See the .env.dist file for a template."
    exit 1
fi

## Check and copy existing auth.json

if [[ ! -f /home/${USER_NAME}/.composer/auth.json ]]
then
    echo "/home/$USER_NAME/.composer/auth.json is missing..."
    exit 1
fi
cp /home/${USER_NAME}/.composer/auth.json apache2/

## Check existing Magento2 Folder

if [[ -d magento2 ]]
then
    echo "magento2/ folder already exists, if you want to reinstall, please remove it.";
    exit 1
fi
mkdir magento2

## Compile & Launch docker

docker-compose up -d
if [[ $? -ne 0 ]]; then
	echo "An error occurred while launching the docker stack."
	exit 1
fi

## Create Magento 2 project
echo "Creating Magento2 project."
docker exec --user ${USER_NAME} apache2 composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition .
docker exec --user ${USER_NAME} apache2 find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
docker exec --user ${USER_NAME} apache2 find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
docker exec apache2 chown -R :www-data .
docker exec apache2 chmod u+x bin/magento

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
	echo "An error occured while installing Magento2."
	exit 1
fi

# Set developer mode

docker exec -it --user ${USER_NAME} apache2 bin/magento deploy:mode:set developer
docker exec -it --user ${USER_NAME} apache2 rm -rf generated/code/* generated/metadata/*

# Install sample data

docker exec -it --user ${USER_NAME} apache2 bin/magento sampledata:deploy
docker exec -it --user ${USER_NAME} apache2 bin/magento setup:upgrade

# Magento 2 french language pack

docker exec -it --user ${USER_NAME} apache2 composer require mageplaza/magento-2-french-language-pack:dev-master
docker exec -it --user ${USER_NAME} apache2 bin/magento cache:clean
docker exec -it --user ${USER_NAME} apache2 bin/magento cache:flush

# Enable all cache

docker exec -it --user ${USER_NAME} apache2 bin/magento cache:enable

# Create and enable cron
docker exec -it apache2 service cron start
docker exec -it --user ${USER_NAME} apache2 bin/magento cron:install
