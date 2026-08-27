# Settings shared between the two apps

`settings.json` here holds the chain and the payout address. It is written by the
Datum Gateway BLAKE2b app's page and read by both the node and the gateway, which
watch it and restart themselves when it changes.

It lives with the node rather than with the gateway because the chain is the
node's setting, and the gateway already reads this app's data directory for the
RPC cookie.

A real file rather than a `.gitkeep`, so the directory certainly survives Umbrel's
copy into `app-data` and is owned by the same user the containers run as. If
Docker had to create it instead, it would be owned by root and the page could not
write here.

Nothing here needs editing by hand. Use the page.
