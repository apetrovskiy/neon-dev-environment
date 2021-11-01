# Build Solidity contracts
FROM ethereum/solc:0.7.0 AS solc
FROM ubuntu:20.04 AS contracts
RUN apt-get update && \
    DEBIAN_FRONTEND=nontineractive apt-get -y install xxd && \
    rm -rf /var/lib/apt/lists/* /var/lib/apt/cache/*
COPY neon-evm/evm_loader/*.sol /opt/
COPY neon-evm/evm_loader/precompiles_testdata.json /opt/
COPY --from=solc /usr/bin/solc /usr/bin/solc
WORKDIR /opt/
RUN solc --output-dir . --bin *.sol && \
    for file in $(ls *.bin); do xxd -r -p $file >${file}ary; done && \
        ls -l

# Define solana-image that contains utility
FROM neonlabsorg/solana:v1.7.9-resources AS solana

# Install BPF SDK
FROM solanalabs/rust:1.53.0 AS builder
RUN rustup component add clippy
WORKDIR /opt
RUN sh -c "$(curl -sSfL https://release.solana.com/v1.7.9/install)" && \
    /root/.local/share/solana/install/releases/1.7.9/solana-release/bin/sdk/bpf/scripts/install.sh
ENV PATH=/root/.local/share/solana/install/active_release/bin:/usr/local/cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Download and build spl-token
FROM builder AS spl-token-builder
ADD http://github.com/solana-labs/solana-program-library/archive/refs/tags/token-cli-v2.0.14.tar.gz /opt/
RUN tar -xvf /opt/token-cli-v2.0.14.tar.gz && \
    cd /opt/solana-program-library-token-cli-v2.0.14/token/cli && \
    cargo build --release && \
    cp /opt/solana-program-library-token-cli-v2.0.14/target/release/spl-token /opt/

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install vim less openssl ca-certificates curl python3 python3-pip parallel && \
    rm -rf /var/lib/apt/lists/*

COPY neon-evm/evm_loader/test_requirements.txt neon-evm/solana-py.patch /tmp/
RUN pip3 install -r /tmp/test_requirements.txt
RUN cd /usr/local/lib/python3.7/dist-packages/ && patch -p0 </tmp/solana-py.patch

COPY --from=solana /opt/solana/bin/solana /opt/solana/bin/solana-keygen /opt/solana/bin/solana-faucet /opt/solana/bin/
COPY --from=contracts /opt/ /opt/solidity/
COPY --from=contracts /usr/bin/solc /usr/bin/solc

RUN solana-keygen new --no-passphrase
COPY neon-evm/evm_loader/*.py \
     neon-evm/evm_loader/deploy-test.sh \
     neon-evm/evm_loader/test_token_keypair \
     neon-evm/evm_loader/test_token_owner \
     neon-evm/evm_loader/test_token_config.yml /spl/bin/
     
COPY proxy-model.py/requirements.txt /tmp/proxy-requirements.txt
RUN pip3 install -r /tmp/proxy-requirements.txt
ENV PATH=$PATH:/opt/neon-dev-env/neon-evm/evm_loader/target/release
#RUN solana airdrop 100500

