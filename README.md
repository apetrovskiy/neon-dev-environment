# Neon-EVM development environment
This is integration repository containing scripts for development of neon-evm and proxy. 
It is aimed to simplify building and deployment of different components of neon-evm infrastructure from a single place

**NOTE** Always update repository with *--recursive* flag:
> git clone --recursive https://github.com/ivandzen/neon-dev-environment.git

If you already have cloned a repository and now want to load it’s submodules you have to use submodule update:
> git submodule update --init --recursive

# Using

## Building neon-evm
>docker-compose run build-evm

Sources located under *./neon-evm* directory will be used

**NOTE** Error of kind **error checking context: 'no permission to read from ...** means
that you should run command as superuser. This issue caused by files created from inside container
previously

## Deploying neon-evm to local solana cluster
>docker-compose run deploy-evm

There with be file *./neon-config.env* after successful deployment. 
It contains all the parameters necessary for starting proxy server

**NOTE** build-evm must be performed at least once

## Starting proxy server
>docker-compose run proxy

**NOTE** ./neon-config.env file must exist
