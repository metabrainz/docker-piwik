#!/bin/sh

mkdir -p /run/php
exec /usr/sbin/php-fpm7.0 -c /etc/php/7.0/fpm --nodaemonize
