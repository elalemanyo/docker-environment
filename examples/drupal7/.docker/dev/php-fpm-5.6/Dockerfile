FROM php:5.6-fpm

ARG INSTALL_XDEBUG=true
ENV INSTALL_XDEBUG ${INSTALL_XDEBUG}
RUN if [ ${INSTALL_XDEBUG} = true ]; then \
    pecl install xdebug && \
    docker-php-ext-enable xdebug \
;fi

RUN apt-get update && apt-get install -y libz-dev libmemcached-dev libjpeg-dev libpng-dev \
    && docker-php-ext-install -j$(nproc) pdo pdo_mysql mysqli gd \
    && docker-php-ext-enable pdo pdo_mysql mysqli gd

RUN docker-php-ext-install zip \
    && docker-php-ext-enable zip

CMD ["php-fpm"]

EXPOSE 9000
