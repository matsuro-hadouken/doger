# TEST NET

_This is DogeCash test net virtual network, not for the public use yet, experimental and in alpha stage._

**Pull images from docker hub:**

```docker
docker pull dogecash/test-master_x64:latest
docker pull dogecash/test-slave_x64latest
```

**Run MASTER persistently:**

```docker
docker run -it -d -p 41001:41001 --name MASTER <IMAGE_ID>
```

_SLAVE run without -p_

1. **Update binaries**

```sh
docker exec -u 0 -it CONTAINER_NAME update.sh
```

2. **Configure**

_For master:_

```bash
docker exec -u 0 -it MASTER dogecash.sh <PRIVATE KEY> <EXTERNAL_IP>
```

_For slave:_

```bash
docker exec -u 0 -it MASTER dogecash.sh <PRIVATE KEY>
```

_For seeder ( SLAVE / MASTER ):_

```sh
docker exec -u 0 -it $CONTAINER_NAME dogecash.sh <seed> 'with ot without external IP'
```

3. **Run**

```sh
docker exec -u dogecash -it $CONTAINER_NAME run.sh
```

# Tools documentation:

**mn.sh**

Shape shift, private key manager. ADD key , CHANGE key , REMOVE key

```sh
docker exec -u 0 -it $CONTAINER_NAME mn.sh
```

**update.sh**

Update binaries inside container.

```bash
docker exec -u 0 -it $CONTAINER_NAME update.sh
```

**dogecash.sh**

Setup configuration as described above.

```bash
docker exec -u 0 -it $CONTAINER_NAME dogecash.sh
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
wipe.sh config        - remove everything from config, including private node key ( be careful! )
```

```bash
docker exec -u 0 -it $CONTAINER_NAME wipe.sh
```

**Build:**

```sh
cd test-master
docker build -t test-master_x64 .

cd ../test-slave
docker build -t test-slave_x64 .
```
