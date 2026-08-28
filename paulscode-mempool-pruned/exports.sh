#!/bin/bash

# Mempool Pruned exports.
# Static IPs for this app's three containers. The BIP-110 Mempool sits on
# .240-.242 and this takes the next block, so the two explorers can be installed
# together: they share no address, no port and no database.

export APP_MEMPOOL_PRUNED_IP="10.21.21.243"
export APP_MEMPOOL_PRUNED_PORT="8080"
export APP_MEMPOOL_PRUNED_API_IP="10.21.21.244"
export APP_MEMPOOL_PRUNED_DB_IP="10.21.21.245"
