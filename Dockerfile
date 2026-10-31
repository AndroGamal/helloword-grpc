
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    pkg-config \
    libjsoncpp-dev \
    uuid-dev \
    zlib1g-dev \
    libssl-dev \
    libbrotli-dev \
    libc-ares-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 \
    https://github.com/drogonframework/drogon.git /tmp/drogon \
    && cd /tmp/drogon \
    && git submodule update --init --recursive \
    && cmake -S . -B build \
       -DCMAKE_BUILD_TYPE=Release \
       -DBUILD_TESTING=OFF \
    && cmake --build build -j2 \
    && cmake --install build \
    && ldconfig \
    && rm -rf /tmp/drogon

WORKDIR /app

COPY . .

RUN cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release

RUN cmake --build build -j2

CMD ["./build/super_ads_api"]
