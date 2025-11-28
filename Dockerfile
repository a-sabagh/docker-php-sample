FROM composer:lts AS dev_deps

WORKDIR /app

RUN --mount=type=bind,source=composer.json,target=composer.json \
    --mount=type=bind,source=composer.lock,target=composer.lock \
    --mount=type=cache,target=/tmp/cache \
    composer install --no-interaction


FROM composer:lts AS prod_deps

WORKDIR /app

RUN --mount=type=bind,source=composer.json,target=composer.json \
    --mount=type=bind,source=composer.lock,target=composer.lock \
    --mount=type=cache,target=/tmp/cache \
    composer install --no-dev --no-interaction

FROM php:8.2.12-apache AS base

RUN docker-php-ext-install pdo pdo_mysql

COPY ./src /var/www/html

FROM base AS development

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

COPY ./tests/ /var/www/html/tests

COPY phpunit.xml /var/www/html/

COPY --from=dev_deps /app/vendor/ /var/www/html/vendor

FROM base AS production

RUN cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

COPY --from=prod_deps /app/vendor/ /var/www/html/vendor

USER www-data
