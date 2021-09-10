TOOLS_DIR := $(PWD)/.tools
$(shell mkdir -p $(TOOLS_DIR) > /dev/null)

#
# Required executables
#
EXECUTABLES = ansible bash curl docker jq kubectl vagrant
_ := $(foreach exec,$(EXECUTABLES),\
  $(if $(shell command -v $(exec)),some string,$(error "No $(exec) in PATH")))


#
# Go(lang)
#

# some environments don't transfer GO env vars to gnumake; load & export them here
$(shell go env > /tmp/user-goenv)
$(shell env -i - bash -c "set -a && source /tmp/user-goenv && env" > /tmp/goenv)
include /tmp/goenv
export

export GO_VERSION ?= 1.16.7
export USER_GOROOT := $(GOROOT)
# change go root to the dev env path
export GOROOT := $(TOOLS_DIR)/go-$(GO_VERSION)
export GO_TOOL := $(GOROOT)/bin/go
export PATH := $(GOROOT)/bin:$(PATH)

# Local dev go tool
# Install go from upstream since packaged go might not have the latest features, which
# sometimes can speed up build times.
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
GO_TARFILE=go$(GO_VERSION).$(OS)-amd64.tar.gz
$(GO_TOOL):
	@ echo ' === downloading go version $(GO_VERSION). === '
	@ rm -rf $(GOROOT)
	@ curl --location --create-dirs https://dl.google.com/go/$(GO_TARFILE) --output $(GO_TARFILE)
	@ tar -C $(TOOLS_DIR) -xzf $(GO_TARFILE)
	@ mv $(TOOLS_DIR)/go/ $(GOROOT)
	@ rm -f $(GO_TARFILE)
