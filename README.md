# NeoFS All-in-One

Single node deployment helper provides instructions on how to deploy all NeoFS
components in the on-premise setup on one physical or virtual server. There will
be just one instance of a service of each type, hence it is suitable for
development purposes only and not recommended for production use.

# Server requirements

- Docker with docker-compose

# Quick Start

``` sh
$ git clone https://github.com/nspcc-dev/neofs-aio.git /opt/neofs
$ cd /opt/neofs
$ docker-compose up -d
```

All the services will be listening on `localhost` interface by default.
On the first start you may have to make sure the storage node is in the network
map.

``` sh
$ docker exec -ti sn neofs-cli  control netmap-snapshot --binary-key /config/wallet.key -r 127.0.0.1:16513
Epoch: 3
Node 1: eQEUoc2DRn4oNnNUxs8iviWJYrYS4mTBsgQqjJ44aFyJ ONLINE [/dns4/localhost/tcp/8080]
    Capacity: 0
    Continent: Europe
    Country: Germany
    CountryCode: DE
    Deployed: Private
    Location: Falkenstein
    Price: 10
    SubDiv: Sachsen
    SubDivCode: SN
    UN-LOCODE: DE FKS

```

If you don't see the output like this, you can wait for the new Epoch to come
(about 1 hour), or force the Storage Node registration.

``` sh
$ docker-compose restart sn
Restarting sn ... done
$ cd bin && ./tick.sh
Updating NeoFS epoch to 4
Enter account NfgHwwTi3wHAS8aFAN243C5vGbkYDpqLHP password >
Sent invocation transaction 89959b243e88184ab8b886ee6b53e13032195197ef45144abff1c64b2b5ea342
```

Now everything is ready to server your requests.

# Systemd unit setup

You may find useful to put your NeoFS Deployment under Systemd management and
treat it as a normal system service. The sample unit file is in `systemd`
directory.

``` sh
$ sudo cp systemd/neofs-aio.service /etc/systemd/system/
$ sudo systemctl daemon-reload
$ sudo systemctl status neofs-aio
```






