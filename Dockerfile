FROM php:7.4-apache

# Install required extensions
RUN docker-php-ext-install pdo_mysql mysqli

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Copy application code
COPY . /var/www/html/

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Configure Apache to allow .htaccess
RUN sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# Set ServerName to suppress Apache warning
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

EXPOSE 80
CMD ["apache2-foreground"]
