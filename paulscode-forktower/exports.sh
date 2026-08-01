#!/bin/bash

# Forktower exports.
#
# A static IP for the container, plus host-side detection of the two things
# Forktower can use but does not require: a Lightning node, and which Bitcoin
# app is installed.
#
# 10.21.21.61 sits next to agent-wallet's .60, clear of the official apps
# (electrs 10.21.21.10, fulcrum 10.21.21.200, mempool 10.21.21.26-28,
# electrs-liquid 10.21.21.50, mempool-bip110 10.21.21.240-242).

export APP_FORKTOWER_IP="10.21.21.61"

# ── The Lightning node ────────────────────────────────────────────────────────
#
# Deliberately not a declared dependency. Forktower's first job is watching two
# chains, and it does that with no Lightning node at all — what a node adds is
# the ability to say *which of your channels* a split would expose. Requiring one
# would refuse the install to somebody who wants exactly the part that works
# without it.
#
# umbrelOS only sources the exports of an app's *declared* dependencies, so an
# optional one has to be found on disk. Detected by the directory rather than by
# `${UMBREL_ROOT}/scripts/app ls-installed`, which the neighbouring apps use and
# which **does not exist on umbrelOS 1.x** — it fails silently, and the failure
# looks exactly like not having a Lightning node.
lnd_dir="${UMBREL_ROOT}/app-data/lightning/data/lnd"
chain_dir="${lnd_dir}/data/chain/bitcoin"

if [ -d "${lnd_dir}" ]; then
  # A fixed address, because we cannot read the Lightning app's own exports for
  # it. This is the value that app publishes and has published for years; if it
  # ever moves, this is the line to change.
  export APP_FORKTOWER_LND_IP="10.21.21.9"
  export APP_FORKTOWER_LND_REST_PORT="8080"

  # The two credential files, bound individually rather than the directory that
  # holds them. The read-only macaroon is the one LND wrote itself when the
  # wallet was created; it answers everything Forktower asks and can do nothing
  # else. Nothing here is ever given a credential that can move money.
  #
  # Which network LND wrote them under is read rather than assumed. A wrong
  # guess reads on the dashboard as "your node has no channels", which is a bad
  # way to learn about a path.
  for net in mainnet testnet signet regtest; do
    if [ -f "${chain_dir}/${net}/readonly.macaroon" ]; then
      export APP_FORKTOWER_LND_MACAROON="${chain_dir}/${net}/readonly.macaroon"
      break
    fi
  done

  if [ -f "${lnd_dir}/tls.cert" ]; then
    export APP_FORKTOWER_LND_CERT="${lnd_dir}/tls.cert"
  fi
fi

# ── The Bitcoin node ──────────────────────────────────────────────────────────
#
# Declared as a dependency on `bitcoin` in umbrel-app.yml, which is what gets its
# exports sourced into this app's environment at all — and it does not exclude
# Bitcoin Knots users, because that app declares `implements: [bitcoin]` and
# Umbrel lets a user satisfy the dependency with it. Both matter here: a Knots
# user is enforcing the new rules whether or not they decided to, and a Core user
# is on the status-quo side and equally blind to the other chain.
#
# Nothing to do here; this comment is, so that the absence is read as settled
# rather than forgotten.
