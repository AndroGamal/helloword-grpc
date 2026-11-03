# Deploying the C++ gRPC server

The Dockerfile builds only `grpc_hello_server`. The Drogon HTTP app is optional
and is disabled for this image.

## Build and inspect the image

From the repository root:

```sh
docker build -t hello-grpc .
```

The image build runs `ldd` against the server and fails if a shared library is
missing. The runtime packages are resolved from Ubuntu 24.04 repositories;
their dependencies provide the remaining gRPC, Protobuf, and system libraries.

## Verify the server locally

The server reads `PORT` (default `8080`), binds to `0.0.0.0`, enables the
standard gRPC health service, and handles `SIGTERM`/`SIGINT` by gracefully
shutting down.

In another terminal, call `SayHello` inside the container:

```sh
docker run -d --name hello-grpc -p 8080:8080 hello-grpc
cd client
python -m pip install grpcio protobuf grpcio-health-checking
python -c "import grpc, hello_pb2, hello_pb2_grpc; c=grpc.insecure_channel('127.0.0.1:8080'); print(hello_pb2_grpc.GreeterStub(c).SayHello(hello_pb2.HelloRequest(name='World'), timeout=5).message); c.close()"
python -c "import grpc; from grpc_health.v1 import health_pb2, health_pb2_grpc; c=grpc.insecure_channel('127.0.0.1:8080'); r=health_pb2_grpc.HealthStub(c).Check(health_pb2.HealthCheckRequest(service=''), timeout=5); print('health status:', health_pb2.HealthCheckResponse.ServingStatus.Name(r.status)); c.close()"
docker stop hello-grpc
docker rm hello-grpc
```

Expected output includes `Hello World!` and `health status: SERVING`. The
`docker stop` command sends `SIGTERM`; the container logs should show the server
stopping.

## Configure a public deployment

Configure the platform to:

1. Build from the repository root using this `Dockerfile`.
2. Route to the container port supplied in `PORT` (the default is `8080`).
3. Terminate public TLS at the platform gateway and forward HTTP/2 gRPC traffic
   to the server. TLS is intentionally not enabled inside this application.

Docker/image support and HTTPS alone do not prove that a platform supports
native gRPC. Its public gateway must accept HTTP/2 `POST` requests with an
`application/grpc` content type, preserve gRPC trailers, and forward HTTP/2 to
the container (or explicitly support h2c upstreams). Confirm these requirements
with the hosting provider. If the gateway only proxies ordinary HTTP, this
server cannot be reached through it as native gRPC; adding Envoy inside the
container does not fix a gateway that rejects HTTP/2 gRPC before forwarding.

The current public client target is configurable with `GRPC_SERVER_ADDRESS`:

```sh
GRPC_SERVER_ADDRESS=your-service.example:443 python client/client.py
```

Use the public hostname and TLS port, without an `https://` prefix. The Python
client enforces connection and RPC timeouts and prints the gRPC status, details,
and debug string on failure.

## Build the gRPC target without Drogon

```sh
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_DROGON_APP=OFF
cmake --build build --target grpc_hello_server -j2
```
