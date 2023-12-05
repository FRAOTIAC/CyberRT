#!/usr/bin/env bash

set -e

CURRENT_PATH=$(cd $(dirname $0) && pwd)
INSTALL_PREFIX="$CURRENT_PATH/../install/"
#ARCH=$(uname -m)
# get arch from env
# if input is empty, use uname -m
if [ -z "$1" ]; then
  ARCH=$(uname -m)
else
  ARCH=$1
fi
#ARCH == aarch64 or arm64 then set INSTALL_PREFIX to /opt/bstos/2.3.1.5/sysroots/aarch64-bst-linux/usr/local/
if [[ "${ARCH}" == "aarch64" ]] || [[ "${ARCH}" == "arm64" ]]; then
  INSTALL_PREFIX="/opt/bstos/2.3.1.5/sysroots/aarch64-bst-linux/usr/"
fi
echo "ARCH: $ARCH"

sleep 3


function download() {
  URL=$1
  LIB_NAME=$2
  DOWNLOAD_PATH="$CURRENT_PATH/../third_party/$LIB_NAME/"
  if [ -e $DOWNLOAD_PATH ]
  then
    echo ""
  else
    echo "############### Install $LIB_NAME $URL ################"
    git clone $URL "$DOWNLOAD_PATH"
  fi
}

function init() {
  echo "############### Init. ################"
  if [ -e $INSTALL_PREFIX ]
  then
    echo ""
  else
    mkdir -p $INSTALL_PREFIX
  fi
  chmod a+w $INSTALL_PREFIX
}

function build_setup() {
  echo "############### Build Setup. ################"
  local NAME="setup"
  download "https://github.com/minhanghuang/setup.git" "$NAME"
  pushd "$CURRENT_PATH/../third_party/$NAME/"
  mkdir -p build && cd build && rm -rf *
  cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX -DBUILD_SHARED_LIBS=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON ..
  make install -j$(nproc)
  popd
}

function build_nlohmann_json() {
  echo "############### Build Nlohmann Json. ################"
  local NAME="nlohmann_json"
  download "https://github.com/nlohmann/json.git" "$NAME"
  pushd "$CURRENT_PATH/../third_party/$NAME/"
  mkdir -p build && cd build && rm -rf *
  cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX -DBUILD_SHARED_LIBS=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DJSON_BuildTests=OFF ..
  make install -j$(nproc)
  popd
}

function build_fastdds() {
  echo "############### Build Fast-DDS. ################"
  # download "https://github.com/eProsima/Fast-RTPS.git" "Fast-RTPS"
  # pushd "$CURRENT_PATH/../third_party/Fast-RTPS/"
  # git checkout v1.5.0
  # git submodule update --init
  # patch -p1 < "$CURRENT_PATH/../scripts/FastRTPS_1.5.0.patch"
  # mkdir -p build && cd build
  # cmake -DEPROSIMA_BUILD=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/home/trunk/work/code/github/CyberRT/third_party/Fast-RTPS/build/external/install ..
  # make -j$(nproc)
  # make install
  # cmake -DEPROSIMA_BUILD=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX ..
  # make -j$(nproc)
  # make install
  # popd
  local INSTALL_PATH="$CURRENT_PATH/../third_party/"
  if [[ "${ARCH}" == "x86_64" ]]; then
    PKG_NAME="fast-rtps-1.5.0-1.prebuilt.x86_64.tar.gz"
  else # aarch64
    PKG_NAME="fast-rtps-1.5.0-1.prebuilt.aarch64.tar.gz"
  fi
  DOWNLOAD_LINK="https://apollo-system.cdn.bcebos.com/archive/6.0/${PKG_NAME}"
  if [ -e $INSTALL_PATH/$PKG_NAME ]
  then
    echo ""
  else
    wget -t 10 $DOWNLOAD_LINK -P $INSTALL_PATH
  fi
  pushd $INSTALL_PATH
  tar -zxf ${PKG_NAME}
  cp -r fast-rtps-1.5.0-1/* $INSTALL_PREFIX
  rm -rf fast-rtps-1.5.0-1
  popd
}

function build_gfamily() {
  echo "############### Build Google Libs. ################"
  download "https://github.com/gflags/gflags.git" "gflags"
  download "https://github.com/google/glog.git" "glog"
  download "https://github.com/google/googletest.git" "googletest"
  download "https://github.com/protocolbuffers/protobuf.git" "protobuf"

  # gflags
  pushd "$CURRENT_PATH/../third_party/gflags/"
  git checkout v2.2.0
  mkdir -p build && cd build && rm -rf *
  CXXFLAGS="-fPIC $CXXFLAGS" cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX -DBUILD_SHARED_LIBS=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON ..
  make install -j$(nproc)
  popd

  # glog
  pushd "$CURRENT_PATH/../third_party/glog/"
#  git checkout v0.4.0
  git checkout v0.5.0
  mkdir -p build && cd build && rm -rf *
  if [ "$ARCH" == "x86_64" ]; then
    CXXFLAGS="-fPIC $CXXFLAGS" cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX -DBUILD_SHARED_LIBS=ON ..
  elif [ "$ARCH" == "aarch64" ]; then
    CXXFLAGS="-fPIC $CXXFLAGS" cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX -DBUILD_SHARED_LIBS=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON ..
  else
      echo "not support $ARCH"
  fi
  make install -j$(nproc)
  popd
 
  # googletest
  pushd "$CURRENT_PATH/../third_party/googletest/"
  git checkout release-1.10.0
  mkdir -p build && cd build && rm -rf *
  CXXFLAGS="-fPIC $CXXFLAGS" cmake -DCMAKE_CXX_FLAGS="-w" -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX -DBUILD_SHARED_LIBS=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON ..
  make install -j$(nproc)
  popd

  # protobuf
  pushd "$CURRENT_PATH/../third_party/protobuf/"
#  git checkout v3.14.0
  git checkout v3.6.1
  cd cmake && mkdir -p build && cd build && rm -rf *
  cmake -Dprotobuf_BUILD_SHARED_LIBS=ON -Dprotobuf_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX -DCMAKE_POSITION_INDEPENDENT_CODE=ON ..
  make install -j$(nproc)
  popd
}

function build_poco() {
  echo "############### Build Poco. ################"
  local NAME="poco"
  local VERSION="poco-1.8.0.1-release"
  local TARBALL_URL="https://github.com/pocoproject/poco/archive/${VERSION}.tar.gz"
  local MD5SUM_EXPECTED="07aa03d7976d0dbc141d95821c104c10"
  local DOWNLOAD_DIR="$CURRENT_PATH/../third_party"
  local FOLDERNAME="${NAME}-${VERSION}"
  local DESIRED_FOLDERNAME="${VERSION}"

  # Download Poco source tarball
  echo "Downloading Poco source..."
  wget ${TARBALL_URL} -O "${DOWNLOAD_DIR}/${FOLDERNAME}.tar.gz"

  # MD5 checksum verification
  echo "MD5 checksum verification..."
  echo "${MD5SUM_EXPECTED}  ${DOWNLOAD_DIR}/${FOLDERNAME}.tar.gz" | md5sum -c -

  # Prepare the source directory
  [ -d "${DOWNLOAD_DIR}/${DESIRED_FOLDERNAME}" ] && rm -rf "${DOWNLOAD_DIR}/${DESIRED_FOLDERNAME}"
  mkdir -p "${DOWNLOAD_DIR}/${DESIRED_FOLDERNAME}"
  tar -xzf "${DOWNLOAD_DIR}/${FOLDERNAME}.tar.gz" --strip-components=1 -C "${DOWNLOAD_DIR}/${DESIRED_FOLDERNAME}"

  # Compile Poco
  pushd "${DOWNLOAD_DIR}/${DESIRED_FOLDERNAME}"
  mkdir -p build && pushd build && rm -rf *


  cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
        -DENABLE_CRYPTO:BOOL=OFF \
        -DENABLE_DATA:BOOL=OFF \
        -DENABLE_JSON:BOOL=OFF \
        -DENABLE_MONGODB:BOOL=OFF \
        -DENABLE_NET:BOOL=OFF \
        -DENABLE_NETSSL:BOOL=OFF \
        -DENABLE_PAGECOMPILER_FILE2PAGE:BOOL=OFF \
        -DENABLE_PAGECOMPILER:BOOL=OFF \
        -DENABLE_REDIS:BOOL=OFF \
        -DENABLE_UTIL:BOOL=OFF \
        -DENABLE_XML:BOOL=OFF \
        -DENABLE_ZIP:BOOL=OFF \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON ..
  make install -j$(nproc)
  popd && popd
}

function main() {
  echo "############### Install Third Party. ################"
  init
  build_setup
  if [[ "${ARCH}" == "x86_64" ]]; then
    build_gfamily
    build_nlohmann_json
  fi
  build_fastdds
  build_poco
  return
}

main "$@"
