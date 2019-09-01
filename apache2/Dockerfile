FROM ubuntu:18.04

LABEL maintainer="llemoullec@gmail.com>"

ARG TIMEZONE
ARG LOCALES
ARG LANGUAGE

ARG USER_NAME
ARG USER_UID
ARG GROUP_NAME
ARG GROUP_UID

ARG DEBIAN_FRONTEND=noninteractive

# Set the locale
RUN apt-get clean && apt-get update && apt-get install -y locales
RUN locale-gen ${LOCALES} \
    && dpkg-reconfigure locales
ENV LANG ${LOCALES}
ENV LANGUAGE ${LANGUAGE}
ENV LC_ALL ${LOCALES}

RUN apt-get update \
    && apt-get -y install apt-utils apache2 nano vim mysql-client \
    && a2enmod rewrite \
    && a2enmod headers \
    && apt-get update \
    && apt-get install -y software-properties-common \
    && apt-get install -y language-pack-en-base \
    && add-apt-repository ppa:ondrej/php \
    && apt-get update \
    && apt-get -y install curl wget zip unzip git php7.1 php7.1-curl php7.1-intl php7.1-gd php7.1-dom php7.1-iconv php7.1-xsl php7.1-mbstring php7.1-ctype php7.1-zip php7.1-pdo php7.1-xml php7.1-bz2 php7.1-calendar php7.1-exif php7.1-fileinfo php7.1-json php7.1-mysqli php7.1-mysql php7.1-posix php7.1-tokenizer php7.1-xmlwriter php7.1-xmlreader php7.1-phar php7.1-soap php7.1-mysql php7.1-fpm php7.1-bcmath libapache2-mod-php7.1 php-xdebug \
    && sed -i -e"s/^memory_limit\s*=\s*128M/memory_limit = 512M/" /etc/php/7.1/apache2/php.ini \
    && rm /var/www/html/* \
    && sed -i "s/None/all/g" /etc/apache2/apache2.conf \
    && sed -i "s/80/8080/g" /etc/apache2/ports.conf /etc/apache2/sites-enabled/000-default.conf \
    && apt-get install -y supervisor \
    && mkdir -p /var/log/supervisor
env APACHE_RUN_USER    www-data
env APACHE_RUN_GROUP   www-data
env APACHE_PID_FILE    /var/run/apache2.pid
env APACHE_RUN_DIR     /var/run/apache2
env APACHE_LOCK_DIR    /var/lock/apache2
env APACHE_LOG_DIR     /var/log/apache2

WORKDIR /var/www/html

# Set timezone
RUN rm /etc/localtime
RUN ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime

RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer; \
curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig; \
php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"; \
php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer; \
rm /tmp/composer-setup.php; \
chmod +x /usr/local/bin/composer; \
mkdir -p /root/.composer

# Create matching user/group
RUN groupadd --gid ${GROUP_UID} ${GROUP_NAME} \
  && useradd --uid ${USER_UID} --gid ${GROUP_NAME} --shell /bin/bash --create-home ${USER_NAME}
RUN chown -R ${USER_NAME} /var/www/html/
RUN usermod -a -G www-data ${USER_NAME}

# Deactivate Xdebug
RUN mv /etc/php/7.1/mods-available/xdebug.ini /etc/php/7.1/mods-available/xdebug.iniOLD

# Install Mhsendmail
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install golang-go \
   && mkdir /opt/go \
   && export GOPATH=/opt/go \
   && go get github.com/mailhog/mhsendmail

# Install Magerun 2
RUN wget https://files.magerun.net/n98-magerun2.phar \
	&& chmod +x ./n98-magerun2.phar \
	&& mv ./n98-magerun2.phar /usr/local/bin/

# copy Composer auth file
COPY --chown=${USER_NAME}:www-data auth.json /home/${USER_NAME}/.composer/auth.json

# copy helper scripts
COPY bin/* /usr/local/bin/
RUN chmod +x /usr/local/bin/*

CMD ["/usr/bin/supervisord"]
