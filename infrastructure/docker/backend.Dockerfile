FROM php:8.3-cli-alpine

RUN apk add --no-cache postgresql-dev libzip-dev icu-dev \
    && docker-php-ext-install pdo_pgsql pcntl intl zip

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY . .
RUN composer install --no-interaction --prefer-dist || true

EXPOSE 8000
CMD ["sh", "-c", "php artisan migrate --force && php artisan serve --host=0.0.0.0 --port=8000"]
