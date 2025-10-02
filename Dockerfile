# ---------- Builder Stage ----------
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum* ./

# Download dependencies
RUN go mod download

# Copy source code
COPY main.go ./

# Build static binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-extldflags "-static"' -o startup-server .

# ---------- Export Binary Stage ----------
FROM scratch AS export-binary
COPY --from=builder /app/startup-server /startup-server

# ---------- Runtime Stage ----------
FROM alpine:3.19 AS runtime

WORKDIR /app

# Copy the static binary from builder
COPY --from=builder /app/startup-server /usr/local/bin/startup-server

# Expose the application port
EXPOSE 8081

# Run the startup server
ENTRYPOINT ["/usr/local/bin/startup-server"]
