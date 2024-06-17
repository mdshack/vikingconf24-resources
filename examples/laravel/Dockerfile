FROM dunglas/frankenphp:1.2-php8.2

RUN install-php-extensions \
	pdo_mysql \
    redis

COPY . /app

CMD ["frankenphp", "run", "/app/Caddyfile"]