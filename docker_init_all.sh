#!/bin/bash

## todo: Add support for XDebug
## todo: Add SSL support
## todo: Add ElasticSearch
## todo: Add the redis.patch

## todo: Warning if no auth.json is available in the user home folder
## todo: Warning if MAGENTO_BASE_URL is not defined on host
## todo: Error if service 80,443,3306,8080,8090,1025,8025 are running on host
## todo: Update README.md

## Disclaimer if not launch from Ubuntu

UNAME=$(uname | tr "[:upper:]" "[:lower:]")
# If Linux, try to determine specific distribution
if [ "$UNAME" == "linux" ]; then
    # If available, use LSB to identify distribution
    if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
        export DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
    # Otherwise, use release info file
    else
        export DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
    fi
fi
if [[ ! "$DISTRO" == "Ubuntu" ]]; then
    echo "Disclaimer: Welcome $DISTRO user. FYI, this Docker stack has only been Tested on Ubuntu..."
fi

## Test and import .env file

if [[ -f .env ]]
then
    export $(cat .env | sed 's/#.*//g' | xargs)
else
    echo "ERROR: .env file is missing. Please review the .env.dist file for a template."
    exit 1
fi

## Test if the targetted user is in www-data group

if ! groups ${USER_NAME} | grep &>/dev/null '\bwww-data\b'; then
    echo "Error: $USER_NAME user is not a member of the www-data group"
    exit 1
fi

## Check and copy the Composer auth.json file

if [[ ! -f /home/${USER_NAME}/.composer/auth.json ]]
then
    echo "ERROR: /home/$USER_NAME/.composer/auth.json is missing..."
    exit 1
fi
cp /home/${USER_NAME}/.composer/auth.json apache2/

## Check existing Magento2 Folder, Create one if none exists

if [[ -d ${MAGENTO_BASE_FOLDER} ]]
then
    echo "ERROR: $MAGENTO_BASE_FOLDER folder already exists, if you want to reinstall, please remove it.";
    exit 1
fi
mkdir ${MAGENTO_BASE_FOLDER}
if [[ $? -ne 0 ]]; then
	echo "ERROR: Enable to create $MAGENTO_BASE_FOLDER."
	exit 1
fi

## Compile & Launch the Docker stack

docker-compose up -d
if [[ $? -ne 0 ]]; then
	echo "ERROR: An error occurred while launching the docker stack."
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
--base-url="http://${MAGENTO_BASE_URL}" \
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
	echo "ERROR: An error occured while installing Magento2."
	exit 1
fi

# copy Composer auth.json file to Magento

docker exec --user ${USER_NAME} apache2 cp /home/${USER_NAME}/.composer/auth.json var/composer_home/auth.json

# Set developer mode

docker exec -it --user ${USER_NAME} apache2 bin/magento deploy:mode:set developer
docker exec -it --user ${USER_NAME} apache2 rm -rf generated/code/* generated/metadata/*

# Optional: Install the sample data (demo store)

docker exec -it --user ${USER_NAME} apache2 bin/magento sampledata:deploy
docker exec -it --user ${USER_NAME} apache2 bin/magento setup:upgrade

# Optional: Install Magento 2 french language pack

docker exec -it --user ${USER_NAME} apache2 composer require mageplaza/magento-2-french-language-pack:dev-master
docker exec -it --user ${USER_NAME} apache2 bin/magento cache:clean
docker exec -it --user ${USER_NAME} apache2 bin/magento cache:flush

# Enable all cache

docker exec -it --user ${USER_NAME} apache2 bin/magento cache:enable

# Create and enable cron
docker exec -it apache2 service cron start
docker exec -it --user ${USER_NAME} apache2 bin/magento cron:install
