FROM php:7.1-apache
RUN apt-get update && \
    apt-get install -y \
        zlib1g-dev
COPY src/server.crt /etc/apache2/ssl/server.crt
COPY src/server.key /etc/apache2/ssl/server.key
COPY src/dev.conf /etc/apache2/sites-enabled/dev.conf
COPY src/index.html /var/www/html/
COPY src/cloudguard.png /var/www/html/
COPY src/favicon-16x16.png /var/www/html/
COPY src/favicon-32x32.png /var/www/html/
COPY src/favicon.ico /var/www/html/
RUN docker-php-ext-install mysqli pdo pdo_mysql zip mbstring
RUN a2enmod rewrite
RUN a2enmod ssl
RUN service apache2 restart