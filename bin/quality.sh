#!/bin/bash

set -e

vendor/bin/phpcs -s
vendor/bin/phpstan --memory-limit=-1
