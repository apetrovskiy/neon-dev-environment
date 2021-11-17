#!/bin/bash

function setup_env() {
  cd ./neon-evm
  echo ""
  echo "neon-evm branch:"
  git branch --show-current
  export EVM_LOADER_REVISION=$(git rev-parse HEAD)
  echo "EVM_LOADER_REVISION=$EVM_LOADER_REVISION"
  cd ../proxy-model.py
  echo ""
  echo "proxy-model.py branch:"
  git branch --show-current
  PROXY_REVISION=$(git rev-parse HEAD)
  echo "PROXY_REVISION=$PROXY_REVISION"
  cd ../
}

function build_containers() {
  docker-compose -f docker-compose.yml build
}

function build_evm() {
  docker-compose -f docker-compose.yml run evm_builder
}

function deploy_evm() {
  docker-compose -f docker-compose.yml run evm_loader
}

function stop() {
  echo "Stopping services: $@..."
  docker stop $@
}

function start() {
  echo "Starting services: $@..."
  docker-compose -f docker-compose.yml up $@
}

function clean_evm_build() {
  echo "Removing build artifacts from neon-evm repo"
  sudo rm -r ./neon-evm/evm_loader/target
}

function view_logs() {
  if [ -z "$1" ]; then
    echo "usage: ./do view_logs <SERVICE>"
    exit 1
  fi
  
  docker logs -f $1
}

function exec() {
  docker exec $1 "${@:2}"
}

function save_logs() {
  if docker logs proxy >proxy.log 2>&1; then
    echo "proxy logs saved";
    grep 'get_measurements' <proxy.log >measurements.log
  fi

  if docker logs solana >solana.log 2>&1; then echo "solana logs saved"; fi
  if docker logs evm_loader >evm_loader.log 2>&1; then echo "evm_loader logs saved"; fi
}

function stop_all() {
  pre_compose
  echo "Stopping all containers..."
  docker-compose -f docker-compose.yml down
}

function cleanup_docker() {
  docker system prune -f
}

if [ -z "$1" ]; then
  echo "Specify action:"
  echo "   ./do <ACTION>"
  echo "see predefined actions inside script"
  exit 1
fi

$1 ${@:2}
