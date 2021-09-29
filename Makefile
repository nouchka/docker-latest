DOCKER_IMAGE=latest

include Makefile.docker

PACKAGE_VERSION=0.1

include Makefile.package

.PHONY: check-version
check-version:
	docker run --rm --entrypoint md5sum $(DOCKER_NAMESPACE)/$(DOCKER_IMAGE):$(VERSION) /latest
