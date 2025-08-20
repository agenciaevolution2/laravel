# syntax=docker/dockerfile:1
# --- BASE PHP (build e runtime em um container) ---
FROM php:8.3-cli-alpine

# libs e extensões necessárias ao Laravel
RUN apk add --no-cache bash git unzip libzip-dev oniguruma-dev icu-dev \
    libpng-dev libjpeg-turbo-dev freetype-dev \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath intl zip gd opcache \
 && pecl install redis && docker-php-ext-enable redis

# composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app
COPY . /app

# instalar deps do composer (sem dev, otimizado)
RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader \
 || true

# permissões e link de storage (não falha se .env ainda não existe)
RUN mkdir -p storage bootstrap/cache \
 && chmod -R 775 storage bootstrap/cache \
 && php -r "file_exists('public/storage') || @symlink('../storage/app/public','public/storage');" || true

# porta padrão do container (EasyPanel usa reverse proxy)
ENV PORT=8080
EXPOSE 8080

# inicia app (config:cache usa envs em tempo de execução)
CMD ["sh","-lc","php artisan config:cache || true; php -S 0.0.0.0:$PORT -t public"]
