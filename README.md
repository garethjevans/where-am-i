# where-am-i

a simple webapp to attempt to determine if its running in docker/kubernetes or something else

## Usage

```console
make build && ./build/where-am-i
```

Should output:

```console
is running in docker false
is running in kubernetes false
```

```console
make linux && docker build -t garethjevans/where-am-i:latest .
DOCKER_CONTENT_TRUST=0 docker run garethjevans/where-am-i:latest
```

```console
is running in docker true
is running in kubernetes false
```
