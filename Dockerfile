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

# Install additional extensions
RUN docker-php-ext-install -j$(nproc) bcmath soap xml intl json mbstring

# Install PHP PEAR extensions
RUN pear install channel://pear.php.net/HTTP_WebDAV_Server-1.0.0RC8 \
    && pear clear-cache \
    && pear update-channels \
    && pear upgrade

# Install PECL extensions
RUN pecl install mcrypt scrypt memcached


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

RUN echo 'export LD_LIBRARY_PATH="/usr/local/instantclient"' >> /root/.bashrc
RUN echo 'umask 002' >> /root/.bashrc

RUN echo 'instantclient,/usr/local/instantclient' | pecl install oci8
RUN echo "extension=oci8.so" > /usr/local/etc/php/conf.d/php-oci8.ini

RUN apt-get install nano -y

COPY docker-php.conf /etc/apache2/conf-enabled/docker-php.conf
COPY vhost.conf /etc/apache2/sites-enabled/000-default.conf

RUN a2enmod rewrite
RUN service apache2 restart

RUN echo "<?php echo phpinfo(); ?>" > /var/www/html/phpinfo.php

EXPOSE 80