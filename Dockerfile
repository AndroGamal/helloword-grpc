
# ---------- Build Stage ----------
FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

    RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    libjsoncpp-dev \
    uuid-dev \
    zlib1g-dev \
    libssl-dev \
    libpq-dev \
    libprotobuf-dev \
    protobuf-compiler \
    protobuf-compiler-grpc \
    libgrpc-dev \
    libgrpc++-dev \
    libc-ares-dev \
    && rm -rf /var/lib/apt/lists/*

# Build Drogon
RUN git clone --depth 1 --recurse-submodules \
    https://github.com/drogonframework/drogon.git /tmp/drogon \
    && cmake -S /tmp/drogon -B /tmp/drogon/build \
       -G Ninja \
       -DCMAKE_BUILD_TYPE=Release \
       -DBUILD_TESTING=OFF \
    && cmake --build /tmp/drogon/build -j2 \
    && cmake --install /tmp/drogon/build \
    && ldconfig \
    && rm -rf /tmp/drogon

# Copy your C++ project
WORKDIR /app
COPY . .

# Build your application
RUN cmake -S . -B build \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build -j2

# ---------- Runtime Stage ----------
FROM ubuntu:24.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive
ENV PORT=8080

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libjsoncpp25 \
    uuid-runtime \
    zlib1g \
    libssl3 \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/ /usr/local/lib/
COPY --from=builder /usr/local/include/ /usr/local/include/
COPY --from=builder /app/build/ /app/build/

RUN ldconfig

WORKDIR /app

EXPOSE 8080

CMD ["/app/build/super_ads_api"]
