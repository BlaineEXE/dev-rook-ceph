#!/usr/bin/env bash

test -s /root/.alias && source /root/.alias

test -s /root/.kube/kubectl-completion.sh && source /root/.kube/kubectl-completion.sh

test -s /root/.octopus/octopus-completion.sh && source /root/.octopus/octopus-completion.sh
