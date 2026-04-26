# forge-ui-forge live-mode tests

Tests for the `live` subcommand (HTTP+WebSocket reverse proxy that injects
the overlay into an existing dev server's responses).

## Running

```bash
# from the repo root
plugins/forge-ui-forge/.venv-dev/bin/python -m pytest plugins/forge-ui-forge/tests/live/ -v
```

The venv is created locally per plugin (gitignored). To recreate:

```bash
cd plugins/forge-ui-forge
python3 -m venv .venv-dev
.venv-dev/bin/pip install aiohttp pytest pytest-asyncio
```

Tests are skipped automatically when `aiohttp` is not importable (so the
plugin still works in prototype mode without aiohttp installed).
