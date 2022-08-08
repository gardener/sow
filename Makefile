# Copyright (c) 2019 SAP SE or an SAP affiliate company. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

IMAGE_REPOSITORY   := eu.gcr.io/gardener-project/sow
IMAGE_TAG          := $(shell cat VERSION)

.PHONY: build
build: docker-image

.PHONY: release
release: build docker-login docker-push

.PHONY: docker-image
docker-image:
	@docker build -t $(IMAGE_REPOSITORY):$(IMAGE_TAG) -f docker/Dockerfile --rm .

.PHONY: docker-login
docker-login:
	@gcloud auth activate-service-account --key-file .kube-secrets/gcr/gcr-readwrite.json

.PHONY: docker-push
docker-push:
	@if ! docker images $(IMAGE_REPOSITORY) | awk '{ print $$2 }' | grep -q -F $(IMAGE_TAG); then echo "$(IMAGE_REPOSITORY) version $(IMAGE_TAG) is not yet built. Please run 'make docker-image'"; false; fi
	@gcloud docker -- push $(IMAGE_REPOSITORY):$(IMAGE_TAG)

.PHONY: docker-image-ppc
docker-image-ppc:
	@docker build --build-arg ARCH=ppc64le -t $(IMAGE_REPOSITORY):$(IMAGE_TAG)-pcc -f docker/Dockerfile --rm .

.PHONY: docker-image-arm
docker-image-arm:
	@docker build --build-arg ARCH=arm64 -t $(IMAGE_REPOSITORY):$(IMAGE_TAG) -f docker/Dockerfile --rm .
