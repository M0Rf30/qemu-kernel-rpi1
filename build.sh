#!/bin/sh
#
# Build ARM kernel for QEMU Raspberry Pi 1 Emulation
#
#######################################################
MODEL=rpi1
REMOTE=https://github.com/raspberrypi/linux
TOOLCHAIN=arm-none-eabi
COMMIT=$(git remote show "$REMOTE" | grep "HEAD" | cut -f 2 -d : | tr -d '[:space:]')
export ARCH=arm
export CROSS_COMPILE=${TOOLCHAIN}-

if [[ ! -f "$COMMIT.tar.gz" ]] ;then
    curl -L -O "$REMOTE/archive/$COMMIT.tar.gz" || exit 1
fi

# Extracting sources
if [ ! -d linux-$COMMIT ]; then
    tar xf $COMMIT.tar.gz
    patch -Np1 -i ../patches/linux-arm.patch -d linux-$COMMIT
fi

cd linux-$COMMIT

KERNEL_VERSION=$(make kernelversion)
KERNEL_TARGET_FILE_NAME=qemu-kernel-$MODEL-$KERNEL_VERSION
echo "Building Qemu Raspberry Pi kernel qemu-kernel-$KERNEL_VERSION"

# Config
make CC="ccache ${TOOLCHAIN}-gcc" versatile_defconfig
scripts/kconfig/merge_config.sh .config ../config

# Compiling
#make CC="ccache ${TOOLCHAIN}-gcc" xconfig
make -j 4 -k CC="ccache ${TOOLCHAIN}-gcc" bzImage dtbs
cat arch/arm/boot/zImage arch/arm/boot/dts/versatile-pb.dtb > ../build/$KERNEL_TARGET_FILE_NAME
