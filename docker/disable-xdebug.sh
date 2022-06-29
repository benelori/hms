#!/usr/bin/env bash

mkdir -p /usr/local/etc/php/conf.d/disabled
mv /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/disabled
# restart fpm process
/command/s6-svc -r /var/run/service/php-fpm
