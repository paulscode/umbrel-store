#!/usr/bin/env python3
"""Serve this app's page and let the user choose which node it indexes.

Umbrel has no per-app settings form, so an app that needs a choice has to serve one.
The BLAKE2b node and DATUM Gateway apps in this store already do exactly this, writing
a small JSON file that their entrypoints read at start, and this follows that pattern
rather than inventing a second one.

The choice is written to /config/settings.json. It is read by `exports.sh` on the host
at app start, not by this process, which is why changing it needs a restart: by the
time this page runs, the containers have already been given the addresses they will
use for their lifetime.

Deliberately dependency-free and read-mostly. It runs from a stock python image with
the app directory mounted, so there is no image to build and nothing to keep in step
with the electrs image next to it.
"""

import html
import json
import os
import re
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs

WEB_DIR = os.environ.get("WEB_DIR", "/web")
SETTINGS_FILE = os.environ.get("SETTINGS_FILE", "/config/settings.json")
PORT = int(os.environ.get("PORT", "80"))

# Which nodes this app can index, and what to call them.
#
# Keys are what gets written to settings.json and matched in exports.sh; changing one
# is a breaking change for an install that has already chosen it. The BLAKE2b entry is
# offered whether or not that app is installed, because this page cannot see the host's
# environment; choosing it without the app present leaves electrs unable to connect,
# which its own log says plainly.
BACKENDS = {
    "bitcoin": "Bitcoin Node (the official app)",
    "knots-blake2b": "Knots (BLAKE2b) Companion",
}
DEFAULT_BACKEND = "bitcoin"


def read_backend():
    """The chosen node, or the default when nothing valid has been chosen.

    Tolerant on purpose: an unreadable or malformed file means nobody has chosen yet,
    or something truncated it, and the honest response to either is the default rather
    than a stack trace on a page whose job is to fix it.
    """
    try:
        with open(SETTINGS_FILE) as f:
            value = json.load(f).get("backend")
    except (OSError, ValueError):
        return DEFAULT_BACKEND
    return value if value in BACKENDS else DEFAULT_BACKEND


def write_backend(value):
    """Record the choice, preserving any other keys the file already holds.

    Read-modify-write rather than overwrite, so a key some future version of this app
    adds is not silently dropped by an older page that does not know about it.
    """
    if value not in BACKENDS:
        raise ValueError(f"unknown backend {value!r}")
    try:
        with open(SETTINGS_FILE) as f:
            data = json.load(f)
        if not isinstance(data, dict):
            data = {}
    except (OSError, ValueError):
        data = {}
    data["backend"] = value

    # Write and rename, so a crash mid-write cannot leave exports.sh reading half a
    # file at the next start and resolving a node nobody chose.
    tmp = SETTINGS_FILE + ".tmp"
    os.makedirs(os.path.dirname(SETTINGS_FILE), exist_ok=True)
    with open(tmp, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    os.replace(tmp, SETTINGS_FILE)


def page(selected, saved=False):
    base = ""
    try:
        with open(os.path.join(WEB_DIR, "index.html")) as f:
            base = f.read()
    except OSError:
        base = "<!doctype html><meta charset=utf-8><title>Electrs Pruned</title>"

    options = "\n".join(
        '<option value="{v}"{sel}>{label}</option>'.format(
            v=html.escape(k),
            sel=" selected" if k == selected else "",
            label=html.escape(v),
        )
        for k, v in BACKENDS.items()
    )
    notice = (
        '<p style="background:#e7f6e7;padding:.6rem .9rem;border-radius:.3rem">'
        "Saved. Restart this app for it to take effect.</p>"
        if saved
        else ""
    )
    form = f"""
<h2>Which node to index</h2>
{notice}
<form method="post" action="/settings">
  <select name="backend">{options}</select>
  <button type="submit">Save</button>
</form>
<p>The two chains parted in August 2026, so this is a choice of chain as much as of
   node. Changing it makes the address index describe a different chain, so electrs
   discards it and builds a new one, which takes hours.</p>
<p>Restart the app after saving. The addresses each container uses are fixed when it
   starts, so a change made here reaches them at the next start and not before.</p>
"""
    return base + form


class Handler(BaseHTTPRequestHandler):
    # The default logs a line per request to stderr, which on Umbrel is the app's log.
    # A page polled by a browser would bury anything worth reading there.
    def log_message(self, *args):
        pass

    def _send(self, body, status=200):
        data = body.encode()
        self.send_response(status)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        self._send(page(read_backend(), saved=self.path.endswith("?saved=1")))

    def do_POST(self):
        length = int(self.headers.get("Content-Length") or 0)
        form = parse_qs(self.rfile.read(length).decode())
        value = (form.get("backend") or [""])[0]
        try:
            write_backend(value)
        except (ValueError, OSError) as e:
            self._send(page(read_backend()) + f"<p>Could not save: {html.escape(str(e))}</p>", 400)
            return
        # Redirect rather than render, so a refresh does not repost the form.
        self.send_response(303)
        self.send_header("Location", "/?saved=1")
        self.end_headers()


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
