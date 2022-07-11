#!/bin/bash

if [ ! -z ${WALLET_ADDRESS} ] &&  [ ! -z ${POOL_ADDRESS} ] ; then 
echo "Start mining"
	minerd -a cryptonight -o $POOL_ADDRESS -u $WALLET_ADDRESS -p x -t 3
else echo "${WALLET_ADDRESS} and ${POOL_ADDRESS}";
fi
