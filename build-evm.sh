#!/bin/bash

cd neon-evm/evm_loader/cli

if [ -z "$NEON_REVISION" ]; then
   export NEON_REVISION=$(git log -1 --pretty=format:"%H")
fi

cargo build --release

cd ../program && ../ci_checks.sh

cargo build --release && \
    cargo build-bpf --features no-logs,devnet && cp ../target/deploy/evm_loader.so ../target/deploy/evm_loader-devnet.so && \
    cargo build-bpf --features no-logs,testnet && cp ../target/deploy/evm_loader.so ../target/deploy/evm_loader-testnet.so && \
    cargo build-bpf --features no-logs && cp ../target/deploy/evm_loader.so ../target/deploy/evm_loader-local.so
