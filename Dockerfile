# Custom Spilo image with pg_uuidv7 extension
# Based on official Zalando Spilo PostgreSQL 17 image

ARG SPILO_VERSION=4.0-p2
FROM ghcr.io/zalando/spilo-17:${SPILO_VERSION}

# Install build dependencies and pg_uuidv7 extension
RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        postgresql-server-dev-17 \
        git \
        ca-certificates \
    && cd /tmp \
    && git clone https://github.com/fboulnois/pg_uuidv7.git \
    && cd pg_uuidv7 \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/pg_uuidv7 \
    && apt-get purge -y --auto-remove \
        build-essential \
        postgresql-server-dev-17 \
        git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
