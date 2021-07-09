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

# Simple WebApp

## Create a container

First, you need to create a container to store your object. Because there is
only one storage node in the All-in-One setup, you can only have one replica of
your data. Let's create a container using `neofs-cli`. Container creation
requires on-chain operations, so it may take up to 5-10 seconds to complete.
Here we use the pre-generated key of the HTTP Gateway for simplicity.

``` sh
$ neofs-cli -r localhost:8080 -w http/node-wallet.json \
            --address NPFCqWHfi9ixCJRu7DABRbVfXRbkSEr9Vo \
            container create \
            --policy "REP 1" --basic-acl public-read --await
container ID: GfWw35kHds7gKWmSvW7Zi4U39K7NMLK8EfXBQ5FPJA46
awaiting...
container has been persisted on sidechain
```

## Put an object with neofs-cli

``` sh
$ neofs-cli -r localhost:8080 -w http/node-wallet.json \
            --address NPFCqWHfi9ixCJRu7DABRbVfXRbkSEr9Vo
            object put \
            --cid GfWw35kHds7gKWmSvW7Zi4U39K7NMLK8EfXBQ5FPJA46 \
            --file cat.jpg
[cat.jpg] Object successfully stored
  ID: BYwj7QRxubaLSsXxKU2nbBu3ugcyjv1SsAT4zxPXvosB
  CID: GfWw35kHds7gKWmSvW7Zi4U39K7NMLK8EfXBQ5FPJA46
```

## Put an object via http

``` sh
$ curl -F 'file=@cat.jpg;filename=cat.jpg' \
       http://localhost:8081/upload/ADsJLhJhLQRGMufFin56PCTtPK1BiSxbg6bDmdgSB1Mo
{
    "object_id": "B4J4L61X6zFcz5fcmZaCJJNZfFFTE6uT4pz7dqP87m6m",
    "container_id": "ADsJLhJhLQRGMufFin56PCTtPK1BiSxbg6bDmdgSB1Mo"
}
```

The full description of HTTP API supported by HTTP Gateway can be found in
[neofs-http-gw repository](https://github.com/nspcc-dev/neofs-http-gw).

## Get an object via nginx

``` sh
$ curl --head http://localhost:8082/ADsJLhJhLQRGMufFin56PCTtPK1BiSxbg6bDmdgSB1Mo/cat.jpg
HTTP/1.1 200 OK
Server: nginx/1.20.1
Date: Wed, 07 Jul 2021 17:10:32 GMT
Content-Type: image/jpeg
Content-Length: 187342
Connection: keep-alive
X-Attribute-FileName: cat.jpg
x-object-id: B4J4L61X6zFcz5fcmZaCJJNZfFFTE6uT4pz7dqP87m6m
x-owner-id: NPFCqWHfi9ixCJRu7DABRbVfXRbkSEr9Vo
x-container-id: ADsJLhJhLQRGMufFin56PCTtPK1BiSxbg6bDmdgSB1Mo
Content-Disposition: inline; filename=cat.jpg
```

Having nginx as a reverse proxy behind NeoFS HTTP Gateway allows you to tune the
behaviour according to your application needs. For example, you can set the
rewriting rules to use the pre-configured container for a specific domain to
simplify the URL. Together with `FilePath` attribute in objects it would give
the sense of a regular static web hosting.

For example:
``` nginx
    location / {
      set $cid ADsJLhJhLQRGMufFin56PCTtPK1BiSxbg6bDmdgSB1Mo;

      rewrite '^(/[0-9a-zA-Z\-]{43,44})$' /get/$cid/$1 break;
      rewrite '^/$'                       /get_by_attribute/$cid/FileName/index.html break;
      rewrite '^/([^/]*)$'                /get_by_attribute/$cid/FileName/$1 break;
      rewrite '^(/.*)$'                   /get_by_attribute/$cid/FilePath/$1 break;

      proxy_pass http://localhost:8081;
```

This allow us to upload objects with `FilePath` attached and get them as if they
were put in a directory structure of the regular web server.

``` sh
 curl -F 'file=@cat.jpg;filename=cat.jpg' -H "X-Attribute-FilePath: /pic/cat.jpg" http://localhost:8081/upload/ADsJLhJhLQRGMufFin56PCTtPK1BiSxbg6bDmdgSB1Mo 
{
	"object_id": "4s3T11pktSfSxRfjpJ7BsiuYr2hi7po6nUQ333SPYkWF",
	"container_id": "ADsJLhJhLQRGMufFin56PCTtPK1BiSxbg6bDmdgSB1Mo"
}
```

Now you can get the `cat.jpg` in a traditional way, using your custom server name.

``` sh
$ curl --head http://mysite.neofs:8082/pic/cat.jpg
HTTP/1.1 200 OK
Server: nginx/1.20.1
Date: Fri, 09 Jul 2021 08:14:23 GMT
Content-Type: image/jpeg
Content-Length: 187342
Connection: keep-alive
X-Attribute-FilePath: /pic/cat.jpg
X-Attribute-FileName: cat.jpg
x-object-id: 4s3T11pktSfSxRfjpJ7BsiuYr2hi7po6nUQ333SPYkWF
x-owner-id: NPFCqWHfi9ixCJRu7DABRbVfXRbkSEr9Vo
x-container-id: ADsJLhJhLQRGMufFin56PCTtPK1BiSxbg6bDmdgSB1Mo
Content-Disposition: inline; filename=cat.jpg
```
