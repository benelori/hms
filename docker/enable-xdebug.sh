#!/usr/bin/env bash

mv /usr/local/etc/php/conf.d/disabled/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/
# restart fpm process
/command/s6-svc -r /var/run/service/php-fpm
