#!/usr/bin/env bash

awk --non-decimal-data -f <(m4 -P $(basename "$0" .sh).awk.m4) -- "$@"
