#!/bin/bash

function show_help {
   echo "Usage: deploy.sh <config>"
   echo "    <config> accepts next values:"
   echo "               - local - to deploy onto local environment"
   echo "               - testnet - to deploy onto testnet"
   echo "               - devnet - to deploy onto devnet"
}

function read_evm_loader_id {
   export EVM_LOADER=$(cat evm_loader_id | sed '/Program Id: \([0-9A-Za-z]\+\)/,${s//\1/;b};s/^.*$//;$q1')
}

function deploy_evm_loader {
   echo "Deploying evm_loader"
   cp ./neon-evm/evm_loader/evm_loader-keypair.json ./neon-evm/evm_loader/target/deploy/evm_loader-${CONFIG}-keypair.json
   solana program deploy --upgrade-authority ./neon-evm/evm_loader/target/deploy/evm_loader-${CONFIG}-keypair.json \
                         ./neon-evm/evm_loader/target/deploy/evm_loader-${CONFIG}.so > evm_loader_id
   read_evm_loader_id
}

function read_neon_revision() {
   if [ -z "$1" ]; then
      echo "read_neon_revision: dump file not specified"
      exit 1
   fi
   
   echo $(./neon-evm/evm_loader/target/release/neon-cli --evm_loader="$EVM_LOADER" neon-elf-params "$1" | grep 'NEON_REVISION=')
}

if [ -z "$1" ]; then
   show_help
   exit 1
fi

export CONFIG=$1

if [ "$CONFIG" == "local" ]; then
   export SOLANA_URL="http://localhost:8899"
elif [ "$CONFIG" == "devnet" ]; then
   export SOLANA_URL="https://api.devnet.solana.com"
elif [ "$CONFIG" == "testnet" ]; then
   export SOLANA_URL="https://api.testnet.solana.com"
else
   echo "Unsupported config '$CONFIG'"
   show_help
   exit 1
fi

echo "SOLANA_URL=$SOLANA_URL" > neon-config.env

solana config set -u $SOLANA_URL
solana config get

for i in {1..10}; do
    if solana cluster-version; then break; fi
    sleep 2
done


ADDRESS=$(solana address || echo "no wallet")

if [ "$ADDRESS" == "no wallet" ]; then
  solana-keygen new --no-passphrase
fi

if ! solana account $(solana address); then
  echo "airdropping..."
  solana airdrop 1000
  # check that balance >= 10 otherwise airdroping by 1 SOL up to 10
  BALANCE=$(solana balance | tr '.' '\t'| tr '[:space:]' '\t' | cut -f1)
  while [ "$BALANCE" -lt 10 ]; do
    solana airdrop 1
    sleep 1
    BALANCE=$(solana balance | tr '.' '\t'| tr '[:space:]' '\t' | cut -f1)
  done
fi

solana address
solana balance

# evm_loader_id file found - some program was deployed previously
# Check if it is still exist
# If yes - compare it's version with one to be deployed from .so file 
if [ -f 'evm_loader_id' ]; then
   read_evm_loader_id
   echo "Checking existence of program $EVM_LOADER..."
   if [ ! -z "$(solana account $EVM_LOADER)" ]; then
      echo "Program $EVM_LOADER already exist. Checking program version..."
      solana program dump "$EVM_LOADER" ./evm_loader.dump
      ONCHAIN_REVISION=$(read_neon_revision ./evm_loader.dump)
      SO_FILE_REVISION=$(read_neon_revision ./neon-evm/evm_loader/target/deploy/evm_loader-${CONFIG}.so)
      echo "On-chain: $ONCHAIN_REVISION"
      echo ".so file: $SO_FILE_REVISION"
      
      if [ "$ONCHAIN_REVISION" = "$SO_FILE_REVISION" ]; then
         echo "Program $EVM_LOADER with revision $SO_FILE_REVISION already deployed"
      else
         deploy_evm_loader
      fi
   else
      echo "Program $EVM_LOADER not found and will be deployed"
      deploy_evm_loader
   fi
else
   deploy_evm_loader
fi

echo "EVM_LOADER=$EVM_LOADER" >> neon-config.env
solana program dump "$EVM_LOADER" ./evm_loader.dump
./neon-evm/evm_loader/target/release/neon-cli --evm_loader="$EVM_LOADER" neon-elf-params ./evm_loader.dump >> neon-config.env


echo "A new token will be created. Creating token..."
export ETH_TOKEN_MINT=$(spl-token create-token --owner neon-evm/evm_loader/test_token_owner -- neon-evm/evm_loader/test_token_keypair | grep -Po 'Creating token \K[^\n]*')
echo "ETH_TOKEN_MINT=$ETH_TOKEN_MINT" >> neon-config.env

echo "A new collateral pool accounts will be created. Creating accounts..."
#generate collateral pool accounts
solana -k neon-evm/evm_loader/collateral-pool-keypair.json airdrop 1000
python3 neon-evm/evm_loader/collateral_pool_generator.py neon-evm/evm_loader/collateral-pool-keypair.json
echo "COLLATERAL_POOL_BASE=$(solana-keygen pubkey -f neon-evm/evm_loader/collateral-pool-keypair.json)" >> neon-config.env

