FROM ruby:3.3-slim-bookworm

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential git libsqlite3-dev libpq-dev libssl-dev curl unzip \
    python3 python3-venv python3-pip tzdata \
    && rm -rf /var/lib/apt/lists/*

# Tickrake's DuckDB gem needs the same library as its upstream image.
ARG DUCKDB_VERSION=1.5.4
RUN arch="$(dpkg --print-architecture)" && \
    curl -fsSL "https://github.com/duckdb/duckdb/releases/download/v${DUCKDB_VERSION}/libduckdb-linux-${arch}.zip" -o /tmp/libduckdb.zip && \
    unzip /tmp/libduckdb.zip -d /tmp/libduckdb && \
    cp /tmp/libduckdb/duckdb.h /usr/local/include/ && \
    cp /tmp/libduckdb/libduckdb.so /usr/local/lib/ && \
    ldconfig && rm -rf /tmp/libduckdb /tmp/libduckdb.zip

COPY --from=tickrake . /opt/tickrake
WORKDIR /opt/tickrake
RUN bundle install && ln -s /opt/tickrake/exe/tickrake /usr/local/bin/tickrake

COPY --from=tractatus . /opt/tractatus
RUN python3 -m venv /opt/uv-venv && /opt/uv-venv/bin/pip install --no-cache-dir uv
WORKDIR /opt/tractatus
RUN /opt/uv-venv/bin/uv sync --no-dev --frozen

ENV PATH="/usr/local/bin:/opt/tractatus/.venv/bin:/opt/uv-venv/bin:${PATH}" \
    HOME=/root PYTHONUNBUFFERED=1
RUN mkdir -p /root/.tickrake/logs
RUN rm /usr/local/bin/tickrake && \
    printf '%s\n' '#!/bin/sh' 'exec ruby /opt/tickrake/exe/tickrake "$@"' > /usr/local/bin/tickrake && \
    chmod +x /usr/local/bin/tickrake
RUN apt-get update -qq && apt-get install -y --no-install-recommends sqlite3 \
    && rm -rf /var/lib/apt/lists/*
ENTRYPOINT ["/bin/bash"]
