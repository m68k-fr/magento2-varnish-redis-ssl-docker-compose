# Magento2 (Varnish + PHP7 + Redis + SSL) cluster ready docker-compose infrastructure

## Infrastructure overview
* Container 1: Percona 5.7
* Container 2: Redis (volatile, for Magento's cache)
* Container 3: Redis (for Magento's sessions)
* Container 4: Apache 2.4 + PHP 7.2 (modphp)
* Container 5: Cron
* Container 6: Varnish 5
* Container 7: Redis (volatile, cluster nodes autodiscovery)
* Container 8: Nginx SSL terminator
* Container 9: PhpMyAdmin

Forked from: https://github.com/webkul/magento2-varnish-redis-ssl-docker-compose

## Prerequisites:

This configuration has been tested on Ubuntu 18.04 LTS  

* Docker and Docker-compose CE with non-root access (https://docs.docker.com/install/linux/linux-postinstall/)  
if you get an error message like this: "Got permission denied while trying to connect to the Docker daemon socket", fix the issue by adding your current user to the docker group and reboot:
```
sudo usermod -a -G docker $USER
```
* Download a targz Magento2 archive (https://magento.com/tech-resources/download) in the magento2/ folder
* A valid access key for Magento 2 in your https://marketplace.magento.com/customer/accessKeys/ account (repo.magento.com).  
* No running services on the following ports: 80,443,3306.
* Add the following entry to your /etc/hosts file:  
```
127.0.0.1 magento2.docker
```

## Environment:

* MYSQL host = db 
* MYSQL user = magento2
* MYSQL password = magento2
* MYSQL database = magento2
* MYSQL root password = magento2
* phpMyAdmin URL: http://magento2.docker:8090
* frontend URL: http://magento2.docker/
* backend URL: http://magento2.docker/admin/
* backend login: admin
* backend password: admin123

## Installation:

```
cd
git clone https://github.com/m68k-fr/docker-magento2.git
cd docker-magento2
./docker_init_all.sh
```

## Optional: Install the sample data

As this stack install & run cron tasks as soon as it starts, this could potentially conflicts with the sample data install and result in an error:
```
main.ERROR: Sample Data error: SQLSTATE[HY000]: General error: 1412 Table definition has changed, please retry transaction, query was: DELETE FROM catalogsearch_fulltext_scope1 WHERE (entity_id in ('68', '62', '
```

To avoid this, you need to deactivate Magento cron tasks , install the samples, then reactivate cron jobs. 

```
docker exec -it --user www-data dockermagento2_cron_1 bash
crontab -e
```
Comment the 3 Magento lines and save
```
exit
docker exec -it --user www-data dockermagento2_apache_1 bin/magento sampledata:deploy
docker exec -it --user www-data dockermagento2_apache_1 bin/magento setup:upgrade
docker exec -it --user www-data dockermagento2_cron_1 bash
crontab -e
```
Uncomment the 3 Magento lines and save 
```
exit
```
 

## Uninstall:

Be careful, this will erase everything, including docker containers, volumes and images which are not related to this project.  
Use with caution!  

```
./docker_erase_all.sh
```

## Post-Configuration:

Varnish Full Page Cache must be activated from the backend:

* select Varnish in the "caching application" combobox
* type "apache" in both "access list" and "backend host" fields
* type 80 in the "backend port" field
* save

