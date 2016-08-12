PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
TARGET_DIR=$(PROJECT_DIR)target

CI_BUILD_NUMBER ?= $(USER)-snapshot
CI_IVY_CACHE ?= $(HOME)/.ivy2
CI_SBT_CACHE ?= $(HOME)/.sbt
CI_WORKDIR ?= $(shell pwd)

VERSION ?= 0.1.$(CI_BUILD_NUMBER)

BUILDER_TAG = "meetup/sbt-builder:0.1.3"

PUBLISH_TAG ?= "meetup/cluster-dns:$(VERSION)"

# lists all available targets
list:
	@sh -c "$(MAKE) -p no_op__ | \
		awk -F':' '/^[a-zA-Z0-9][^\$$#\/\\t=]*:([^=]|$$)/ {split(\$$1,A,/ /);\
		for(i in A)print A[i]}' | \
		grep -v '__\$$' | \
		grep -v 'make\[1\]' | \
		grep -v 'Makefile' | \
		sort"

# required for list
no_op__:

__package-sbt:
	sbt clean \
		"set coverageEnabled := true" \
		"set coverageOutputHTML := false" \
		test \
		coverageReport \
		coverallsMaybe \
		coverageOff \
		component:test \
		'docker:publishLocal'

package:
	docker pull $(BUILDER_TAG)
	docker run \
		--rm \
		-v $(CI_WORKDIR):/data \
		-v $(CI_IVY_CACHE):/root/.ivy2 \
		-v $(CI_SBT_CACHE):/root/.sbt \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-e VERSION=$(VERSION) \
		-e COVERALLS_REPO_TOKEN=$(COVERALLS_REPO_TOKEN) \
		$(BUILDER_TAG) \
		make __package-sbt

publish: package
	docker push $(PUBLISH_TAG)

run-local:
	-docker stop cluster-dns
	-docker rm cluster-dns
	docker run \
	    --name cluster-dns \
		-e TRANS_DOMAIN="mup.zone" \
		-p 32053/udp \
		$(PUBLISH_TAG)


# Required for SBT.
version:
	@echo $(VERSION)

# Required for Docker settings.
publish-tag:
	@echo $(PUBLISH_TAG)
