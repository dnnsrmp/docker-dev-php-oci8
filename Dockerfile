FROM composer:latest AS composer
FROM php:7.3-apache AS php

ENV LD_LIBRARY_PATH /usr/local/instantclient_12_2
ENV TNS_ADMIN       /usr/local/instantclient_12_2
ENV ORACLE_BASE     /usr/local/instantclient_12_2
ENV ORACLE_HOME     /usr/local/instantclient_12_2
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends --autoremove apt-utils \
    unzip \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libaio1 \
    libz-dev \
    libxml2-dev \
    libmemcached-dev \
    curl \
    wget \
    gnupg2 \
    git \
    bzip2

# Install PHP PEAR extensions
RUN pear install channel://pear.php.net/HTTP_WebDAV_Server-1.0.0RC8 \
    && pear clear-cache \
    && pear update-channels \
    && pear upgrade

# Oracle instantclient
ADD instantclient-basiclite-linux.x64-12.2.0.1.0.zip /tmp/
ADD instantclient-sdk-linux.x64-12.2.0.1.0.zip /tmp/
ADD instantclient-sqlplus-linux.x64-12.2.0.1.0.zip /tmp/

RUN unzip /tmp/instantclient-basiclite-linux.x64-12.2.0.1.0.zip -d /usr/local/ \
	&& unzip /tmp/instantclient-sdk-linux.x64-12.2.0.1.0.zip -d /usr/local/ \
	&& unzip /tmp/instantclient-sqlplus-linux.x64-12.2.0.1.0.zip -d /usr/local/ \
	&& ln -s /usr/local/instantclient_12_2/libclntsh.so.12.1 /usr/local/instantclient_12_2/libclntsh.so

RUN docker-php-ext-configure oci8 --with-oci8=instantclient,/usr/local/instantclient_12_2 \
	&& docker-php-ext-install oci8

# Install & enable PECL extensions
RUN pecl install memcached scrypt \
	&& docker-php-ext-enable memcached scrypt

# Install additional extensions
RUN docker-php-ext-install -j$(nproc) bcmath soap intl \
	&& docker-php-source delete

# Install nano
RUN apt-get install nano -y \
    && apt-get clean

# Composer
COPY --from=composer /usr/bin/composer /usr/bin/composer
