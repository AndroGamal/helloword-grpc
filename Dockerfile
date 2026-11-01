FROM ubuntu:24.04

# تثبيت الشهادات وأدوات البناء والمكتبات المطلوبة لـ Drogon
RUN apt-get update && apt-get install -y \
    ca-certificates \
    git \
    build-essential \
    cmake \
    libjsoncpp-dev \
    uuid-dev \
    zlib1g-dev \
    openssl \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# بناء وتثبيت إطار Drogon
RUN git clone --depth 1 https://github.com/drogonframework/drogon.git /tmp/drogon \
    && cd /tmp/drogon \
    && git submodule update --init --recursive \
    && cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF \
    && cmake --build build -j2 \
    && cmake --install build \
    && ldconfig \
    && rm -rf /tmp/drogon