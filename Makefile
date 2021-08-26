#!/usr/bin/make -f

include .env
include help.mk

# Common variables
REPO=$(notdir $(shell pwd))
VERSION ?= "$(shell git describe --tags 2>/dev/null || git rev-parse --short HEAD | sed 's/^v//')"

# Variables for docker
HUB_IMAGE ?= "nspccdev/$(REPO)-testcontainer"
HUB_TAG ?= "$(shell echo ${VERSION} | sed 's/^v//')"

# Build testcontainer Docker image
image-testcontainer:
	@echo "⇒ Build testcontainer docker image "
	@docker build \
		--rm \
		--build-arg NEOGO_HUB_TAG=$(NEOGO_VERSION) \
        --build-arg AIO_HUB_TAG=$(AIO_VERSION) \
		-f testcontainer/Dockerfile \
		-t $(HUB_IMAGE):$(HUB_TAG) .

# Push Docker image to the hub
image-push:
	@echo "⇒ Publish image"
	@docker push $(HUB_IMAGE):$(HUB_TAG)

# Show current version
version:
	@echo $(VERSION)

