# Deploying the gRPC server with SnapDeploy

The Dockerfile builds and runs only the gRPC server.

1. Connect the repository and select the repository root as the build context.
2. Select `Dockerfile` as the build file.
3. Configure the service to use the port provided by the platform through the
   `PORT` environment variable. The gRPC server defaults to port `8080` when
   `PORT` is not set.
4. Ensure the platform's ingress supports gRPC over HTTP/2 and forwards TCP
   traffic to the configured container port.

The server listens on `0.0.0.0` and runs as an unprivileged user. The Drogon
HTTP application is not built into or started by this deployment image.
