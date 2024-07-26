FROM php:8-fpm-buster

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    cron \
    procps \
    grep \
    curl \
    libmemcached-dev \
    libz-dev \
    libpq-dev \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    libssl-dev \
    libmcrypt-dev \
    wget \
    nginx \
    libnginx-mod-http-headers-more-filter \
    git \
    libzip-dev \
    supervisor \
  && rm -rf /var/lib/apt/lists/*
# RUN docker-php-ext-install pdo_pgsql pdo_mysql bcmath opcache zip gd
RUN pecl install redis \
    && pecl install xdebug \
    && pecl install mongodb \
    && docker-php-ext-enable redis xdebug mongodb

RUN docker-php-ext-install mysqli && docker-php-ext-enable mysqli
RUN docker-php-ext-install pdo pdo_pgsql pdo_mysql bcmath opcache zip exif  \
    && docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
    && docker-php-ext-install gd

## Composer Install
RUN EXPECTED_COMPOSER_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig) && \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php -r "if (hash_file('SHA384', 'composer-setup.php') === '${EXPECTED_COMPOSER_SIGNATURE}') { echo 'Composer.phar Installer verified';  } else { echo 'Composer.phar Installer corrupt'; unlink('composer-setup.php');  } echo PHP_EOL;" && \
    php composer-setup.php --install-dir=/usr/bin --filename=composer && \
    php -r "unlink('composer-setup.php');"

RUN rm -rf /var/www/html
RUN mkdir -p /var/www/html

RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

# clear default nginx config
RUN rm -rf /etc/nginx/sites-enabled/*

COPY supervisor.conf /etc/supervisor/supervisord.conf
COPY site.conf /etc/nginx/conf.d/site.conf
COPY uploads.ini /usr/local/etc/php/conf.d/uploads.ini
CMD ["supervisord"]
