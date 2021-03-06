#!/bin/bash
set -euo pipefail

BUILD_DEPS="gcc g++ cmake autoconf git curl rename chrpath cpio libssl1.0-dev libxml2-dev nano"
SDK_REPO="DavidSkrundz/sdks"
SDK_LIST="iPhoneOS12.2.sdk"

apt-get update
apt-get upgrade --yes
apt-get install --yes clang make perl rsync  $BUILD_DEPS

pushd /opt

git clone https://github.com/theos/theos.git
pushd theos
git submodule update --init --recursive
popd

git clone https://github.com/kabiroberai/ios-toolchain-linux.git toolchain
pushd toolchain
./prepare-toolchain
cp /usr/lib/llvm-6.0/lib/libLTO.so* staging/linux/iphone/lib/
mv staging/linux ../theos/toolchain/
popd
rm -rf toolchain

git clone https://github.com/$SDK_REPO.git sdk
pushd sdk
mv $SDK_LIST ../theos/sdks/
popd
rm -rf sdk

popd

curl -LO https://github.com/sbingner/llvm-project/releases/download/v10.0.0-1/linux-ios-arm64e-clang-toolchain.tar.lzma
TMP=$(mktemp -d)
tar --lzma -xvf linux-ios-arm64e-clang-toolchain.tar.lzma -C $TMP
pushd $TMP/ios-arm64e-clang-toolchain/bin
find * ! -name clang-10 -and ! -name ldid -and ! -name ld64 -exec mv {} arm64-apple-darwin14-{} \;
find * -xtype l -exec sh -c "readlink {} | xargs -I{LINK} ln -f -s arm64-apple-darwin14-{LINK} {}" \;
popd
mkdir -p $THEOS/toolchain/linux/iphone
rsync -a $TMP/ios-arm64e-clang-toolchain/* $THEOS/toolchain/linux/iphone/
rm -rf $TMP linux-ios-arm64e-clang-toolchain.tar.lzma

popd
