# Copyright 2019 Copyright (c) 2019 SAP SE or an SAP affiliate company. All rights reserved. This file is licensed under the Apache Software License, v. 2 except as noted otherwise in the LICENSE file.
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

FROM alpine:3.9

RUN apk update && apk add --no-cache bash curl libc6-compat findutils apache2-utils
RUN apk add git=2.20.1-r0
RUN apk add terraform=0.11.8-r0
RUN apk add jq=1.6-r0
RUN curl -L -o /usr/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.15.5/bin/linux/amd64/kubectl
RUN curl -L -o /usr/bin/kustomize https://github.com/kubernetes-sigs/kustomize/releases/download/v3.1.0/kustomize_3.1.0_linux_amd64
RUN curl -L -o helm-archive.tar.gz https://storage.googleapis.com/kubernetes-helm/helm-v2.15.1-linux-amd64.tar.gz \
    && mkdir helm-extract \
    && tar -xzf helm-archive.tar.gz -C helm-extract \
    && cp helm-extract/linux-amd64/helm /usr/bin/helm \
    && rm -rf helm-archive.tar.gz helm-extract
RUN curl -L -o spiff-archive.zip https://github.com/mandelsoft/spiff/releases/download/v1.3.0/spiff_linux_amd64.zip \
    && mkdir spiff-extract \
    && unzip -d spiff-extract spiff-archive.zip \
    && cp "spiff-extract/spiff++" /usr/bin/spiff \
    && rm -rf spiff-archive.zip spiff-extract
COPY . /sow
RUN chmod +x /usr/bin/*
ENV PATH=$PATH:/sow/bin
ENTRYPOINT ["sow"]
