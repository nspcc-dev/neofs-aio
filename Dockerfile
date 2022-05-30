ARG HUB_IMAGE=nspccdev/neofs
ARG HUB_TAG=latest

FROM ${HUB_IMAGE}-cli:${HUB_TAG} as neofs-cli
FROM ${HUB_IMAGE}-ir:${HUB_TAG} as neofs-ir
FROM ${HUB_IMAGE}-storage:${HUB_TAG} as neofs-storage

# Executable image
FROM alpine AS neofs-aio
RUN apk add --no-cache \
  bash \
  ca-certificates \
  jq \
  expect \
  iputils

WORKDIR /

COPY --from=neofs-cli /bin/neofs-cli /bin/neofs-cli
COPY --from=neofs-ir /bin/neofs-ir /bin/neofs-ir
COPY --from=neofs-storage /bin/neofs-node /bin/neofs-node

CMD ["neofs-cli"]
