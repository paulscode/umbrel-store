# PaulsCode.Com Umbrel Community App Store

An [Umbrel](https://umbrel.com) community app store bringing together all of
[Paul Lamb](https://paulscode.com)'s Umbrel apps under one heading.

## How to add this store to your Umbrel

1. Open your Umbrel dashboard.
2. Go to **App Store**.
3. Click the ellipsis (⋯) in the upper-right, then **Community App Stores**.
4. Paste the URL of this repo:
   ```
   https://github.com/paulscode/umbrel-store
   ```
5. Click **Add**.
6. The **PaulsCode.Com** app store now appears under its own heading.

## Apps in this store

| App | What it does | Requires |
|-----|--------------|----------|
| [Agent Wallet](#agent-wallet) | Self-custodial Bitcoin & Lightning wallet with an automation API for AI agents | Lightning Node (LND) + Electrs/Fulcrum |
| [Electrs Liquid](#electrs-liquid) | A Liquid (`liquidv1`) full node bundled with an Electrum indexer | none (self-contained) |
| [HashGG](#hashgg) | Sovereign hash routing — exposes your Datum stratum port to the public internet | Datum (→ Bitcoin Knots) |
| [Mempool BIP-110](#mempool-bip-110) | Mempool block explorer fork that visualizes BIP-110 activation activity | Bitcoin Node (+ Electrs) |
| [Pickhash](#pickhash) | Autonomously rents Bitcoin hashrate from MiningRigRentals and points it at your own pool | none (optional: HashGG) |

---

### Agent Wallet

A self-custodial Bitcoin and Lightning wallet that connects to your Umbrel's
**Lightning Node (LND)** and exposes a dashboard plus a programmatic API designed
for AI agents to initiate payments within configured limits. It uses your
installed Electrum indexer (Electrs **or** Fulcrum) for on-chain lookups, and an
optional Mempool explorer (the official **Mempool** or **Mempool BIP-110** below)
for fee estimates and links. It also includes a BOLT 12 onion-message gateway and
an optional, experimental Anonymize feature (with an optional Liquid hop that can
use **Electrs Liquid** below).

> ⚠️ Anyone holding the dashboard password or an issued API key can spend from
> the connected LND node up to its limits. Treat the dashboard password and API
> keys like cash. Get your dashboard password by right-clicking the Agent Wallet
> tile and choosing **Show default credentials** — that value is your login.

The wallet bundles its own PostgreSQL, Redis, and Tor (supervised by s6-overlay)
in a single container — the same image contract as the StartOS package.

**Requirements:** Lightning Node (LND) — required; Electrs **or** Fulcrum —
required; Mempool — optional.

#### Advanced configuration

Umbrel has no per-app settings form, so feature toggles default to sensible
values. To change them, edit the `environment:` block of the `web` service in
[`paulscode-agent-wallet/docker-compose.yml`](paulscode-agent-wallet/docker-compose.yml)
and restart the app:

| Variable | Default | Effect |
|----------|---------|--------|
| `AGENT_WALLET_BOLT12` | `true` | BOLT 12 onion-message gateway |
| `AGENT_WALLET_BRAIINS_DEPOSIT` | `true` | Braiins deposit tab |
| `AGENT_WALLET_ANONYMIZE` | `false` | Experimental Anonymize feature (needs Tor; bundled) |
| `AGENT_WALLET_LIQUID` | `false` | Liquid hop for Anonymize (needs the Electrs Liquid app) |
| `AGENT_WALLET_LOG_LEVEL` | `INFO` | `ERROR` / `WARN` / `INFO` / `DEBUG` / `TRACE` |

- Source: https://github.com/paulscode/agent-wallet
- Issues: https://github.com/paulscode/agent-wallet/issues

---

### Electrs Liquid

Runs a Liquid full node (`elementsd`) and an Electrum indexer (`electrs`, built
`--features liquid`) together in one app. Other apps and wallets can use the
Electrum endpoint to query Liquid balances and transaction history and to
broadcast transactions, without relying on external Liquid Electrum servers.

> ⚠️ **Heavyweight.** Stores the full Liquid chain plus its address index
> (~115 GB of disk) and uses ~14 GiB of RAM during the initial sync. It is meant
> to run alongside other Bitcoin/Lightning services, so ≥32 GB of total RAM is
> recommended. The first sync can take many hours. Self-contained: it does
> **not** require the Bitcoin app.

**Connecting:**

- **Other Umbrel apps** can add `paulscode-electrs-liquid` as a dependency and
  read `APP_ELECTRS_LIQUID_ELECTRS_NODE_IP` / `_NODE_PORT` (internal Electrum
  port `50001`).
- **Wallets on your LAN** can connect an Electrum-compatible Liquid wallet to
  your Umbrel's address on port **50101** (mapped to the indexer's internal
  `50001`; `50101` avoids colliding with the Bitcoin Electrs app's `50001`).

- Source: https://github.com/paulscode/electrs-liquid-startos

---

### HashGG

Sovereign hash routing for your Bitcoin miners. Exposes your
[Datum Gateway](https://github.com/ocean-xyz/datum_gateway) stratum port to the
public internet via [playit.gg](https://playit.gg) or an SSH tunnel to a VPS you
control — so any miner, anywhere, can connect to your node and mine blocks *you*
built. No router configuration, no dynamic DNS, no VPN; works behind NAT, double
NAT, or CGNAT.

Requires the official [**Datum**](https://apps.umbrel.com/app/datum) Umbrel app
(which in turn requires the **Bitcoin Knots** app). Install Datum first, then
install HashGG and pick a tunnel mode in its web UI.

- Source: https://github.com/paulscode/hashgg
- Issues: https://github.com/paulscode/hashgg/issues

---

### Mempool BIP-110

A specialized fork of the [Mempool](https://mempool.space) block explorer that
visualizes [BIP-110 (Reduced Data Temporary Softfork)](https://github.com/dathonohm/bips/blob/reduced-data/bip-0110.mediawiki)
activity on the Bitcoin network:

- 🟢 **Miner signaling detection** — blocks from miners signaling BIP-110 support glow green/gold
- 🟠 **Violation highlighting** — transactions that would be invalid under BIP-110 rules glow neon orange
- 📊 **Full Mempool functionality** — all standard explorer features (mempool, blocks, transactions, mining dashboard)

**Requirements:** a fully synced **Bitcoin Node**; **Electrs** recommended.

- Source: https://github.com/paulscode/mempool-bip110

---

### Pickhash

Rent Bitcoin hashrate on your own terms. Pickhash autonomously rents SHA-256
(AsicBoost) hashrate from [MiningRigRentals](https://www.miningrigrentals.com)
and points it at *your* stratum endpoint — typically your Bitcoin node behind a
[Datum Gateway](https://github.com/ocean-xyz/datum_gateway) — so the hashrate you
pay for mines *your* block templates.

You set a target hashrate, a budget, and a duration; Pickhash finds reliable
rigs, prices and creates the rentals, points them at your pool, and watches over
delivery (ramp-up, under-delivery, offline rigs, refunds). It starts in DRY-RUN
(a rehearsal that spends nothing); going LIVE requires a dashboard password.

> ⚠️ Pickhash spends real Bitcoin on your behalf, within the budget and
> guardrails you set. Marketplace credentials are encrypted at rest. Set a
> dashboard password before switching to LIVE.

Optionally pair it with the [**HashGG**](#hashgg) app above to auto-discover your
public stratum endpoint — not required; you can enter any reachable `host:port`.

- Source: https://github.com/paulscode/pickhash
- Issues: https://github.com/paulscode/pickhash/issues

---

## Requirements

- **Umbrel** (umbrelOS 1.x or later)
- Per-app dependencies as listed above.

## Building the images

The container images referenced by these apps are published to Docker Hub under
`paulscode/*` and pinned by digest in each app's `docker-compose.yml`. The
scripts that build and push them live in [`build/`](build/) — see
[`build/README.md`](build/README.md).

## Support

- Store issues (packaging): https://github.com/paulscode/umbrel-store/issues
- Per-app issues: see each app's links above.
- Umbrel (general): https://community.umbrel.com

## License

MIT — see [LICENSE](LICENSE). The Mempool BIP-110 fork itself is licensed under
the GNU Affero General Public License v3.0.

## Notes

- **Architecture:** all images are published multi-arch (linux/amd64 +
  linux/arm64). The arm64 builds have not been hardware-tested by the author;
  please report issues if you hit any.
