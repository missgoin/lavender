#!/usr/bin/env bash
 # Script For Building Android Kernel

# Bail out if script fails
set -e

##---------------------------------------------------------##

# Basic Information
KERNEL_DIR="$(pwd)"
VERSION=01
MODEL=Xiaomi
DEVICE=lavender
DEFCONFIG=${DEVICE}-perf_defconfig
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
#C_BRANCH=$(git branch --show-current)

##----------------------------------------------------------##
## Export Variables and Info
function exports() {
  export ARCH=arm64
  export SUBARCH=arm64
  #export LOCALVERSION="-${C_BRANCH}"
  export KBUILD_BUILD_HOST=Pancali
  export KBUILD_BUILD_USER="unknown"
  export PROCS=$(nproc --all)
  export DISTRO=$(source /etc/os-release && echo "${NAME}")

# Variables
KERVER=$(make kernelversion)
COMMIT_HEAD=$(git log --oneline -1)
DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%T")
TANGGAL=$(date +"%F%S")

# Compiler and Build Information
TOOLCHAIN=azure # List (clang = nexus14 | aosp | nexus15 | proton )
#LINKER=ld # List ( ld.lld | ld.bfd | ld.gold | ld )
VERBOSE=0

FINAL_ZIP=SUPER.KERNEL-Lavender-${TANGGAL}.zip
FINAL_ZIP_ALIAS=Kernullav-${TANGGAL}.zip

}

##----------------------------------------------------------##

## Telegram Bot Integration

##----------------------------------------------------------##

## Get Dependencies
function clone() {
# Get Toolchain
if [[ $TOOLCHAIN == "azure" ]]; then
       git clone --depth=1  https://gitlab.com/Panchajanya1999/azure-clang clang
elif [[ $TOOLCHAIN == "nexus14" ]]; then
       git clone --depth=1 https://gitlab.com/Project-Nexus/nexus-clang.git -b nexus-14 clang
elif [[ $TOOLCHAIN == "proton" ]]; then
       git clone --depth=1 https://github.com/kdrag0n/proton-clang clang
elif [[ $TOOLCHAIN == "nexus15" ]]; then
       git clone --depth=1 https://gitlab.com/Project-Nexus/nexus-clang.git -b nexus-15 clang
fi

# Get AnyKernel3
git clone --depth=1 https://github.com/reaPeR1010/AnyKernel3 AK3

# Set PATH
PATH="${KERNEL_DIR}/clang/bin:${PATH}"

# Export KBUILD_COMPILER_STRING
export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
}

##----------------------------------------------------------------##

function compile() {
START=$(date +"%s")

# Generate .config
make O=out ARCH=arm64 ${DEFCONFIG}

# Start Compilation
if [[ "$TOOLCHAIN" == "azure" || "$TOOLCHAIN" == "proton" ]]; then
     make -j$(nproc --all) O=out ARCH=arm64 CC=clang CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- LLVM=1 LLVM_IAS=1 AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip READELF=llvm-readelf OBJSIZE=llvm-size V=$VERBOSE 2>&1 | tee error.log
elif [[ "$TOOLCHAIN" == "nexus" ]]; then
     make -j$(nproc --all) O=out ARCH=arm64 CC=clang CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- LLVM=1 LLVM_IAS=1 AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip READELF=llvm-readelf OBJSIZE=llvm-size V=$VERBOSE 2>&1 | tee error.log
fi

}

##----------------------------------------------------------------##

function zipping() {
# Copy Files To AnyKernel3 Zip
cp $IMAGE AK3

# Zipping and Upload Kernel
cd AK3 || exit 1
zip -r9 ${FINAL_ZIP_ALIAS} *
MD5CHECK=$(md5sum "$FINAL_ZIP_ALIAS" | cut -d' ' -f1)
echo "Zip: $FINAL_ZIP_ALIAS"
curl -T $FINAL_ZIP_ALIAS temp.sh; echo

cd ..

}

##----------------------------------------------------------##

# Functions
exports
clone
compile
zipping

##------------------------*****-----------------------------##
