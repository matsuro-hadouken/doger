# DogeCash run masternode:

**Alpha documentation !**

Pull MASTER image first from the hub:

```docker
docker pull dogecash/main-master_x64
```

Check which images are available on the host:

```docker
docker images
```

![docker_images](https://user-images.githubusercontent.com/50751381/80302333-eaa9d980-8798-11ea-8644-5aaef52efc48.png)

_Run image persistently ( port 56740 will be open for incoming connections ):_

```docker
docker run -it -d -p 56740:56740 --name MASTER <IMAGE_ID>
```

![docker_run](https://user-images.githubusercontent.com/50751381/80302533-15e0f880-879a-11ea-8da3-0edd2cdd8b85.png)

_Check if MASTER container is up and running:_

```docker
docker ps
```

![docker ps](https://user-images.githubusercontent.com/50751381/80302655-d070fb00-879a-11ea-9826-ecfa23bdc7c7.png)

Start configuration script, we need to provide a masternode private key and external IP address:

_As VPS owner your should know your IP address, in case not use `curl ifconfig.me` or `curl ident.me`_

```bash
docker exec -u 0 -it MASTER dogecash.sh 'MASTERNODE PRIV KEY' 'EXTERNAL IP'
```

![dogecash.sh](https://user-images.githubusercontent.com/50751381/80302833-fe0a7400-879b-11ea-9ca4-6f3deb82d55f.png)

_Script starts download of the full chain snapshot, that can take a long time, depending on your internet connection, for modern VPS host it should not take more than 1 minute or 2._

**Start masternode:**

```bash
docker exec -u dogecash -it MASTER run.sh
```

Now we can check the log in real time, use Ctrl+C to exit:

```bash
docker exec -it MASTER tail -f /home/dogecash/.dogecash/debug.log
```

**Here we should wait for the MN to fully sync with the chain**

By the time you are done reading this it should be already synched, to double check we ask the daemon about his current block, by passing _getblockcount_ command:

```bash
docker exec -u dogecash -it MASTER dogecash-cli getblockcount
```

Then check last block on explorer https://explorer.dogec.io/status and compare. Usually, daemon should be in atomic sync or around 1 or 2 blocks behind which is acceptable latency in most cases.

**There comes a time when you have to choose between turning the page or just closing the book.**

If you want to run another node, we need to pull SLAVE image from the hub.

```docker
docker pull dogecash/main-slave_x64
```

_All steps are the same as we did with master container, except no need to provide external IP and we won't open port to outside._

_Names can be absolutely your choice, like DOGE is the MASTER and COIN is a SLAVE, up to you. We going to use SLAVE as example._

Check available containers:

```bash
docker images
```

```bash
docker run -it -d --name SLAVE <IMAGE_ID>
```

Complete full configuration setup:

```bash
docker exec -u 0 -it SLAVE dogecash.sh 'MASTERNODE PRIV KEY'
```

_If you fail at some step or want to learn more by trying different utilities included in the package, here is the way to start from scratch, these commands remove ALL containers and images data and bring docker to virgin state as if it was just installed._

```
docker stop MASTER      - stop container by NAME ( MASTER in this example )

docker system prune -a  - clear up all docker system
docker volume prune     - remove all created volumes
docker container prune  - remove all containers
```

_notice: you should stop container before removing it's data, otherwise only offline containers data will be removed._

# Tools documentation:

_Most of this tools should be run as root except bootstrap.sh ( -u 0 )_

_dogecash.sh_

One liner all in one setup to run masternode and instantly sync with network.

It's a mandatory recommendation to use this script and avoid any additional setup manipulations.

It will download full chain snapshot, it can take long time and it depends on connection speed.
With modern VPS providers should not take longer than about 8 minutes.

_Only works as root:_

```bash
docker exec -u 0 -it MASTER dogecash.sh <MASTERNODE PRIVATE KEY HERE>
```

_config.sh_

_Set up daemon configuration file, check for private masternode key,_
_generate random RPC entries, and add up-to-date peers for fast synchronization._

_Only works as root user:_

```bash
docker exec -u 0 -it MASTR config.sh <MASTERNODE_PRIVATE_KEY>
```

_snapshot.sh_

_Wipe ALL chain storage and download full stapshot to provide up to block synchronisation._
_Can take a long time, it depends on connection speed._
_With modern VPS providers should not take longer than about 8 minutes._

_bootstrap.dat will be deleted, so use in appropriate order !_

_Only works as root user:_

```bash
docker exec -u 0 -it MASTER snapshot.sh
```

_bootstrap.sh_

_Download bootstrap.dat into the DATA folder._
_script will not wipe anything, so use wipe.sh before to support your needs._

_Use with this command, should not run as root:_

```bash
docker exec -u dogecash -it MASTER bootstrap.sh
```

_wipe.sh_

For advanced users only !

_Script will wipe all sort of things, depends on your needs, it can clear addnodes from config, wipe all chain data, delete wllet.dat, delete bootstrap.dat.old or bootstrap.dat to free space above 200M, wipe daemon config to initial stage._

available commands:

wipe.sh stop - _stop daemon_

wipe.sh data - _remove all chain and database data_

wipe.sh wallet - _remove wallet.dat ( becareful )_

wipe.sh bootstrap - _removing bootstrap if present ( make container more then 200M lighter )_

wipe.sh addnode - _remove all addnodes entry_

wipe.sh config - _remove everything from config, including private node key ( becareful )_

_If you wipe config this will make node non-functional, so run config.sh to recreate or use dogecash.sh ( recommended )._

This will only work as container root user:'

```bash
docker exec -u 0 -it MASTER wipe.sh <option1> <option2> <option3> <option4> ...
```

_Example:_

```bash
docker exec -u 0 -it MASTER wipe.sh stop data addnode
```

**Debugging and additional commands:**

Check ALL containers including offline:

```docker
docker container ls -a
```

Connect to bash in case we need to change something as dogecash user:

```bash
docker exec -u dogecash -it MASTER bash
```

Stop and Start container:

_( all data are always saved ):_

```docker
docker stop --time=45 $CONTAINER_NAME

docker start $CONTAINER_NAME
```

Get container IP address:

```docker
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' MASTER
```

Passing commands to container:

```docker
docker exec -u dogecash -it MASTER dogecash-cli getinfo
                ^^ -u 0 for root !
docker exec -u dogecash -it MASTER dogecash-cli getpeerinfo
                                   ^^ everything after container name is the command.
```

If we need to run one command for all instances:

```bash
for i in c1 dm1 dm2 ds1 ds2 gtm_m gtm_sl; do docker exec -u <username> -it $i /bin/bash -c "whatever we need to do"; done
```

Remove image for people with low HDD space:

```bash
docker image rm -f <IMAGE NAME OR ID>
```

Troubleshooting docker activity:

```docker
sudo journalctl -u docker

sudo journalctl -u docker -f

journalctl -xn -u docker | less
```

Check logs:

```docker
docker logs $container_id>
```
