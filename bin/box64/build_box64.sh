#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BOX64_SOURCE="$SCRIPT_DIR/source"
BUILD_DIR="$SCRIPT_DIR/build_ios"
OUTPUT_LIB="$SCRIPT_DIR/lib/libbox64.dylib"

echo "--- Box64 iOS Cross-Compilation Başlatılıyor ---"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# CMake yapılandırması
cmake "$BOX64_SOURCE" \
    -DCMAKE_TOOLCHAIN_FILE="$SCRIPT_DIR/ios.toolchain.cmake" \
    -DARM64=1 \
    -DIOS=1 \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=Release

echo "--- Derleme Başlıyor (make) ---"
make -j$(nproc)

echo "✅ Box64 iOS Derleme Tamamlandı."
