#!/bin/bash

# Datum (BLAKE2b) exports.
#
# umbreld sources this under `set -euo pipefail`, for this app and for anything
# depending on it, so nothing here may exit non-zero.

# The gateway's container. 10.21.21.69, clear of the Datum Companions (.62/.63 for
# BLAKE2b, .64/.65 for SHA256), Datum (SHA256) at .67, and the official apps.
export APP_DATUM_GATEWAY_BLAKE2B_IP="10.21.21.69"

# Stratum, published on the host for miners on your LAN. Clear of the official
# Datum app's 23334 and the Companions' 23336/23338. HashGG finds it on this port.
export APP_DATUM_GATEWAY_BLAKE2B_STRATUM_PORT="23342"
