SHELL := /bin/bash

grn=$'\e[1;32m
yel=$'\e[1;33m
end=$'\e[0m

-include .env

configure-env:
	@printf "$(grn)\nConfiguring environment variables..$(end)\n"
	./bin/configure_env.sh

# Docker operations.
start:
	docker-compose up -d ;\

stop:
	docker-compose down ;\

restart:
	docker-compose down ;\
	make start

list:
	docker-compose ps

docker-update: stop
	docker-compose pull ;\
	docker volume prune -f || true ;\
	docker-compose up -d --build ;\

docker-clean:
	docker ps -qa --no-trunc --filter "status=exited" | xargs docker rm || true ;\
	docker images -f "dangling=true" -q | xargs docker rmi || true ;\
	docker volume prune -f || true ;\

ssh:
	docker-compose exec php bash

# Xdebug causes performance issues, disable it for commands,migrations etc.
disable-xdebug:
	if [ "$(CI)" == "true" ]; then \
  		dxd || true ;\
	else \
		docker-compose exec -T php dxd || true ;\
	fi

enable-xdebug:
	if [ "$(CI)" == "true" ]; then \
		mv /usr/local/etc/php/conf.d/disabled/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini ;\
	else \
		docker-compose exec -T php exd || true ;\
	fi
# End of - Docker operations.

# Database operations.
migrate: disable-xdebug
	@printf "$(grn)\nMigrating schema..$(end)\n"
	@make migrate-schema
	@printf "$(grn)\nMigrating data..$(end)\n"
	@make migrate-data
	@if [ "$(ENV)" == "local" ]; then \
		printf "$(grn)\nMigrating local only data..$(end)\n" ;\
  		make migrate-data-local ;\
	fi

migrate-schema:
	docker-compose exec php bin/console d:m:m --configuration=config/migrations/schema.yaml -n ;\

migrate-data:
	docker-compose exec php bin/console d:m:m --configuration=config/migrations/data.yaml -n ;\

migrate-data-local:
	docker-compose exec php bin/console d:m:m --configuration=config/migrations/data_local.yaml -n ;\

create-migration-schema:
	docker-compose exec php bin/console d:m:g --configuration=config/migrations/schema.yaml -n ;\

generate-migration-diff:
	docker-compose exec php bin/console d:m:diff --configuration=config/migrations/schema.yaml -n ;\

create-migration-data:
	docker-compose exec php bin/console d:m:g --configuration=config/migrations/data.yaml -n ;\

create-migration-data-local:
	docker-compose exec php bin/console d:m:g --configuration=config/migrations/data_local.yaml -n ;\

create-migration-data-test:
	docker-compose exec php bin/console d:m:g --configuration=config/migrations/data_test.yaml -n ;\

initialize-db: disable-xdebug
	docker-compose exec php bin/console d:d:c --if-not-exists
	make migrate

reset-db: disable-xdebug
	docker-compose exec php bin/console d:d:d --force
	make initialize-db

# End of - Database operations.

# Application operations.
sf:
	docker-compose exec php bin/console $(filter-out $@,$(MAKECMDGOALS))

composer: disable-xdebug
	docker-compose exec php composer $(filter-out $@,$(MAKECMDGOALS))

clear-cache: disable-xdebug
	docker-compose exec php bin/console c:c ;\
	docker-compose exec php bin/console cache:pool:clear cache.app ;\

clear-cache-test: disable-xdebug
	docker-compose exec php bin/console c:c --env test;\

reset-cache-for-test:
	make clear-cache && make clear-cache-test && make enable-xdebug

deploy:
	make configure-env
	make start
	make composer install
	make initialize-db

update-app: disable-xdebug
	make configure-env
	make start
	make composer install
	make migrate

open-local:
	@printf "$(grn)\nOpening local website..$(end)\n"
	which xdg-open || exit 1
	xdg-open ${APP_URL}

phpcs:
	docker-compose exec php vendor/bin/phpcs -s
phpcbf: disable-xdebug
	docker-compose exec -u $$UID php vendor/bin/phpcbf
phpstan:
	docker-compose exec php vendor/bin/phpstan --memory-limit=-1

pre-push: disable-xdebug
	if [ "$$NO_PHPQA" != "true" ]; then \
		docker-compose exec -T php ./bin/quality.sh ;\
	fi

pre-commit: disable-xdebug
	docker-compose exec -T -u $$UID php ./bin/pre_commit.sh

# Required to allow make command parameters.
%:
	@:
