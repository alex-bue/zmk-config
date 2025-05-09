FROM python:3.12-slim

RUN apt-get update && \
    apt-get install -y curl git make && \
    pip install keymap-drawer && \
    curl -L https://github.com/mikefarah/yq/releases/download/v4.43.1/yq_linux_amd64 -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq && \
    git clone --depth 1 https://github.com/urob/zmk-helpers.git /zmk-helpers && \
    apt-get clean && rm -rf /var/lib/apt/lists/*



