# CPUMiner-Multi-on-Docker-Ubuntu 
CPU mining on Ubuntu 14 or higher  using Docker


[![Docker]( https://img.shields.io/travis/rust-lang/rust.svg?organization=anecula&repository=cpu-mining-on-docker-ubuntu)](https://hub.docker.com/r/anecula/cpu-mining-on-docker-ubuntu/builds)

## Prerequisite
Before you start mining with Docker, you need to install it:
- [Install Docker] (https://docs.docker.com/engine/installation/)
- [Install Docker Compose] (https://docs.docker.com/compose/install/)

## Sign in a pool

 For this example I create an account on [minergate.com](https://minergate.com/) [feel free to use whatever pool you choose)
 
 
# Start mining in 2 minutes

1. Download the [docker-compose.yml](https://raw.githubusercontent.com/anecula/CPU-mining-on-Docker-Ubuntu/master/docker-compose.yml) file on your host
2. Edit `docker-compose.yml` file by adding your credentials in the following variables:
``` 
      - WALLET_ADDRESS=your wallet address
      - POOL_ADDRESS=mining pool address
 ```
 for example mine are:
 ```
      - WALLET_ADDRESS=andra.gabr@gmail.com
      - POOL_ADDRESS=stratum+tcp://xmr.pool.minergate.com:45560
  ```
  WALLET_ADDRES: should be the mail addres used to signup on minegrate.com
  You can choose your pool addres for  CPUMiner-Multi Miner from here https://minergate.com/altminers/cpuminer-multi-wolf 
  
2. Run command: `docker-compose up -d` 

3. See your container with: `docker ps` 

* make sure that you followed the Prerequisite and installed docker and docker-compose.

If everything worked as expected and you can see your container Healthy/up and running go on Minegrad site and check your Dashboard (https://minergate.com/internal)

## Use in production
By default, CPU-mining-on-Docker-Ubuntu will start one container mining a single crypto currency (XMR/Monero) in one pool (minegrate)

You can configure all the files as you wish:

1. Clone the repo: 
`git clone https://github.com/anecula/CPU-mining-on-Docker-Ubuntu.git`

2 Change working directory to : `CPU-mining-on-Docker-Ubuntu`

Edit desired files:
- Dockerfile
- entrypoint.sh
- docker-compose.yml


