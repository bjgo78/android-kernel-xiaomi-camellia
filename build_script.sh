#!/bin/bash

# 设置时区
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime

# 彩色输出
green='\033[01;32m'
red='\033[01;31m'
yellow='\033[01;33m'
restore='\033[0m'

echo -e "${green}–––––––––––––––––––––––––––"
echo "Cloning Toolchains If Needed"
echo -e "–––––––––––––––––––––––––––${restore}"

TOOLCHAIN_DIR="$HOME/toolchain"
mkdir -p "$TOOLCHAIN_DIR"

# 克隆 Proton Clang
if [ ! -d "$TOOLCHAIN_DIR/proton-clang/bin" ]; then
  git clone --depth=1 https://github.com/kdrag0n/proton-clang "$TOOLCHAIN_DIR/proton-clang"
else
  echo -e "${yellow}[!] Skipping Proton Clang clone, already exists.${restore}"
fi

# 克隆 GCC
if [ ! -d "$TOOLCHAIN_DIR/gcc/bin" ]; then
  git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 "$TOOLCHAIN_DIR/gcc"
else
  echo -e "${yellow}[!] Skipping GCC64 clone, already exists.${restore}"
fi

# 克隆 GCC32
if [ ! -d "$TOOLCHAIN_DIR/gcc32/bin" ]; then
  git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 "$TOOLCHAIN_DIR/gcc32"
else
  echo -e "${yellow}[!] Skipping GCC32 clone, already exists.${restore}"
fi

echo -e "${green}[*] Done cloning toolchains.${restore}"

# 设置路径变量
export PATH="$TOOLCHAIN_DIR/proton-clang/bin:$TOOLCHAIN_DIR/gcc/bin:$TOOLCHAIN_DIR/gcc32/bin:$PATH"

# 编译参数
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz
START=$(date +"%s")
KERNEL_DIR=$(pwd)
DEFCONFIG=camellia_defconfig
VERSION="$(grep 'CONFIG_LOCALVERSION=' arch/arm64/configs/$DEFCONFIG | cut -d '"' -f2 | sed 's/^.//')"
ZIPNAME="$VERSION-camellia-$(date +%Y%m%d-%H%M).zip"
export KBUILD_BUILD_USER="Konnlori"
export KBUILD_BUILD_HOST="Instance"

# 编译函数
compile_kernel() {
    echo -e "${green}[*] Starting Kernel Compilation...${restore}"
    make O=out ARCH=arm64 $DEFCONFIG
    make -j4 O=out \
        ARCH=arm64 \
        CC=clang \
        LD=ld.lld \
        CLANG_TRIPLE=aarch64-linux-gnu- \
        CROSS_COMPILE=aarch64-linux-android- \
        CROSS_COMPILE_ARM32=arm-linux-androideabi-

    if [ ! -f "$IMAGE" ]; then
        echo -e "${red}[!] Build failed: Image.gz not found!${restore}"
        exit 1
    fi

    cp "$IMAGE" AnyKernel
}

# 打包函数
zipping() {
    echo -e "${green}[*] Zipping kernel...${restore}"
    cd AnyKernel || exit 1
    rm -f *.zip
    zip -r9 "$ZIPNAME" * > /dev/null
    mv "$ZIPNAME" ..
    cd ..
}

# 调用
compile_kernel
zipping

END=$(date +"%s")
DIFF=$(($END - $START))
echo -e "${green}----------------------------------------------"
echo "Build Completed in: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo "Output File: $ZIPNAME"
echo -e "----------------------------------------------${restore}"