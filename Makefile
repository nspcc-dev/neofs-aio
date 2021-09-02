#!/usr/bin/make -f

include .env
include help.mk

# Common variables
REPO=$(notdir $(shell pwd))
VERSION ?= "$(shell git describe --tags 2>/dev/null || git rev-parse --short HEAD | sed 's/^v//')"

# Variables for docker
HUB_IMAGE ?= "nspccdev/neofs"
AIO_IMAGE ?= "$(HUB_IMAGE)-aio"
TESTCONTAINER_IMAGE ?= "$(AIO_IMAGE)-testcontainer"

# Build aio Docker image
image-aio:
	@echo "⇒ Build aio docker image "
	@docker build \
		--rm \
		--build-arg HUB_IMAGE=$(HUB_IMAGE) \
        --build-arg HUB_TAG=$(AIO_VERSION) \
		-f Dockerfile \
		-t $(AIO_IMAGE):$(AIO_VERSION) .

# Build testcontainer Docker image
image-testcontainer: image-aio
	@echo "⇒ Build testcontainer docker image "
	@docker build \
		--rm \
		--build-arg NEOGO_HUB_TAG=$(NEOGO_VERSION) \
        --build-arg AIO_HUB_TAG=$(AIO_VERSION) \
		-f testcontainer/Dockerfile \
		-t $(TESTCONTAINER_IMAGE):$(AIO_VERSION) .


# Tick new epoch in side chain
tick.epoch:
	@./bin/tick.sh

# Update container fee per alphabet node
prepare.ir:
	@./bin/config.sh ContainerFee 0

# Show current version
version:
	@echo $(VERSION)
	@echo "neofs-node: $(AIO_VERSION)"

