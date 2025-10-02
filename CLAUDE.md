# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a lightweight HTTP server written in Go that:
1. Receives environment variables via query parameters on the root endpoint (`/`)
2. Writes them to a `.env` file
3. Terminates itself after completion

The server is compiled into a truly static binary with zero runtime dependencies, working on any Linux distribution and architecture.

## Build Commands

### Build Binary for Export (CI/CD)
```bash
# AMD64
docker buildx build -f Dockerfile \
  --platform linux/amd64 \
  --output type=local,dest=. \
  --target export-binary \
  ./

# ARM64
docker buildx build -f Dockerfile \
  --platform linux/arm64 \
  --output type=local,dest=. \
  --target export-binary \
  ./
```

### Build and Run with Docker
```bash
# Build runtime image
docker buildx build -f Dockerfile \
  --platform linux/arm64 \
  --target runtime \
  --load \
  -t startup-server:test \
  ./

# Run
docker run -p 8081:8081 startup-server:test
```

### Local Development
```bash
# Run directly
go run main.go

# Build locally
go build -o startup-server main.go
./startup-server
```

## Architecture

**Core Application** (`main.go`):
- Standard library HTTP server listening on port 8081
- `/` endpoint: Accepts query params, writes to `.env`, logs with request ID, then exits via goroutine
- `/heart_beat` endpoint: Health check returning "success"
- Structured JSON logging with UUID-based request IDs
- Request ID middleware adds `X-Request-ID` header to all responses

**Build Process**:
- Multi-stage Docker build using `golang:1.21-alpine`
- `CGO_ENABLED=0` creates fully static binary with no libc dependencies
- Binary works on any Linux distro (Alpine, Ubuntu, Debian, CentOS, etc.)
- `export-binary` stage outputs just the binary for CI/CD
- `runtime` stage uses minimal Alpine base for testing

**CI/CD** (`.github/workflows/build-release.yml`):
- Triggered on version tags (`v*`) or manual dispatch
- Builds binaries for both AMD64 and ARM64 platforms
- Creates GitHub releases with both binaries attached

## Dependencies

Only one external Go dependency:
- `github.com/google/uuid` v1.6.0 - for generating request IDs

## Important Notes

- The binary is **truly static** - no GLIBC, musl, or any system library dependencies
- Binary size is approximately 6MB
- Server intentionally terminates after processing the first request to `/`
- Shutdown happens in a goroutine with 100ms delay to allow response to be sent