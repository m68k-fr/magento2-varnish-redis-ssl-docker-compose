#!/bin/bash

## todo: Add the redis.patch
## todo: Warning if no auth.json is available in the user home folder
## todo: Error if service 80,443,3306,8080,8090,1025,8025 are running on host
## todo: Update README.md

## Test and import .env file

if [[ -f .env ]]
then
    export $(cat .env | sed 's/#.*//g' | xargs)
else
    echo "ERROR: .env file is missing. Please review the .env.dist file for a template."
    exit 1
fi

## Check existing Magento2 folder content

if [[ ! -d ${MAGENTO_BASE_FOLDER} ]]
then
    mkdir ${MAGENTO_BASE_FOLDER}
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Enable to create $MAGENTO_BASE_FOLDER."
        exit 1
    fi
    docker-compose down
    docker-compose up -d
fi
if [[ "$(ls -A ${MAGENTO_BASE_FOLDER})" ]]
then
    echo "ERROR: $MAGENTO_BASE_FOLDER folder is not empty, if you want to reinstall Magento, please wipe this folder first.";
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
--base-url-secure="https://${MAGENTO_BASE_URL}" \
--use-secure=1 \
--use-secure-admin=1 \
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

# Enable all cache & activate Varnish

docker exec -it --user ${USER_NAME} apache2 bin/magento cache:enable
docker exec -it --user ${USER_NAME} apache2 bin/magento setup:config:set --http-cache-hosts=varnish:6081
docker exec -it --user ${USER_NAME} apache2 bin/magento config:set --scope=default --scope-code=0 system/full_page_cache/caching_application 2

# Activate Redis Cache
cp env_redis.patch ${MAGENTO_BASE_FOLDER}
pushd  ${MAGENTO_BASE_FOLDER}
patch -p0  app/etc/env.php env_redis.patch
rm env_redis.patch
popd

# Clear All Caches

docker exec -it --user ${USER_NAME} apache2 bin/magento cache:clean
docker exec -it --user ${USER_NAME} apache2 bin/magento cache:flush
rm -rf ${MAGENTO_BASE_FOLDER}/var/cache/*
rm -fr ${MAGENTO_BASE_FOLDER}/var/page_cache/*

# Create and enable cron
docker exec -it apache2 service cron start
docker exec -it --user ${USER_NAME} apache2 bin/magento cron:install
