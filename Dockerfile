# Dockerfile
FROM python:3.11-slim

# At the very top, right after FROM
ARG FORCE_REBUILD=2025-10-02-1
# OS deps (zstd/xz required for Lean toolchain archives)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git ca-certificates build-essential libgmp-dev bash zstd xz-utils \
 && rm -rf /var/lib/apt/lists/*

# Install Lean toolchain via elan
ENV ELAN_HOME=/root/.elan
ENV PATH="/root/.elan/bin:${PATH}"
RUN set -eux; \
    curl -fsSL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -o /tmp/elan-init.sh; \
    bash /tmp/elan-init.sh -y --no-modify-path --default-toolchain leanprover/lean4:stable; \
    ls -lah /root/.elan/bin; \
    /root/.elan/bin/elan --version; \
    /root/.elan/bin/lean --version; \
    /root/.elan/bin/lake --version; \
    ln -s /root/.elan/bin/* /usr/local/bin/

WORKDIR /app
COPY . /app

# MCP server
RUN pip install --no-cache-dir lean-lsp-mcp

# (Optional) warm Lean cache if the project exists in the repo
RUN if [ -d "/app/lean-project" ]; then cd /app/lean-project && lake build; fi

# Tell the server where the Lean project lives (adjust if different)
ENV LEAN_PROJECT_PATH=/app/lean-project

# Railway sets PORT at runtime; default for local runs
ENV PORT=8000
EXPOSE 8000

# Start the MCP server (no login shell so PATH won't reset)
CMD ["bash","-c","exec lean-lsp-mcp --transport streamable-http --host 0.0.0.0 --port ${PORT}"]
