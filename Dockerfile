FROM --platform=${BUILDPLATFORM} alpine:3.13.2

ARG TARGETOS
ARG TARGETARCH
ARG TARGETPLATFORM

LABEL maintainer="Gareth Evans <gareth@bryncynfelin.co.uk>"
COPY build/linux/where-am-i /usr/bin/where-am-i

ENTRYPOINT [ "/usr/bin/where-am-i" ]
