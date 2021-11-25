#!/bin/bash

function build_containers() {
  docker-compose -f docker-compose.yml build
}

function build_evm() {
  cd ./neon-evm
  export NEON_REVISION=$(git rev-parse HEAD)
  cd ../
  docker-compose -f docker-compose.yml run builder
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

function save_proxy_logs() {
  if docker logs proxy >proxy.log 2>&1; then
    echo "proxy logs saved";
    grep 'get_measurements' <proxy.log >measurements.log
  fi
}

function save_solana_logs() {
  if docker logs solana >solana.log 2>&1; then echo "solana logs saved"; fi
}

function save_evm_loader_logs() {
  if docker logs evm_loader >evm_loader.log 2>&1; then echo "evm_loader logs saved"; fi
}

function save_logs() {
  SERVICE_NAME="$1"
  if [ -z "$SERVICE_NAME" ]; then
    save_proxy_logs
    save_solana_logs
    save_evm_loader_logs
    exit 0
  fi
  save_${SERVICE_NAME}_logs
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
