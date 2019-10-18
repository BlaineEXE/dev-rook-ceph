TOOLS_DIR := $(PWD)/.tools
$(shell mkdir -p $(TOOLS_DIR) > /dev/null)

#
# Octopus
#

export OCTOPUS_VERSION ?= v2.0.1
export OCTOPUS_TOOL := $(TOOLS_DIR)/octopus-$(OCTOPUS_VERSION)

# Make sure octopus tool exists for use from the local dev environment
$(OCTOPUS_TOOL):
	@ echo ' === downloading Octopus version $(OCTOPUS_VERSION) === '
	@ curl --location --create-dirs --output $(OCTOPUS_TOOL) \
	  https://github.com/BlaineEXE/octopus/releases/download/$(OCTOPUS_VERSION)/octopus-static-$(OCTOPUS_VERSION)-$(GOOS)-$(GOARCH)
	@ chmod +x $(OCTOPUS_TOOL)

#
# Go(lang)
#

# some environments don't transfer GO env vars to gnumake; load & export them here
$(shell go env > /tmp/user-goenv)
$(shell env --ignore-environment - bash -c "set -a && source /tmp/user-goenv && env" > /tmp/goenv)
include /tmp/goenv
export

export GO_VERSION ?= 1.12.5
export USER_GOROOT := $(GOROOT)
# change go root to the dev env path
export GOROOT := $(TOOLS_DIR)/go-$(GO_VERSION)
export GO_TOOL := $(GOROOT)/bin/go
export PATH := $(GOROOT)/bin:$(PATH)

# Local dev go tool
# Install go from upstream since packaged go might not have the latest features, which
# sometimes can speed up build times.
GO_TARFILE=go$(GO_VERSION).linux-amd64.tar.gz
$(GO_TOOL):
	@ echo ' === downloading go version $(GO_VERSION) === '
	@ rm -rf $(GOROOT)
	@ curl --location --create-dirs https://dl.google.com/go/$(GO_TARFILE) --output $(GO_TARFILE)
	@ tar -C $(TOOLS_DIR) -xzf $(GO_TARFILE)
	@ mv $(TOOLS_DIR)/go/ $(GOROOT)
	@ rm -f go$(GO_VERSION).linux-amd64.tar.gz
