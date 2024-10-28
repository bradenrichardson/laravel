FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
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
    zip

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy application files
COPY . .

# Create .env file from .env.example if .env doesn't exist
RUN if [ ! -f ".env" ]; then cp .env.example .env; fi

# Install dependencies
RUN composer install --no-interaction --optimize-autoloader --no-dev

# Generate application key if not set
RUN php artisan key:generate --force

# Set permissions
RUN chown -R www-data:www-data /var/www \
    && chmod -R 755 /var/www/storage /var/www/bootstrap/cache

# Enable PHP error logging
RUN echo "\
error_reporting = E_ALL\n\
display_errors = On\n\
log_errors = On\n\
error_log = /dev/stderr\n\
" > /usr/local/etc/php/conf.d/error-logging.ini

# Configure PHP-FPM
RUN echo "\
[global]\n\
daemonize = no\n\
\n\
[www]\n\
listen = 9000\n\
user = www-data\n\
group = www-data\n\
pm = dynamic\n\
pm.max_children = 5\n\
pm.start_servers = 2\n\
pm.min_spare_servers = 1\n\
pm.max_spare_servers = 3\n\
catch_workers_output = yes\n\
decorate_workers_output = no\n\
" > /usr/local/etc/php-fpm.d/zz-docker.conf

# Add nginx
RUN apt-get update && apt-get install -y nginx

# Configure nginx with error logging and custom routing for /health endpoint
RUN echo "\
server {\n\
    listen 8000;\n\
    index index.php index.html;\n\
    error_log  /dev/stderr;\n\
    access_log /dev/stdout;\n\
    root /var/www/public;\n\
\n\
    # Special handling for /health endpoint - faster processing\n\
    location /health {\n\
        try_files /index.php =404;\n\
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;\n\
        fastcgi_pass 127.0.0.1:9000;\n\
        fastcgi_index index.php;\n\
        include fastcgi_params;\n\
        fastcgi_param SCRIPT_FILENAME \$document_root/index.php;\n\
        fastcgi_param PATH_INFO /health;\n\
    }\n\
\n\
    location / {\n\
        try_files \$uri \$uri/ /index.php?\$query_string;\n\
    }\n\
\n\
    location ~ \.php\$ {\n\
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;\n\
        fastcgi_pass 127.0.0.1:9000;\n\
        fastcgi_index index.php;\n\
        include fastcgi_params;\n\
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;\n\
        fastcgi_param PATH_INFO \$fastcgi_path_info;\n\
    }\n\
}\n\
" > /etc/nginx/sites-available/default

# Create start script with error checking
RUN echo '#!/bin/bash\n\
set -e\n\
echo "Starting PHP-FPM..."\n\
php-fpm -D\n\
echo "Starting Nginx..."\n\
nginx -g "daemon off;"\n\
' > /start.sh && chmod +x /start.sh

EXPOSE 8000

CMD ["/start.sh"]