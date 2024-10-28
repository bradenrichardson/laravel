FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libicu-dev \
    zip \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip \
    intl \
    opcache

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy composer.json first
COPY composer.json ./

# Copy composer.lock if it exists (but won't fail if it doesn't)
COPY composer.lock* ./

# Install composer dependencies
RUN composer install --no-scripts --no-autoloader --no-dev

# Copy application files
COPY . .

# Generate optimized autoload files
RUN composer dump-autoload --optimize

# Set permissions
RUN chown -R www-data:www-data /var/www \
    && chmod -R 755 /var/www/storage /var/www/bootstrap/cache

# Configure PHP-FPM to listen on port 8000
RUN echo "\
[www]\n\
listen = 8000\n\
user = www-data\n\
group = www-data\n\
pm = dynamic\n\
pm.max_children = 10\n\
pm.start_servers = 2\n\
pm.min_spare_servers = 1\n\
pm.max_spare_servers = 3\n\
clear_env = no\n\
catch_workers_output = yes\n\
decorate_workers_output = no\n\
pm.status_path = /status\n\
ping.path = /ping\n\
" > /usr/local/etc/php-fpm.d/zz-docker.conf

# Expose port 8000
EXPOSE 8000

# Start PHP-FPM
CMD ["php-fpm"]