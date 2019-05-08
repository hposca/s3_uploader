ROOT_DIR := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

.PHONY: all
all: build local_test

#
# Cleaning
#
.PHONY: clean
clean:
	rm -rf ${ROOT_DIR}/.stamps/

.PHONY: delete_all
delete_all:
	docker-compose down --rmi local --volumes

.PHONY: down
down:
	docker-compose down --volumes

.PHONY: bruteforce_delete
bruteforce_delete:
	docker container ls -aq | xargs docker container stop; docker container ls -aq | xargs docker rm ; docker container prune --force; docker image prune --force; docker volume prune --force

.PHONY: fresh
fresh: delete_all clean

#
# Running
#

.PHONY: upd
upd: | docker
	docker-compose up -d uploader

.PHONY: up
up: | docker
	docker-compose up uploader

.PHONY: shell
shell: | docker
	docker-compose run --service-ports --entrypoint /bin/sh uploader

.PHONY: build
build: | docker
	docker-compose build

.PHONY: force-build
force-build: | docker
	docker-compose build --no-cache

.PHONY: local_test
local_test: upd | docker
	scripts/simple_validation.sh

#
# Auxiliary targets
#
.stamps: Makefile
	@mkdir -p $@

.PHONY: docker
docker: | .stamps/docker.installed
.stamps/docker.installed: | .stamps
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "You need to install docker before running this."; \
		exit 1; \
	fi
	@if ! command -v docker-compose >/dev/null 2>&1; then \
		echo "You need to install docker-compose before running this."; \
		exit 1; \
	fi
	@touch ${ROOT_DIR}/$@
