# Install BPF SDK
FROM solanalabs/rust:1.53.0 AS builder
RUN rustup component add clippy
WORKDIR /opt
RUN sh -c "$(curl -sSfL https://release.solana.com/v1.7.9/install)" && \
    /root/.local/share/solana/install/releases/1.7.9/solana-release/bin/sdk/bpf/scripts/install.sh
ENV PATH=/root/.local/share/solana/install/active_release/bin:/usr/local/cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
