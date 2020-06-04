**_Manual Deployment documentation._**

_Requirements:_

* Debian or Ubuntu x64 host
* Docker installed
* Port 56740 should be open and available from outside

Expand terminal window for better redability.

**_Run master image persistently:_**

```docker
$ docker run -it -d -p 56740:56740 --name MASTER dogecash/main-master_x64
```

Start configuration script, we need to provide masternode private key and external IP address:

```bash
$ docker exec -u 0 -it MASTER dogecash.sh 'MASTERNODE PRIV KEY' 'EXTERNAL IP'
```

_Script download full chain snapshot, that can take a long time, depending on your internet connection, for modern VPS host it should not take more than 1 minute or 2._

**_Start masternode:_**

```bash
$ docker exec -u dogecash -it MASTER run.sh
```

Wait for the MN to fully sync with the chain ...

**_Start node from wallet, done._**

_There comes a time when you have to choose between turning the page or just closing the book._

**_Run more nodes:_** ( _setting up private network_ )

_All steps are the same as we did with master container, except no need to provide external IP and we won't open port to outside._

_Names can be absolutely your choice, like DOGE is the MASTER and CASH is a SLAVE, up to you. For sake of simplicity we going to use SLAVE name as example._

**_Run container:_**

```bash
$ docker run -it -d --name SLAVE dogecash/main-slave_x64
```

**_Start configuration:_**

```bash
docker exec -u 0 -it SLAVE dogecash.sh 'MASTERNODE PRIV KEY'
```

_If you fail at some step or want to learn more by trying different utilities included in the package, here is the way to start from scratch, these commands remove ALL containers and images data and bring docker to virgin state as if it was just installed._

notice: _you should stop container before removing it's data, otherwise only offline containers data will be removed._

```
docker stop MASTER      - stop container by NAME ( MASTER in this example )

docker system prune -a  - clear up all docker system
docker volume prune     - remove all created volumes
docker container prune  - remove all containers
```

**_Tools documentation:_**

_Most of this tools should be run as root except bootstrap.sh ( -u 0 )_

_dogecash.sh_

One liner all in one setup to run masternode and instantly sync with network.

It's a mandatory recommendation to use this script and avoid any additional setup manipulations.

It will download full chain snapshot, it can take long time and it depends on connection speed. With modern VPS providers should not take longer than about 1 minute or 2.

_Only works as root:_

```bash
docker exec -u 0 -it MASTER dogecash.sh <MASTERNODE PRIVATE KEY HERE>
```

_snapshot.sh_

_Wipe ALL chain storage and download full stapshot to provide up to block synchronisation. Can take a long time, it depends on connection speed. With modern VPS providers should not take longer than 1 minute or 2._

_bootstrap.dat will be deleted, so use in appropriate order !_

_Only works as root user:_

```bash
docker exec -u 0 -it MASTER snapshot.sh
```

_bootstrap.sh_

_Download bootstrap.dat into the DATA folder. Script will not wipe anything, so use wipe.sh before to support your needs._

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

_If you wipe config this will make node non-functional, so run dogecash.sh to recreate ( recommended )._

This will only work as container root user:'

```bash
docker exec -u 0 -it MASTER wipe.sh <option1> <option2> <option3> <option4> ...
```

_Example:_

```bash
docker exec -u 0 -it MASTER wipe.sh stop data addnode
```

**Debugging and additional commands:**

Check ALL containers include offline:

```docker
docker container ls -a
```

Connect to bash in case we need to change something as dogecash user:

```bash
docker exec -u dogecash -it <CONTAINER_NAME> bash
```

Stop and Start container:

_( all data are always saved ):_

```docker
docker stop --time=45 <CONTAINER_NAME>

docker start <CONTAINER_NAME>
```

Get container IP address:

```docker
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <CONTAINER_NAME>
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
