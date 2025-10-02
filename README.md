# Startup Server

A lightweight FastAPI server that receives environment variables via query parameters and writes them to a `.env` file before terminating.

## Building Binaries

### Export Binary Only (for CI/CD)

```shell
# Alpine
docker buildx build -f alpine.Dockerfile \
  --platform linux/amd64 \
  --output type=local,dest=. \
  --target export-binary \
  ./

# Ubuntu
docker buildx build -f ubuntu.Dockerfile \
  --platform linux/amd64 \
  --output type=local,dest=. \
  --target export-binary \
  ./
```

## Running and Testing

### Build and Run with Docker

```shell
# Build the runtime image for ARM64 (Apple Silicon)
docker buildx build -f ubuntu.Dockerfile \
  --platform linux/arm64 \
  --target runtime \
  --load \
  -t startup-server:test \
  ./

# Build the runtime image for AMD64 (Intel/x86)
docker buildx build -f ubuntu.Dockerfile \
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
pip install -r requirements.txt

# Run the server
python startup-server.py
```

## Endpoints

- `GET /` - Accepts query parameters, writes them to `.env`, then terminates the server
- `GET /heart_beat` - Health check endpoint