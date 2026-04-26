FROM php:8.1-apache

RUN a2enmod rewrite ssl headers

# Install mysqli
RUN docker-php-ext-install mysqli

COPY static/ /var/www/html/
COPY conf/vhost.conf /etc/apache2/sites-enabled/000-default.conf

EXPOSE 80 443
