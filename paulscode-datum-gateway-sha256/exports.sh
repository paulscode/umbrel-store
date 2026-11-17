#!/bin/bash

# Datum (SHA256) exports.
#
# umbreld sources this under `set -euo pipefail`, for this app and for anything
# depending on it, so nothing here may exit non-zero. There is nothing that can
# fail, and it should stay that way.

# The gateway's container. 10.21.21.67, clear of the Datum Companions (.62/.63 for
# BLAKE2b, .64/.65 for SHA256) and of the official apps.
export APP_DATUM_GATEWAY_SHA256_IP="10.21.21.67"

# Stratum, published on the host for miners on your LAN. The official Datum app
# keeps 23334, so this app can be installed beside it while miners are moved over.
# HashGG finds it on this port.
export APP_DATUM_GATEWAY_SHA256_STRATUM_PORT="23340"
