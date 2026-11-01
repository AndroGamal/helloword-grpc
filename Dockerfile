FROM ubuntu:24.04

# تحديث النظام وتثبيت الشهادات وأدوات الـ Git والبناء
RUN apt-get update && apt-get install -y \
    ca-certificates \
    git \
    build-essential \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# الآن سيتم تنزيل Drogn بدون مشاكل التحقق من الشهادة
RUN git clone --depth 1 https://github.com/drogonframework/drogon.git /tmp/drogon \
    && cd /tmp/drogon \
    && git submodule update --init --recursive \
    && cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF \
    && cmake --build build -j2 \
    && cmake --install build \
    && ldconfig \
    && rm -rf /tmp/drogon