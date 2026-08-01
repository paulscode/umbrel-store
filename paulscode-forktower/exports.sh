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
# umbrelOS only injects the environment of an app's *required* dependencies, so
# an optional one has to be detected here — the same pattern the neighbouring
# apps use for an optional Mempool.
installed="$("${UMBREL_ROOT}/scripts/app" ls-installed 2>/dev/null | tr ' ' '\n' || true)"

if echo "${installed}" | grep -qxF "lightning"; then
  export APP_FORKTOWER_LND_IP="10.21.21.9"
  export APP_FORKTOWER_LND_REST_PORT="8080"

  # The two credential files, bound individually rather than the directory that
  # holds them. The read-only macaroon is the one LND wrote itself when the
  # wallet was created; it answers everything Forktower asks and can do nothing
  # else. Nothing here is ever given a credential that can move money.
  lnd_dir="${UMBREL_ROOT}/app-data/lightning/data/lnd"
  chain_dir="${lnd_dir}/data/chain/bitcoin"

  # Which network LND actually wrote its macaroons under, rather than assuming
  # mainnet. A wrong guess here reads on the dashboard as "your node has no
  # channels", which is a bad way to learn about a path.
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
# Not declared either, and for a sharper reason: there are two apps, `bitcoin`
# and `bitcoin-knots`, exporting different variable prefixes. Requiring one would
# exclude the other, and both are people Forktower is for — a Knots user is
# enforcing the new rules whether or not they decided to, and a Core user is on
# the status-quo side and equally blind to the other chain.
#
# Both prefixes are passed through in docker-compose.yml and the container's
# entrypoint picks whichever exists. Nothing is needed here; this comment is, so
# that the absent dependency is read as a decision rather than an oversight.
