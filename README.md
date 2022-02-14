# Brief description
Mostly, this repository is about one file - **docker-compose.yml**. This compose-file contains descriptions of
docker-services fitted for fast rebuild-deploy cycles that happens oftenly during development process. All services exists in a single virtual network. Some services also exposes ports to host machine

# Requirements
It is highly recomended to install latest versions of docker and docker-compose following instructions for your OS by this links:
- docker https://docs.docker.com/engine/install/
- docker-compose https://docs.docker.com/compose/install/

# Cloning

Update repository with *--recursive* flag:
> git clone --recursive https://github.com/ivandzen/neon-dev-environment.git

If you already have cloned a repository and now want to load it’s submodules you have to use submodule update:
> git submodule update --init --recursive

# Using

**NOTE!** Run this commands from current directory neon-dev-environment before starting to use any other commands:
> docker-compose pull --include-deps deploy-evm proxy proxy-test 
>
> docker-compose build builder

## Services
### solana
Solana development cluster. Usually one have to run this service once and then work with this instance. 
Running solana is simple as:
> docker-compose up -d solana

### builder
This service aimed for building evm_loader and all it's linked tools (neon-cli, faucet, etc.). When running, 
service attaches neon-dev submodule as volume inside container, and executes cargo build upon it's sources. 
All artifacts then will be placed under *neon-evm/evm_loader/target* directory. This approach provides fast rebuilds 
in case when only several files was changed. Run this command to build/rebuild neon-evm:
> docker-compose up builder

### cleaner
Cleaner service removes all artifacts produced by builder
> docker-compose up cleaner

### deploy-evm 
You can deploy evm_loader after it had been successfully built with next command: 
> docker-compose up deploy-evm

### proxy
To start proxy one should run command:
> docker-compose up -d proxy

Proxy service uses volumes to attach build artifacts produced by builder service into container therefore replacing files of original evm_loader image. So it will always use latest versions with your changes from neon-evm repository.

**NOTE**: This command will not deploy evm_loader by itself (as it is implemented in proxy/docker-compose-test.yml for example).
So you should perform deployment by yourself using previous commands.

To restart proxy service with latest changes use command:
> docker-compose restart proxy

### proxy-test
You can start proxy tests using command:
> docker-compose up proxy-test

Specify service's environment variable TESTNAME in docker-compose.yml if you want to start particular test

