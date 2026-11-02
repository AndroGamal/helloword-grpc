# Deploying with SnapDeploy

The project includes a Dockerfile for SnapDeploy's Docker-based deployment.

1. Connect the repository and select the repository root as the build context.
2. Select `Dockerfile` as the build file.
3. Configure the service to use the HTTP port provided by the platform through
   the `PORT` environment variable. The app defaults to port `8080` when `PORT`
   is not set.
4. If the application stores uploaded files, attach persistent storage at
   `/app/uploads`. Container-local files may be removed when a deployment is
   restarted or replaced.

The container listens on `0.0.0.0` and runs as an unprivileged user.
