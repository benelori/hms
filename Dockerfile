FROM php:8.1-fpm as base
ARG S6_OVERLAY_VERSION=3.1.0.1
ARG S6_OVERLAY_ARCH=x86_64
# See S6 README
ENV S6_KEEP_ENV=1

# Install S6 Overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz

# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER=1

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
      libxslt-dev \
      libzip-dev \
      libpq-dev \
      unzip \
      nginx \
      xz-utils \
      git \
      netcat \
    && docker-php-ext-install \
      xsl \
      zip \
      pdo \
      pdo_pgsql \
      opcache \
      pcntl \
      intl \
    && rm -rf /var/lib/apt/lists/*

# Install Nginx S6 Overlay Service
COPY docker/nginx/run /etc/s6-overlay/s6-rc.d/nginx/run
COPY docker/nginx/type /etc/s6-overlay/s6-rc.d/nginx/type
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/nginx
# Install PHP FPM S6 Overlay Service
COPY docker/php-fpm/run /etc/s6-overlay/s6-rc.d/php-fpm/run
COPY docker/php-fpm/type /etc/s6-overlay/s6-rc.d/php-fpm/type
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/php-fpm
# Nginx config file and disable access logging
COPY docker/nginx/site-default.conf /etc/nginx/sites-enabled/default
COPY docker/nginx/logging.conf /etc/nginx/conf.d/logging.conf

WORKDIR /tmp

FROM base as production

WORKDIR /var/www/

# Add prod stuff

# For local development purposes
FROM production as development

RUN pecl install  \
      xdebug \
    && docker-php-ext-enable \
      xdebug

COPY docker/disable-xdebug.sh /bin/dxd
COPY docker/enable-xdebug.sh /bin/exd

ENTRYPOINT ["/init"]
