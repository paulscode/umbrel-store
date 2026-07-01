# Image build scripts

These scripts build and push the multi-arch Docker images referenced (by digest)
in each app's `docker-compose.yml`. They are maintainer tooling — you do **not**
need them to install the apps from the store.

Each script expects its upstream source repo to be checked out separately and
takes an environment-variable override for the source location:

| Script | Builds | Source repo (override var → default) |
|--------|--------|--------------------------------------|
| `agent-wallet/build-umbrel-images.sh` | `paulscode/agent-wallet-umbrel` | `AGENT_WALLET_STARTOS_DIR` → `../../../agent-wallet-startos` |
| `electrs-liquid/build-umbrel-images.sh` | `paulscode/elements-electrs` | `ELECTRS_LIQUID_STARTOS_DIR` → `../../../electrs-liquid-startos` |
| `mempool-bip110/build-umbrel-images.sh` | `paulscode/mempool-bip110-{frontend,backend}` | `MEMPOOL_BIP110_DIR` → `/mnt/1Lane/bip110-apps/mempool-bip110` |

The default relative paths assume `umbrel-store` is checked out under
`~/workspace` next to the StartOS repos.

`mempool-bip110/docker/` holds the Dockerfiles and mining-pool logos consumed by
that build (the logos are `.gitignored` in the upstream mempool-bip110 repo, so
they are vendored here).

HashGG's image is built from its own repo
([paulscode/hashgg](https://github.com/paulscode/hashgg)); there is no build
script for it here.

## Usage

```bash
# Build locally (amd64 only):
./agent-wallet/build-umbrel-images.sh

# Build multi-arch and push to Docker Hub (requires `docker login` as paulscode):
./agent-wallet/build-umbrel-images.sh --push
```

After a `--push`, copy the printed image digest into the matching app's
`docker-compose.yml` (`image: ...@sha256:<digest>`).
