FROM golang:1-alpine as builder

RUN apk --no-cache --no-progress add git ca-certificates tzdata make \
    && update-ca-certificates \
    && rm -rf /var/cache/apk/*

WORKDIR /go/whotools

# Download go modules
COPY go.mod .
COPY go.sum .
RUN GO111MODULE=on GOPROXY=https://proxy.golang.org go mod download

COPY . .

RUN make build

###

FROM alpine:3.15

RUN     apk update \
    &&  apk add bash bind-tools busybox-extras curl \
                iproute2 iputils jq mtr \
                net-tools openssl \
                perl-net-telnet procps tcpdump tcptraceroute wget \
    &&  mkdir /certs /docker \
    &&  chmod 700 /certs \
    &&  openssl req \
        -x509 -newkey rsa:2048 -nodes -days 3650 \
        -keyout /certs/server.key -out /certs/server.crt -subj '/CN=localhost'

COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /go/whotools/whotools .

ENTRYPOINT ["/whotools"]
EXPOSE 80