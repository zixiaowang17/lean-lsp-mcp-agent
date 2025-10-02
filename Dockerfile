# Dockerfile
FROM python:3.11-slim

# OS deps for Lean
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git ca-certificates build-essential libgmp-dev bash \
 && rm -rf /var/lib/apt/lists/*

# Install Lean toolchain via elan (gives you `lean` + `lake`)
ENV ELAN_HOME=/root/.elan
ENV PATH="$ELAN_HOME/bin:${PATH}"
RUN bash -lc 'curl -fsSL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | bash -s -- -y --no-modify-path --default-toolchain leanprover/lean4:stable' \
 && bash -lc 'elan --version && lean --version && lake --version'

# Copy repo
WORKDIR /app
COPY . /app

# Install the MCP server runtime
RUN pip install --no-cache-dir lean-lsp-mcp

# Point to your committed Lean project
ENV LEAN_PROJECT_PATH=/app/lean-project
# Railway provides PORT; default for local runs
ENV PORT=8000
EXPOSE 8000

# Run the MCP server as a Streamable HTTP server
CMD ["bash", "-lc", "uvx lean-lsp-mcp --transport streamable-http --host 0.0.0.0 --port ${PORT}"]

