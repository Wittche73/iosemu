#!/bin/bash
set -e

BOX64_SOURCE="bin/box64/source"
BUILD_DIR="bin/box64/build_ios"
OUTPUT_LIB="bin/box64/lib/libbox64.a"

echo "--- Box64 iOS Cross-Compilation Başlatılıyor ---"

mkdir -p $BUILD_DIR
cd $BUILD_DIR

# CMake yapılandırması
cmake ../source \
    -DCMAKE_TOOLCHAIN_FILE=../ios.toolchain.cmake \
    -DARM64=1 \
    -DIOS=1 \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_BUILD_TYPE=Release

echo "--- Derleme Başlıyor (make) ---"
# make -j$(nproc)

echo "✅ Box64 iOS Derleme Senaryosu Hazır."
echo "Not: Fiziksel SDK eksikliği nedeniyle 'make' adımı manuel veya Theos üzerinden tetiklenmelidir."
