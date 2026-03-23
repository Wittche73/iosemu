set(CMAKE_SYSTEM_NAME iOS)
set(CMAKE_SYSTEM_PROCESSOR arm64)

# SDK Path (Default to Theos locally, or detect on macOS)
if(NOT DEFINED IOS_SDK_PATH)
    if(APPLE)
        execute_process(COMMAND xcrun --sdk iphoneos --show-sdk-path
                        OUTPUT_VARIABLE IOS_SDK_PATH
                        OUTPUT_STRIP_TRAILING_WHITESPACE)
    else()
        set(IOS_SDK_PATH "/home/f-rat/theos/sdks/iPhoneOS.sdk")
    endif()
endif()

message(STATUS "Using iOS SDK: ${IOS_SDK_PATH}")

set(CMAKE_OSX_SYSROOT ${IOS_SDK_PATH})
set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)

# Compilation flags for iOS arm64
set(TARGET_TRIPLE arm64-apple-ios16.0)
set(COMMON_FLAGS "-target ${TARGET_TRIPLE} -arch arm64 -isysroot ${IOS_SDK_PATH} -D_XOPEN_SOURCE=600 -D_DARWIN_C_SOURCE -Wno-macro-redefined")
set(CMAKE_C_FLAGS "${COMMON_FLAGS}")
set(CMAKE_CXX_FLAGS "${COMMON_FLAGS}")
set(CMAKE_ASM_FLAGS "-target ${TARGET_TRIPLE} -arch arm64 -isysroot ${IOS_SDK_PATH}")

# Linker flags (Custom ld64.lld only on Linux, system linker on macOS)
set(LINKFLAGS "-Wl,-platform_version,ios,16.0.0,16.0.0 -Wl,-arch,arm64 -target ${TARGET_TRIPLE} -arch arm64 -isysroot ${IOS_SDK_PATH}")
if(NOT APPLE)
    set(LINKFLAGS "${LINKFLAGS} -fuse-ld=/home/f-rat/Masaüstü/projemm/projemm/bin/box64/build_ios/custom_bin/ld64.lld")
endif()

set(CMAKE_EXE_LINKER_FLAGS "${LINKFLAGS}")
set(CMAKE_SHARED_LINKER_FLAGS "${LINKFLAGS}")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Fix for "install TARGETS given no BUNDLE DESTINATION"
set(CMAKE_MACOSX_BUNDLE OFF)
set(CMAKE_INSTALL_BUNDLEDIR "bin")
