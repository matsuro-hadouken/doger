# DogeCash run masternode:

_This is alpha release, valid for single node VPS setup._

**Pull images from docker hub:**

```docker
docker pull dogecash/master_x64:alpha
```

**Check which images are available on host:**

```docker
docker images
```
![docker_images](https://user-images.githubusercontent.com/50751381/80302333-eaa9d980-8798-11ea-8644-5aaef52efc48.png)

**Run image persistently:**

```docker
docker run -it -d -p 56740:56740 --name MASTER <IMAGE_ID>
```
![docker_run](https://user-images.githubusercontent.com/50751381/80302533-15e0f880-879a-11ea-8da3-0edd2cdd8b85.png)
**Check if MASTER container is up and running:**

```docker
docker ps
```
![docker ps]https://user-images.githubusercontent.com/50751381/80302655-d070fb00-879a-11ea-9826-ecfa23bdc7c7.png

**Start configuration script, we need to provide masternode private key:**

```bash
docker exec -u 0 -it MASTER dogecash.sh <MASTERNODE PRIVATE KEY HERE>
```

_Script will download full chain, which can take a long time, depends on your internet connection._

**Start masternode:**

```bash
docker exec -u dogecash -it MASTER run.sh
```

**Now we can check debug.log use Ctrl+C to exit, pay attention on ACCEPT messages:**

```bash
docker exec -it MASTER tail -f /home/dogecash/.dogecash/debug.log
```

# Scripts & Tools documentation:

_Most of this tools should be run as root except bootstrap.sh ( -u 0 )_

**dogecash.sh**

Oneliner all in one setup to run masternode and instantly sync with network.

Is mandatory recommendation to use this script and avoid any adition setup manipulations.

It will download full chain snapshot, can take a long time depands on connection speed.
With modern VPS providers should not take longer then a 10 minutes.

_Only work as root:_

```bash
docker exec -u 0 -it MASTER dogecash.sh <MASTERNODE PRIVATE KEY HERE>
```

**config.sh**

_Set up daemon configuration file, check for private masternode key,_
_generate random RPC entries, and add up-to-date peers for fast synchronization._

_Only work as root user:_

```bash
docker exec -u 0 -it MASTR config.sh <MASTERNODE_PRIVATE_KEY>
```

**snapshot.sh**

_Wipe ALL chain storage and download full stapshot to provide up to block synchronisation._
_Can take a long time depands on connection speed._
_With modern VPS providers should not take longer then a 10 minutes._

_bootstrap.dat will be deleted, so use in apropriate order !_

_Only work as root user:_

```bash
docker exec -u 0 -it MASTER snapshot.sh
```

**bootstrap.sh**

_Download bootstrap.dat in to DATA folder._
_script will not wipe anything, so use wipe.sh before to support your needs._

_Use with this command, should not run as root:_

```bash
docker exec -u dogecash -it MASTER bootstrap.sh
```

**wipe.sh**

For advanced users only !

_Will wipe all sort of data, depends on your needs, it can clear addnodes from config,_
_wipe all chain storage, delete wllet.dat, delete bootstrap.dat.old to free some space, wipe daemon config._
_I'm actually planing to wipe corona virus soon, more to come, stay tuna for updates._

```
wipe.sh stop          - stop daemon

wipe.sh data          - remove all chain and database data
wipe.sh wallet        - remove wallet.dat ( be careful! )
wipe.sh bootstrap     - removing bootstrap* if present
wipe.sh addnode       - remove all addnodes entry
wipe.sh config        - remove everything from config, including private node key ( be careful! )
```

```bash
docker exec -u 0 -it MASTER wipe.sh <option1> <option2> <option3> <option4> ...
```

_Example:_

```bash
docker exec -u 0 -it MASTER wipe.sh stop data addnode
```

# Debugging and additional commands:

**Connect to bash in case we need to change something:**

```bash
docker exec -u dogecash -it MASTER bash
```

**Stop and Start container:**

```docker
docker stop --time=45 MASTR
```

_run container ( all data are saved ):_

```docker
docker start <CONTAINER_NAME_OR_ID>
```

**Get container IP address:**

```docker
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' MASTER
```

**Passing commands to container:**

```docker
docker exec -u dogecash -it MASTER dogecash-cli getinfo
                ^^ -u 0 for root
docker exec -u dogecash -it MASTER dogecash-cli getpeerinfo
                                   ^^ everything after container.
```

**Check all containers including offline:**

```docker
docker container ls -a
```

**If we need to run one command for all instances:**

```bash
for i in c1 dm1 dm2 ds1 ds2 gtm_m gtm_sl; do docker exec -u <username> -it $i /bin/bash -c "whatever we need to do"; done
```

**Remove image for people with low HDD space:**

```bash
docker image rm -f <IMAGE NAME OR ID>
```

**Troubleshooting docker activity:**

```docker
sudo journalctl -u docker

sudo journalctl -u docker -f

journalctl -xn -u docker | less
```

**Check logs:**

```docker
docker logs $container_id>
```
