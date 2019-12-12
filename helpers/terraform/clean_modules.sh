#!/usr/bin/env bash

set -e

find . -name ".terraform" -type d -exec rm -rf {} \;
