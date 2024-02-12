#!/bin/bash
#
# SPDX-FileCopyrightText: 2024 SAP SE or an SAP affiliate company and Gardener contributors
#
# SPDX-License-Identifier: Apache-2.0

set -e

DOCKER_BUILDER_NAME=${1:-"sow"}

if ! docker buildx ls | grep "$DOCKER_BUILDER_NAME" >/dev/null; then
  echo "Creating docker builder '$DOCKER_BUILDER_NAME' ..."
  docker buildx create --name "$DOCKER_BUILDER_NAME"
fi
