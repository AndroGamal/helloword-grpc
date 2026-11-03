
# ---------- Build Stage ----------
FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    libprotobuf-dev \
    protobuf-compiler-grpc \
    libgrpc++-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY CMakeLists.txt GRPC_Server.cc grpc_client.cc ./
COPY proto/ ./proto/

RUN cmake -S . -B build \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_DROGON_APP=OFF \
    && cmake --build build --target grpc_hello_server -j2

# ---------- Runtime Stage ----------
FROM ubuntu:24.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive
ENV PORT=8080

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgrpc++1.51t64 \
    libprotobuf32t64 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/build/grpc_hello_server /app/grpc_hello_server

RUN set -eu; \
    ldconfig; \
    ldd /app/grpc_hello_server | tee /tmp/grpc-hello-ldd.txt; \
    if grep -Fq "not found" /tmp/grpc-hello-ldd.txt; then \
        echo "Missing runtime shared library" >&2; \
        exit 1; \
    fi; \
    rm /tmp/grpc-hello-ldd.txt; \
    useradd --system --uid 10001 --create-home app

USER app

WORKDIR /app

EXPOSE 8080

CMD ["/app/grpc_hello_server"]
