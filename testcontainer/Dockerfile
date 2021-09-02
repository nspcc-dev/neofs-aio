ARG NEOGO_HUB_TAG=latest
ARG AIO_HUB_TAG=latest

FROM nspccdev/neo-go:${NEOGO_HUB_TAG} as neo-go
FROM nspccdev/neofs-aio:${AIO_HUB_TAG} as neofs-all

# Executable image
FROM alpine AS neofs-aio
RUN apk add --no-cache \
  bash \
  ca-certificates \
  jq \
  expect \
  iputils \
  curl

WORKDIR /

COPY --from=neo-go /config /config
COPY --from=neo-go /usr/bin/privnet-entrypoint.sh /usr/bin/privnet-entrypoint.sh
COPY --from=neo-go /usr/bin/neo-go /usr/bin/neo-go
COPY --from=neo-go /etc/ssl/certs /etc/ssl/certs
COPY --from=neofs-all /bin/neofs-ir /bin/neofs-ir
COPY --from=neofs-all /bin/neofs-node /bin/neofs-node
COPY --from=neofs-all /bin/neofs-cli /bin/neofs-cli

COPY ./testcontainer/init-testcontainer.sh /usr/bin/
COPY ./sn/wallet.key /config/wallet-sn.key
COPY ./sn/config.yaml /config/config-sn.yaml
COPY ./ir/wallet.key /config/wallet.key
COPY ./ir/config.yaml /config/config-ir.yaml
COPY ./vendor/locode_db /config/locode.db
COPY ./vendor/morph_chain.gz /config/morph_chain.gz
COPY ./morph/protocol.privnet.yml /config/protocol.privnet.yml
COPY ./morph/node-wallet.json /config/node-wallet.json
COPY ./bin/ /config/bin


ENTRYPOINT ["/usr/bin/init-testcontainer.sh"]
