# Magento2 (Apache2.4 + PHP7 + Varnish + Redis + ElasticSearch + SSL)

## Infrastructure overview
* Container 1: Nginx (SSL reverse proxy)
* Container 2: Redis (volatile, for Magento's cache)
* Container 3: Varnish (volatile, for Magento's full page cache)
* Container 4: Apache 2.4 + PHP 7.2 (modphp)
* Container 5: PhpMyAdmin
* Container 6: Percona 5.7
* Container 7: ElasticSearch 6
* Container 8: Mailhog (Mail collector)

## Disclaimer:

**This configuration has only been tested on Ubuntu 18.04 LTS.**  
**Don't expect too much, if you're not using a Debian based distribution...** 

## Prerequisites:

* Docker and Docker-compose CE with non-root access (https://docs.docker.com/install/linux/linux-postinstall/)  
if you get an error message like this: "Got permission denied while trying to connect to the Docker daemon socket", fix the issue by adding your current user to the docker group and reboot:
```
sudo usermod -aG docker $USER
```
* On your host, no service running on the following ports: 80,443,3306,8080,8090,1025,8025,9200,6379,6081,6082.  
So, don't forget to shut down conflicting services on your host before starting.

* Having a valid public/private Magento2 couple keys:  
https://devdocs.magento.com/guides/v2.3/install-gde/prereq/connect-auth.html  

* Add the following entry to your /etc/hosts file:  
```
127.0.0.1 magento2.docker
```

* Add your current user to the www-data group
```
sudo usermod -aG www-data $USER
```
* On your host, you need to boost VM Max Count for Elasticsearch
```
sudo sysctl -w vm.max_map_count=262144
```


## Installation:

```
git clone https://github.com/m68k-fr/magento2-varnish-redis-ssl-docker-compose.git
cd magento2-varnish-redis-ssl-docker-compose
cp .env.dist .env
```

Edit the user/group settings and the Magento Keys couple in the .env file.

```
./docker_init.sh 
./docker_install_magento.sh
```

## Environment:

* MYSQL host = db 
* MYSQL user = magento2
* MYSQL password = magento2
* MYSQL database = magento2
* MYSQL root password = magento2
* phpMyAdmin URL: http://magento2.docker:8090
* Magento frontend URL: http://magento2.docker/
* Magento backend URL: http://magento2.docker/admin/
* Magento backend login: admin
* Magento backend password: admin123
* MailHog: http://magento2.docker:8025
 
## Post-Configuration:

You need to configure Magento to use Elasticsearch:  
https://devdocs.magento.com/guides/v2.3/config-guide/elasticsearch/configure-magento.html  
Elasticsearch Server Hostname: elasticsearch 

## Docker 911 Survival Guide:
```
# shut down all services:
docker-compose down
# Start all services:
docker-compose up -d
# List all running containers:
docker ps
# Opening a terminal on the apache/php container:
docker exec -ti --user ${USER_NAME} apache2 bash
```

## Uninstall:
Shut down all containers, delete compiled images, Docker networks, Volumes etc.
```
./docker_erase_all.sh
```
