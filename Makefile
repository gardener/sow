# SPDX-FileCopyrightText: 2024 SAP SE or an SAP affiliate company and Gardener contributors
#
# SPDX-License-Identifier: Apache-2.0

REPO_ROOT           := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
VERSION             := $(shell cat $(REPO_ROOT)/VERSION)
EFFECTIVE_VERSION   := $(VERSION)-$(shell git rev-parse HEAD)
IMAGE_REPOSITORY    := eu.gcr.io/gardener-project/sow
DOCKER_BUILDER_NAME := "sow"

.PHONY: build
build: docker-image

.PHONY: release
release: build docker-login docker-push

.PHONY: docker-image
docker-image: docker-image-amd

.PHONY: docker-login
docker-login:
	@gcloud auth activate-service-account --key-file .kube-secrets/gcr/gcr-readwrite.json

.PHONY: docker-push
docker-push:
	@if ! docker images ${IMAGE_REPOSITORY} | awk '{ print $$2 }' | grep -q -F ${EFFECTIVE_VERSION}; then echo "${IMAGE_REPOSITORY} version ${EFFECTIVE_VERSION} is not yet built. Please run 'make docker-image'"; false; fi
	@gcloud docker -- push ${IMAGE_REPOSITORY}:${EFFECTIVE_VERSION}

.PHONY: docker-image-amd
docker-image-amd:
	@$(REPO_ROOT)/.ci/prepare-docker-builder.sh
	@echo "Building docker images for version $(EFFECTIVE_VERSION)"
	@docker buildx build --builder $(DOCKER_BUILDER_NAME) --load --build-arg EFFECTIVE_VERSION=$(EFFECTIVE_VERSION) --platform linux/amd64 -t ${IMAGE_REPOSITORY}:${EFFECTIVE_VERSION} -f docker/Dockerfile .

.PHONY: docker-image-arm
docker-image-arm:
	@$(REPO_ROOT)/.ci/prepare-docker-builder.sh
	@echo "Building docker images for version $(EFFECTIVE_VERSION)"
	@docker buildx build --builder $(DOCKER_BUILDER_NAME) --load --build-arg EFFECTIVE_VERSION=$(EFFECTIVE_VERSION) --platform linux/arm64 -t ${IMAGE_REPOSITORY}:${EFFECTIVE_VERSION}-arm -f docker/Dockerfile .

.PHONY: docker-image-ppc
docker-image-ppc:
	@$(REPO_ROOT)/.ci/prepare-docker-builder.sh
	@echo "Building docker images for version $(EFFECTIVE_VERSION)"
	@docker buildx build --builder $(DOCKER_BUILDER_NAME) --load --build-arg EFFECTIVE_VERSION=$(EFFECTIVE_VERSION) --platform linux/ppc64le -t ${IMAGE_REPOSITORY}:${EFFECTIVE_VERSION}-ppc -f docker/Dockerfile .
