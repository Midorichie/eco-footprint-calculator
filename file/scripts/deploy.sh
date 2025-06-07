#!/usr/bin/env bash
# deploy to mocknet or testnet
environment=${1:-mocknet}
clarinet deploy --network "$environment"
