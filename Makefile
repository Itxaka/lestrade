GIT_COMMIT ?= $(shell git rev-parse HEAD)
GIT_COMMIT_SHORT ?= $(shell git rev-parse --short HEAD)
GIT_TAG ?= $(shell git describe --abbrev=0 --tags 2>/dev/null || echo "v0.0.0" )
REPO?=ttl.sh/lestrade-ci
ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
# This are the default images already in the dockerfile but we want to be able to override them
OPERATOR_IMAGE?=quay.io/costoolkit/elemental-operator-ci:latest
REGISTER_IMAGE?=quay.io/costoolkit/elemental-register-ci:latest
SYSTEM_AGENT_IMAGE?=rancher/system-agent:v0.2.9
TOOL_IMAGE?=quay.io/costoolkit/elemental-cli-ci:latest
LUET_VERSION?="0.32.5"
CI?=""

.PHONY: build
build:
ifeq ($(CI), "")
	@echo "Not running on ci, appending ${GIT_COMMIT_SHORT} to version"
	$(eval GIT_TAG=${GIT_TAG}-${GIT_COMMIT_SHORT})
endif
	@mkdir -p build
	@DOCKER_BUILDKIT=1 docker build -f Dockerfile \
		--target default \
		--build-arg IMAGE_TAG=${GIT_TAG} \
		--build-arg IMAGE_COMMIT=${GIT_COMMIT} \
		--build-arg IMAGE_REPO=${REPO} \
		--build-arg OPERATOR_IMAGE=${OPERATOR_IMAGE} \
		--build-arg REGISTER_IMAGE=${REGISTER_IMAGE} \
		--build-arg SYSTEM_AGENT_IMAGE=${SYSTEM_AGENT_IMAGE} \
		--build-arg TOOL_IMAGE=${TOOL_IMAGE} \
		--build-arg ELEMENTAL_VERSION=${FINAL_TAG} \
		--build-arg LUET_VERSION=${LUET_VERSION} \
		-t iso:${GIT_TAG} .
	@DOCKER_BUILDKIT=1 docker run --rm -v $(PWD)/build:/mnt \
		iso:${GIT_TAG} \
		--config-dir . \
		--debug build-iso \
		-o /mnt \
		-n lestrade-${GIT_TAG} \
		dir:rootfs
	@echo "INFO: ISO available at build/lestrade-${GIT_TAG}.iso"


.PHONY: image
image:
ifeq ($(CI), "")
	@echo "Not running on ci, appending ${GIT_COMMIT_SHORT} to version"
	$(eval GIT_TAG=${GIT_TAG}-${GIT_COMMIT_SHORT})
endif
	@mkdir -p build
	@DOCKER_BUILDKIT=1 docker build -f Dockerfile \
		--target baseos \
		--build-arg IMAGE_TAG=${GIT_TAG} \
		--build-arg IMAGE_COMMIT=${GIT_COMMIT} \
		--build-arg IMAGE_REPO=${REPO} \
		--build-arg OPERATOR_IMAGE=${OPERATOR_IMAGE} \
		--build-arg REGISTER_IMAGE=${REGISTER_IMAGE} \
		--build-arg SYSTEM_AGENT_IMAGE=${SYSTEM_AGENT_IMAGE} \
		--build-arg TOOL_IMAGE=${TOOL_IMAGE} \
		--build-arg ELEMENTAL_VERSION=${FINAL_TAG} \
		-t ${REPO}:${GIT_TAG} .