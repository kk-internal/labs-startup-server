# ---------- Builder Stage ----------
FROM python:3.11-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    make \
    binutils \
    git \
    && rm -rf /var/lib/apt/lists/*

ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1

COPY --from=ghcr.io/astral-sh/uv:0.8.22 /uv /uvx /bin/

WORKDIR /app

# Install PyInstaller and dependencies
ADD ./requirements.txt .
RUN uv pip install --system --break-system-packages -r requirements.txt

# Copy startup-server.py into /opt
COPY ./startup-server.py .

# Build executable
RUN pyinstaller --onefile --clean startup-server.py

# ---------- Final Output ----------
# The binary will be at /app/dist/startup-server

FROM scratch AS export-binary
COPY --from=builder /app/dist/startup-server /startup-server