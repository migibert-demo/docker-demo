#!/bin/bash
set -m
set -e

echo "Starting Consul agent to join $CONSUL_JOIN_IP"
/bin/consul agent -config-dir=/config/consul -join=$CONSUL_JOIN_IP &
