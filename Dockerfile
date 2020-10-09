FROM php:7.1-apache
RUN apt-get update && \
    apt-get install -y \
        zlib1g-dev
COPY src/index.html /var/www/html/
COPY src/cloudguard.png /var/www/html/
COPY src/favicon-16x16.png /var/www/html/
COPY src/favicon-32x32.png /var/www/html/
COPY src/favicon.ico /var/www/html/
RUN service apache2 restart