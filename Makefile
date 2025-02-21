ifdef TARGET
TARGETDEFINED="true"
else
TARGETDEFINED="false"
endif

dev:
	$(eval export env_stub=dev)
	@true

test:
	$(eval export env_stub=test)
	@true

integration:
	$(eval export env_stub=integration)
	@true

live:
	$(eval export env_stub=live)
	@true

target:
ifeq ($(TARGETDEFINED), "true")
	$(eval export env_stub=${TARGET})
	@true
else
	$(info Must set TARGET)
	@false
endif

init:
	$(eval export ECR_REPO_URL=754256621582.dkr.ecr.eu-west-2.amazonaws.com/formbuilder/fb-user-filestore-api)

# install aws cli w/o sudo
install_build_dependencies: init
	docker --version
	pip install --user awscli
	$(eval export PATH=${PATH}:${HOME}/.local/bin/)


build_image: install_build_dependencies
	docker build --build-arg BUNDLE_FLAGS="--without test development" -t ${ECR_REPO_URL}:latest-${env_stub} -t ${ECR_REPO_URL}:${CIRCLE_SHA1} -f ./Dockerfile .

login: init
	@eval $(shell aws ecr get-login --no-include-email --region eu-west-2)

push: login
	docker push ${ECR_REPO_URL}:latest-${env_stub}
	docker push ${ECR_REPO_URL}:${CIRCLE_SHA1} #multiple tags in ECR can only be done by pushing twice

build_and_push: build_image push

.PHONY := init push build_image login build
DOCKER_COMPOSE = docker-compose -f docker-compose.yml

stop:
	$(DOCKER_COMPOSE) down -v

build: stop
	$(DOCKER_COMPOSE) build --build-arg BUNDLE_FLAGS=''

serve: stop build
	$(DOCKER_COMPOSE) up

spec: build
	$(DOCKER_COMPOSE) run --rm app bundle exec rspec --require spec_helper
