# Startup Server

A lightweight HTTP server written in Go that receives environment variables via query parameters and writes them to a `.env` file before terminating.

## Building Binaries

### Export Binary Only (for CI/CD)

```shell
# Build for AMD64 (Intel/x86)
docker buildx build -f Dockerfile \
  --platform linux/amd64 \
  --output type=local,dest=. \
  --target export-binary \
  ./

# Build for ARM64 (Apple Silicon, ARM servers)
docker buildx build -f Dockerfile \
  --platform linux/arm64 \
  --output type=local,dest=. \
  --target export-binary \
  ./
```

The exported binary is fully static and works on **any** Linux distribution.

## Running and Testing

### Build and Run with Docker

```shell
# Build the runtime image for ARM64 (Apple Silicon)
docker buildx build -f Dockerfile \
  --platform linux/arm64 \
  --target runtime \
  --load \
  -t startup-server:test \
  ./

# Build the runtime image for AMD64 (Intel/x86)
docker buildx build -f Dockerfile \
  --platform linux/amd64 \
  --target runtime \
  --load \
  -t startup-server:test \
  ./

# Run the server
docker run -p 8081:8081 startup-server:test

# Test endpoints
curl "http://localhost:8081/?KEY1=value1&KEY2=value2"
curl "http://localhost:8081/heart_beat"
```

### Local Development

```shell
# Install dependencies
go mod download

# Run the server
go run main.go

# Or build locally
go build -o startup-server main.go
./startup-server
```

## Endpoints

- `GET /` - Accepts query parameters, writes them to `.env`, then terminates the server
- `GET /heart_beat` - Health check endpoint

## Features

- **Truly static binary** - No runtime dependencies, works on any Linux
- **Structured JSON logging** with request IDs
- **Cross-platform** - Builds for AMD64 and ARM64
- **Lightweight** - ~6MB binary size