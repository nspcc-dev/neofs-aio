# NeoFS All-in-One

Single node deployment helper provides instructions on how to deploy all NeoFS
components in the on-premise setup on one physical or virtual server. There will
be just one instance of a service of each type, hence it is suitable for
development purposes only and not recommended for production use.

# Server requirements

- Docker with docker-compose
- `expect` 
- `jq`
- `curl`

# Quick Start

For Linux machines:
``` sh
$ git clone https://github.com/nspcc-dev/neofs-aio.git /opt/neofs
$ cd /opt/neofs
$ docker-compose up -d
```

All the services will be listening on `localhost` interface by default.

For Windows and macOS use `docker-compose.cross.yml` without `host` network mode.
``` sh
$ git clone https://github.com/nspcc-dev/neofs-aio.git /opt/neofs
$ cd /opt/neofs
$ docker-compose -f docker-compose.cross.yml up -d
```

On the first start you have to run (this command will allow you to create containers):
``` sh
$ make prepare.ir
Changing ContainerFee configration value to 0
Enter account NfgHwwTi3wHAS8aFAN243C5vGbkYDpqLHP password > 
Sent invocation transaction b50c3035b851db06eb070fadb88c4cd55d56436c01a92c0ba7f3197c9ec3b1fe
Updating NeoFS epoch to 2
Enter account NfgHwwTi3wHAS8aFAN243C5vGbkYDpqLHP password > 
Sent invocation transaction 2a8d0536559f242f5b64bb1b29d4b1f4c7a225ab184a26414b93da18d265f1f4
```

A storage node container uses persistent storage, so, if you've updated `aio` version, it's recommended to clear local 
volumes before starting the container:  
```
docker volume rm neofs-aio_data
docker volume rm neofs-aio_cache
```

Also, you may have to make sure the storage node is in the network
map.

``` sh
$ docker exec -ti sn neofs-cli netmap snapshot -c /config/cli-cfg.yaml --rpc-endpoint 127.0.0.1:8080
Epoch: 45
Node 1: 022bb4041c50d607ff871dec7e4cd7778388e0ea6849d84ccbd9aa8f32e16a8131 ONLINE /dns4/localhost/tcp/8080
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
If the commands fails, make sure you have jq and expect installed.

``` sh
$ docker-compose restart sn
Restarting sn ... done
$ make tick.epoch
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

# Build images

In order to build test container image that can be used for instead of mocks run:
``` sh
$ make image-testcontainer
```
Also, you can build the aio image itself:
``` sh
$ make image-aio
```

# Simple WebApp

## Create a container

First, you need to create a container to store your object. Because there is
only one storage node in the All-in-One setup, you can only have one replica of
your data. Let's create a container using `neofs-cli`. Container creation
requires on-chain operations, so it may take up to 5-10 seconds to complete.
Here we use the pre-generated key of the HTTP Gateway for simplicity.

Password for wallet is `one`.

``` sh
$ neofs-cli -r localhost:8080 -w http/wallet.json \
            --address NPFCqWHfi9ixCJRu7DABRbVfXRbkSEr9Vo \
            container create \
            --policy "REP 1" --basic-acl public-read --await
container ID: GfWw35kHds7gKWmSvW7Zi4U39K7NMLK8EfXBQ5FPJA46
awaiting...
container has been persisted on sidechain
```

## Get container

```sh
$ curl http://localhost:8090/v1/containers/GfWw35kHds7gKWmSvW7Zi4U39K7NMLK8EfXBQ5FPJA46 | jq
{
  "attributes": [
    {
      "key": "Timestamp",
      "value": "1661861767"
    }
  ],
  "basicAcl": "1fbf8cff",
  "cannedAcl": "public-read",
  "containerId": "iafCKZmWu1mahdxxcA6HRYdB5S9BrypYF1qNqpQezpA",
  "containerName": "",
  "ownerId": "NPFCqWHfi9ixCJRu7DABRbVfXRbkSEr9Vo",
  "placementPolicy": "REP 1",
  "version": "v2.13"
}
```

## Put an object with neofs-cli

``` sh
$ neofs-cli -r localhost:8080 -w http/wallet.json \
            --address NPFCqWHfi9ixCJRu7DABRbVfXRbkSEr9Vo \
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
