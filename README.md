# Documentation:

_Our cluster contain MASTER which used as reference and SLAVES  which are connected to MASTER._

_MASTER image include extra packages like 'unzip' and 'curl' for maintenance and adjustments._

__Pull images from docker hub:__
```docker
docker pull dogecash/testnet-master:alpha
docker pull dogecash/testnet-slave:alpha
```
__Check which images are available on our host:__
```sh
docker images
```
__Run image persistently:__
```sh
docker run -it -d --name MASTER <MASTER_IMAGE_ID>
```
__Check if MASTER container is up and running:__
```sh
docker ps
```
__Start *MASTER*:__
```sh
docker exec -u dogecash -it MASTER run.sh
```
__Check log:__
```sh
docker exec -it MASTER tail -f /home/dogecash/.dogecash/debug.log
```
__Connect to bash in case we need to change anything:__
```sh
docker exec -u dogecash -it MASTER bash
```
__Stop container gently:__
```sh
docker stop --time=45 SLAVE
```
__After we sure MASTER is ready, go ahead and run *SLAVE* peer.__

_Instructions are the same, except we need to provide MASTER IP for communication._

```docker
docker run -it -d --name SLAVE <SLAVE_IMAGE_ID>
docker ps
```
__Rheck MASTER container IP address:__
```docker
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' MASTER
```
__Provide *MASTER IP* of *SLAVE*:__
```sh
docker exec -t SLAVE config.sh 172.17.0.2
```

__Run *SLAVE*:__
```docker
docker exec -u dogecash -it SLAVE run.sh
```

## Networking:

__Publish port:__
```sh
docker run -p 127.0.0.1:80:8080/tcp <IMAGE_ID> bash
```
__Expose port:__
```sh
docker run --expose 80 <NAME> bash
```
    
## How to start offline containers after we wake up in the morning:

__Check all containers:__
```sh
docker container ls -a
```
_run container ( all data are saved ), but we need to start daemon as described above_
```sh
docker start <NAME>
```
__If we need to run one command for all instances:__
```sh
for i in c1 dm1 dm2 ds1 ds2 gtm_m gtm_sl; do docker exec -u dogecash -it $i /bin/bash -c "whatever we need to do"; done
```

## Development command:
```sh
docker system prune -af
docker volume prune
docker container prune
```
__Remove and clear:__
```sh
docker image rm -f <IMAGE NAME OR ID>
```
__List all images:__
```sh
docker images -a
```

__Check logs:__
```sh
docker logs $container_id>
```

__Rename give a name:__
```sh
docker tag dogecash:alpha dogecash/dogecash:alpha
```

__Troubleshooting docker activity:__
```sh
sudo journalctl -u docker

sudo journalctl -u docker -f

journalctl -xn -u docker | less
```
## Build containers:
```sh
cd MASTER
sudo docker build -t dogecash/testnet-master:alpha .

cd ../SVALE
sudo docker build -t dogecash/testnet-slave:alpha .
```



__Good explanation about use of the VOLUME in my docker image if someone ask this question, thanks to Mr. Haven__

Generaly good topic to read about this subject: https://stackoverflow.com/a/55052682
