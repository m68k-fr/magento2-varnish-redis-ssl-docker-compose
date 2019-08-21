#!/bin/bash

ARCHIVE=Magento-CE-2.3.2_sample_data-2019-06-13-04-34-43.tar.gz

## Copy Magento2 Archive

if [[ ! -f magento2_archive/${ARCHIVE} ]]
then
    echo "$ARCHIVE is missing..."
    exit
fi
if [[ -d magento2 ]]
then
echo "Le dossier magento2 existe deja !";
exit
fi

## Unpack Magento2 Archive

mkdir magento2
cp magento2_archive/${ARCHIVE} magento2/
cd magento2/
tar xzf ${ARCHIVE}
rm ${ARCHIVE}
cd ..

## Launch docker

docker-compose up -d
if [[ $? -ne 0 ]]; then
	echo "An error occurred while launching the docker stack."
	exit
fi

## Magento binary as executable

docker exec --user www-data apache2 chmod a+x bin/magento

## Sleeping 45 seconds

echo "Sleeping 45 seconds to wait for all containers to fully initialize."
sleep 45


## Install Magento

docker exec --user www-data apache2 bin/magento setup:install \
--base-url='http://magento2.docker' \
--db-host='db' \
--db-name='magento2' \
--db-user='root' \
--db-password='magento2' \
--backend-frontname='admin' \
--admin-firstname='admin' \
--admin-lastname='admin' \
--admin-email='admin@admin.com' \
--admin-user='admin' \
--admin-password='admin123' \
--language='fr_FR' \
--currency='EUR' \
--timezone='Europe/Paris' \
--use-rewrites=1 \
 \

if [ $? -ne 0 ]; then
	echo "An error occured installing Magento2."
	exit
fi

# Set developer mode

docker exec -it --user www-data apache2 bin/magento deploy:mode:set developer
docker exec -it --user www-data apache2 rm -rf generated/code/* generated/metadata/*

# Magento 2 french language pack

docker exec -it --user www-data apache2 composer require mageplaza/magento-2-french-language-pack:dev-master
docker exec -it --user www-data apache2 bin/magento cache:clean
docker exec -it --user www-data apache2 bin/magento cache:flush

# Enable all cache

docker exec -it --user www-data apache2 bin/magento cache:enable

# Create and enable cron
docker exec -it apache2 service cron start
docker exec -it --user www-data apache2 bin/magento cron:install

