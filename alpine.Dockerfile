# ---------- Builder Stage ----------
FROM alpine:3.19 AS builder

# Install Python and build dependencies
RUN apk add --no-cache \
    python3 \
    py3-pip \
    gcc \
    g++ \
    musl-dev \
    libffi-dev \
    make \
    binutils \
    libc-dev \
    git

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
# The binary will be at /opt/dist/startup-server

FROM scratch AS export-binary
COPY --from=builder /app/dist/startup-server /startup-server
