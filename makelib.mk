include tools.mk
export

# Entering/Leaving directory messages are annoying and not very useful
MAKEFLAGS += --no-print-directory

# This roundabout way of importing variables from 'developer-settings' works around the issue that
# gnumake will read in quotes from variables if `developer-settings` is included directly.
# e.g., var="val" will be read is as ["val"] instead of just [val]
$(shell env --ignore-environment - bash -c "source developer-settings && env" > /tmp/mkenv)
include /tmp/mkenv
export


export SUDO ?= sudo --preserve-env
export BASH ?= bash
export PYTHON ?= python3
export GO ?= $(GO_TOOL)
export OCTOPUS ?= $(OCTOPUS_TOOL)


ifdef DEBUG
export BASH += -x
export OCTOPUS += -v
endif
