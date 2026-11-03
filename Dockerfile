
# ---------- Build Stage ----------
FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    libprotobuf-dev \
    protobuf-compiler \
    protobuf-compiler-grpc \
    libgrpc-dev \
    libgrpc++-dev \
    libc-ares-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

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
    ca-certificates \
    libgrpc++1.51t64 \
    libprotobuf32t64 \
    libc-ares2 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/build/grpc_hello_server /app/grpc_hello_server

RUN ldconfig \
    && useradd --system --uid 10001 --create-home app \
    && chown -R app:app /app

USER app

WORKDIR /app

EXPOSE 8080

CMD ["/app/grpc_hello_server"]
