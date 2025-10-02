# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a lightweight FastAPI server that:
1. Receives environment variables via query parameters on the root endpoint (`/`)
2. Writes them to a `.env` file
3. Terminates itself after completion

The server is compiled into standalone binaries for Alpine and Ubuntu using PyInstaller, eliminating runtime Python dependencies.

## Build Commands

### Build Alpine Binary
```bash
docker buildx build -f alpine.Dockerfile \
  --platform linux/amd64 \
  --output type=local,dest=. \
  --target export-binary \
  ./
```

### Build Ubuntu Binary
```bash
docker buildx build -f ubuntu.Dockerfile \
  --platform linux/amd64 \
  --output type=local,dest=. \
  --target export-binary \
  ./
```

### Local Development
```bash
# Install dependencies
pip install -r requirements.txt

# Run the server locally
python startup-server.py
```

## Architecture

**Core Application** (`startup-server.py`):
- FastAPI server listening on port 8081
- `/` endpoint: Accepts query params, writes to `.env`, then kills server via background task
- `/heart_beat` endpoint: Health check returning "success"
- Uses KodeKloud custom libraries: `kk_logger` (logging) and `kk_request_id` (request ID middleware)

**Build Process**:
- Multi-stage Docker builds compile Python app into standalone ELF binary using PyInstaller
- Alpine build uses `alpine:3.19` base with musl-libc
- Ubuntu build uses `python:3.11-slim` base with glibc
- Uses `uv` package manager for faster dependency installation
- Final binary exported via `scratch` stage

**CI/CD** (`.github/workflows/build-release.yml`):
- Triggered on version tags (`v*`) or manual dispatch
- Builds both Alpine and Ubuntu binaries in parallel using matrix strategy
- Creates GitHub releases with both binaries attached

## Dependencies

External libraries in `requirements.txt`:
- Private GitLab packages: `python-kk-logger` (v0.1.4) and `python-kk-request-id` (v0.1.3) - require GitLab token
- FastAPI, Uvicorn, PyInstaller

## Important Notes

- The server intentionally terminates after processing the first request to `/` (via `os._exit(0)`)
- Authentication token for KodeKloud libraries is hardcoded in `requirements.txt`
- The compiled binary is statically linked and has no external Python runtime dependencies