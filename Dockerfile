# Dockerfile
FROM python:3.11-slim

# OS deps for Lean + tooling to extract .zst/.xz archives
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git ca-certificates build-essential libgmp-dev bash zstd xz-utils \
 && rm -rf /var/lib/apt/lists/*

# Install Lean toolchain via elan (installs lean + lake under /root/.elan/bin)
ENV ELAN_HOME=/root/.elan
ENV PATH="/root/.elan/bin:${PATH}"
RUN set -eux; \
    curl -fsSL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -o /tmp/elan-init.sh; \
    bash /tmp/elan-init.sh -y --no-modify-path --default-toolchain leanprover/lean4:stable; \
    ls -lah /root/.elan/bin; \
    /root/.elan/bin/elan --version; \
    /root/.elan/bin/lean --version; \
    /root/.elan/bin/lake --version

# App code
WORKDIR /app
COPY . /app

# Install the MCP server
RUN pip install --no-cache-dir lean-lsp-mcp

# (Optional) warm Lean build cache if you committed a project at /app/lean-project
# Comment out if you used a different folder name
RUN bash -lc 'if [ -d "/app/lean-project" ]; then cd /app/lean-project && lake build; fi'

# Tell the server where your Lean project lives (adjust if different)
ENV LEAN_PROJECT_PATH=/app/lean-project

# Railway-provided PORT; default for local runs
ENV PORT=8000
EXPOSE 8000

# Start the MCP server using Streamable HTTP
# Use the installed console script (no uvx required)
CMD ["bash","-lc","lean-lsp-mcp --transport streamable-http --host 0.0.0.0 --port ${PORT}"]
