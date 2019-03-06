FROM php:7.3-apache

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils \
    unzip \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libaio1 \
    libz-dev \
    libxml2-dev \
    libmemcached-dev \
    curl

# Install PHP PEAR extensions
RUN pear install channel://pear.php.net/HTTP_WebDAV_Server-1.0.0RC8 \
    && pear clear-cache \
    && pear update-channels \
    && pear upgrade

# Oracle instantclient
ADD instantclient-basiclite-linux.x64-12.2.0.1.0.zip /tmp/
ADD instantclient-sdk-linux.x64-12.2.0.1.0.zip /tmp/
ADD instantclient-sqlplus-linux.x64-12.2.0.1.0.zip /tmp/

RUN unzip /tmp/instantclient-basiclite-linux.x64-12.2.0.1.0.zip -d /usr/local/
RUN unzip /tmp/instantclient-sdk-linux.x64-12.2.0.1.0.zip -d /usr/local/
RUN unzip /tmp/instantclient-sqlplus-linux.x64-12.2.0.1.0.zip -d /usr/local/

RUN ln -s /usr/local/instantclient_12_2 /usr/local/instantclient
RUN ln -s /usr/local/instantclient/libclntsh.so.12.1 /usr/local/instantclient/libclntsh.so
RUN ln -s /usr/local/instantclient/sqlplus /usr/bin/sqlplus

RUN echo 'instantclient,/usr/local/instantclient' | pecl install oci8
RUN docker-php-ext-configure oci8 --with-oci8=instantclient,/usr/local/instantclient \
	&& docker-php-ext-install oci8

ENV LD_LIBRARY_PATH /usr/local/instantclient
ENV TNS_ADMIN       /usr/local/instantclient
ENV ORACLE_BASE     /usr/local/instantclient
ENV ORACLE_HOME     /usr/local/instantclient

# Install & enable PECL extensions
RUN pecl install memcached scrypt mcrypt \
	&& docker-php-ext-enable memcached scrypt mcrypt

# Install additional extensions
RUN docker-php-ext-install -j$(nproc) bcmath soap xml intl json mbstring

# Install nano
RUN apt-get install nano -y

COPY php.ini /usr/local/etc/php/php.ini
COPY vhost.conf /etc/apache2/sites-enabled/000-default.conf

RUN a2enmod rewrite
RUN service apache2 restart

RUN echo "<?php\n echo phpinfo();\n" > /var/www/html/phpinfo.php

EXPOSE 80