#!/bin/bash

# Mempool BIP-110 exports
# Static IP addresses for containers on Umbrel's Docker network
# Using 10.21.21.240-242 range to avoid collisions with official apps

export APP_BIP110_MEMPOOL_IP="10.21.21.240"
export APP_BIP110_MEMPOOL_PORT="8080"
export APP_BIP110_MEMPOOL_API_IP="10.21.21.241"
export APP_BIP110_MEMPOOL_DB_IP="10.21.21.242"
