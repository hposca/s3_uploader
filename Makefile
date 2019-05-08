ROOT_DIR := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
AWS_REGION := us-west-2
ECR_PATH := ${AWS_ACCOUNT}.dkr.ecr.us-west-2.amazonaws.com

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
# CI/CD
#

# Humans should not be able to publish the image, only automated processes.
# Also, the tagging mechanism needs to be improved for real-world usage and the way we are updating the service (forcing it) is not ideal.
.PHONY: publish
publish: | .stamps/docker.login
	docker build -t ${ECR_PATH}/s3_uploader:master-latest . && \
	docker push ${ECR_PATH}/s3_uploader:master-latest && \
	aws ecs update-service --cluster arn:aws:ecs:${AWS_REGION}:${AWS_ACCOUNT}:cluster/s3_uploader --service arn:aws:ecs:${AWS_REGION}:${AWS_ACCOUNT}:service/s3uploader-service1 --force-new-deployment

#
# Infrastructure
#
.stamps/infrastructure.initialized: | .stamps/terraform.installed
	@cd infrastructure/ && \
	terraform init && \
	terraform workspace new testing ; \
	touch ${ROOT_DIR}/$@

infra-create: | .stamps/infrastructure.created
.stamps/infrastructure.created: .stamps/infrastructure.initialized
	@cd infrastructure/ && \
	terraform workspace select testing && \
	terraform apply --var-file=testing.tfvars && \
	touch ${ROOT_DIR}/$@

.PHONY: infra-plan infra
infra-plan: infra
infra: | .stamps/infrastructure.initialized
	@cd infrastructure/ && \
	terraform workspace select testing && \
	terraform plan --var-file=testing.tfvars

.PHONY: infra-update
infra-update: | .stamps/infrastructure.created
	@cd infrastructure/ && \
	terraform workspace select testing && \
	terraform apply --var-file=testing.tfvars

.PHONY: infra-destroy
infra-destroy: | .stamps/terraform.installed
	@cd infrastructure/ && \
	terraform workspace select testing && \
	terraform destroy --var-file=testing.tfvars && \
	rm -f ${ROOT_DIR}/.stamps/infrastructure.created

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

.stamps/aws.installed: | .stamps
	@if ! command -v aws >/dev/null 2>&1; then \
		echo "You need to install the AWS CLI before running this."; \
		exit 1; \
	fi
	@touch ${ROOT_DIR}/$@

.stamps/terraform.installed: | .stamps .stamps/aws.installed
	@if ! command -v terraform >/dev/null 2>&1; then \
		echo "You need to install the Terraform before running this."; \
		exit 1; \
	fi
	@touch ${ROOT_DIR}/$@

.stamps/docker.login: | .stamps .stamps/aws.installed
	eval $$(aws ecr get-login --no-include-email --region ${AWS_REGION})
	@touch ${ROOT_DIR}/$@
