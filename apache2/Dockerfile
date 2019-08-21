FROM ubuntu:18.04

LABEL maintainer="Alankrit Srivastava <alankrit.srivastava256@webkul.com>"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get -y install apt-utils apache2 nano mysql-client \
    && a2enmod rewrite \
    && a2enmod headers \
    && export LANG=en_US.UTF-8 \
    && apt-get update \
    && apt-get install -y software-properties-common \
    && apt-get install -y language-pack-en-base \
    && LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php \
    && apt-get update \
    && apt-get -y install curl zip unzip git php7.2 php7.2-curl php7.2-intl php7.2-gd php7.2-dom php7.2-iconv php7.2-xsl php7.2-mbstring php7.2-ctype php7.2-zip php7.2-pdo php7.2-xml php7.2-bz2 php7.2-calendar php7.2-exif php7.2-fileinfo php7.2-json php7.2-mysqli php7.2-mysql php7.2-posix php7.2-tokenizer php7.2-xmlwriter php7.2-xmlreader php7.2-phar php7.2-soap php7.2-mysql php7.2-fpm php7.2-bcmath libapache2-mod-php7.2 \
    && sed -i -e"s/^memory_limit\s*=\s*128M/memory_limit = 512M/" /etc/php/7.2/apache2/php.ini \
    && rm /var/www/html/* \
    && sed -i "s/None/all/g" /etc/apache2/apache2.conf \
    && sed -i "s/80/8080/g" /etc/apache2/ports.conf /etc/apache2/sites-enabled/000-default.conf \
##install supervisor and setup supervisord.conf file
    && apt-get install -y supervisor \
    && mkdir -p /var/log/supervisor
env APACHE_RUN_USER    www-data
env APACHE_RUN_GROUP   www-data
env APACHE_PID_FILE    /var/run/apache2.pid
env APACHE_RUN_DIR     /var/run/apache2
env APACHE_LOCK_DIR    /var/lock/apache2
env APACHE_LOG_DIR     /var/log/apache2
env LANG               C

WORKDIR /var/www/html

RUN usermod -u 1000 www-data; \
curl -o /tmp/composer-setup.php https://getcomposer.org/installer; \
curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig; \
php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"; \
php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer; \
rm /tmp/composer-setup.php; \
chmod +x /usr/local/bin/composer; \
mkdir -p /root/.composer

CMD ["/usr/bin/supervisord"]

