# Hotel Management System

* [Installation](#installation)
* [Development](#installation)
  * [Useful macros commands](#useful-macro-commands)
  * [Environment variables](#environment-variables)
  * [Pulling changes](#pulling-changes)
  * [Static code analysis](#static-code-analysis)
  * [Xdebug](#xdebug)

## Installation

1. Install `Ubuntu` or other linux distribution
2. Install `docker`, `docker-compose`, `make`, `gettext`.
3. Run `make deploy` - this command is intended to be ran once on initial setup
4. Run `sudo bash -c 'echo "0.0.0.0 $(. .env && echo "$APP_HOST")" >> /etc/hosts'`
5. Run `make open-local`

## Development

### Useful macro commands

Macros are managed with `make`. See the [Makefile](./Makefile) for the full list. Feel free to extend
this list if you come by sets of commands or long commands that are frequently used.

* `make start && make stop` - Docker start / stop.
* `make composer` - Shortcut for composer commands executed inside of the api container. Ex 
  `make composer install`
* `make sf` - Shortcut to symfony console. Ex `make sf c:c` to clear cache.
* `make push-no-check` - To push without running code checks. Useful when pushing POC code or partial work.

> NOTE: Use -- to not pass options to make but rather to the underlying command. 
> Ex: `make composer require -- --dev {package}`.

Other commands are detailed in lower sections.

### Environment variables

Environment variables used by the app can be found in `.env`. Initially this file does not exist and 
has to be compiled from `.env.dist` and `.env.override`.
* `.env.dist` - here are the actual variables defined with local defaults, this file is committed
* `.env.override` - here one can define overrides or additional local variables that are personal and should
not be committed
  
To generate `.env` run:
```bash
make configure-env
```
Configures also nginx server conf. After running this command you'd need to also restart docker for these 
to take effect.

### Pulling changes

Everytime you pull several things can change: environment variables, composer dependencies, migrations.
To update all of these with one command run:
```bash
make update-app
```

The default mode is debugging. To enable profiling you need to modify `docker-compose.yaml` and set XDEBUG_MODE
to `profile`. Profiling data will be output to ./public by default.

### Migrations

Migrations can be found at [./migrations](./migrations). There are 4 types of migrations that 
can be crated for different purposes:
* `schema` - Contains only schema modifications and should be the same on any environment.
* `data` - Contains data that should be the same on any environment.
* `local data` - Contains data that should be only added for local development (and testing).
* `test data` - Contains data only added to database for tests.

To initialize the databases.
```
make initialize-db
```

To run all migrations.
```
make migrate
```

There are macro commands to generate or migrate only one of these types of migrations.
* example `make create-migration-data` to create data migrations
* generally schema migrations are autogenerated from entity definitions, and this can be done with
  `make generate-migration-diff`

### Static code analysis

The following tools are used for static code analysis:
- phpcs - `make phpcs` - linting
- phpcbf - `make phpcbf` - fix linting
- phpstan - `make phpstan` - typing


### Xdebug

Xdebug is enabled and disabled with make macros. It also works with commands and in tests. Many macros disable
xdebug before execution to not affect performance, ex `make composer`.
```bash
make enable-xdebug 
make disable-xdebug
```
