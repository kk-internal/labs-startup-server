# ---------- Builder Stage ----------
FROM ubuntu:24.04 AS builder

# Install Python and build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    gcc \
    g++ \
    make \
    binutils \
    git \
    patchelf \
    scons \
    && rm -rf /var/lib/apt/lists/*

ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1

COPY --from=ghcr.io/astral-sh/uv:0.8.22 /uv /uvx /bin/

WORKDIR /app

# Install PyInstaller, staticx, and dependencies
ADD ./requirements.txt .
RUN uv pip install --system --break-system-packages -r requirements.txt && \
    uv pip install --system --break-system-packages staticx

# Copy startup-server.py into /opt
COPY ./startup-server.py .

# Build executable with PyInstaller
RUN pyinstaller --onefile --clean startup-server.py

# Create truly static binary with staticx
RUN staticx /app/dist/startup-server /app/dist/startup-server-static && \
    mv /app/dist/startup-server-static /app/dist/startup-server

# ---------- Final Output ----------
# The binary will be at /app/dist/startup-server

FROM scratch AS export-binary
COPY --from=builder /app/dist/startup-server /startup-server

# ---------- Runtime Stage ----------
FROM ubuntu:24.04 AS runtime

WORKDIR /app

# Copy the compiled binary from builder
COPY --from=builder /app/dist/startup-server /usr/local/bin/startup-server

# Expose the application port
EXPOSE 8081

# Run the startup server
ENTRYPOINT ["/usr/local/bin/startup-server"]