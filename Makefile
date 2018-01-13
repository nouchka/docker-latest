DOCKER_IMAGE=latest
DOCKER_NAMESPACE=nouchka
prefix = /usr/local

.DEFAULT_GOAL := build

build:
	docker build -t $(DOCKER_NAMESPACE)/$(DOCKER_IMAGE) .

run:
	docker run \
		-v '$(HOME)/workspace/docker:/root/latest/:ro' \
		-e GITHUB_TOKEN=$$GITHUB_TOKEN_READ_PUBLIC \
		$(DOCKER_NAMESPACE)/$(DOCKER_IMAGE)

check:
	docker run --rm -i hadolint/hadolint < Dockerfile

test: build run check

install:
	install bin/$(DOCKER_IMAGE) $(prefix)/bin
