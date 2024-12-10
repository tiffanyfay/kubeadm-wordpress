#!/bin/bash

set -eu

SSH_KEY_ID=$(doctl compute ssh-key list --no-header | grep 'dropletssh' | awk '{print $1}')

# TODO: make it so it gets the VPC ID from the API instead of being hardcoded

curl -X POST -H 'Content-Type: application/json' \
    -H "Authorization: Bearer ${DO_TOKEN}" \
    -d '{"names":["ubuntu-cp",
        "ubuntu-wn"],
        "size":"s-2vcpu-2gb-amd",
        "region":"sfo3",
        "image":"ubuntu-24-10-x64",
        "vpc_uuid":"923890d9-80c3-4177-9fcb-6859df206e1d",
        "ssh_keys":["'"${SSH_KEY_ID}"'"]}' \
    "https://api.digitalocean.com/v2/droplets"