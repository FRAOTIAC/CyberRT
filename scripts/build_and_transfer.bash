#!/bin/bash
set -e


function compile() {
pushd /workshop/wsl2_workshop/CyberRT/

unset LD_LIBRARY_PATH
source /opt/b*/*/environment-setup-aarch64-bst-linux
# install third party libraries
./scripts/install.sh aarch64

# 构建 CyberRT
source ./install/setup.bash
mkdir -p build && pushd build
  rm -rf *
  cmake_args+=(
      "-DCMAKE_CROSSCOMPILING=ON"
      "-DCMAKE_SYSTEM_NAME=Linux"
      "-DCMAKE_SYSTEM_PROCESSOR=aarch64"
      "-DCMAKE_SYSROOT=${aarch64_ROOT_DIR}"
    )
rm -rf * && cmake .. "${cmake_args[@]}" && make -j$(nproc) && make package
popd
popd
}

function passwd_ssh() {
  sshpass -p "a" ssh "$@"
}
function passwd_scp() {
  echo scp -r "$@"
  sshpass -p "a" scp -r "$@"
}

function transfer() {
  DEV_IP="192.168.6.187"
  USERNAME="root"
  pushd /workshop/wsl2_workshop/CyberRT/build
  passwd_ssh $USERNAME@$DEV_IP "mkdir -p /mnt/nfs_share/cyber8"
  passwd_ssh $USERNAME@$DEV_IP "mkdir -p /mnt/nfs_share/cyber8/examples"
  passwd_ssh $USERNAME@$DEV_IP "mkdir -p /mnt/nfs_share/cyber8/install"
  passwd_scp cyber/examples/cyber_example*  $USERNAME@$DEV_IP:/mnt/nfs_share/cyber8/examples/
#  passwd_scp libcyber.so $USERNAME@$DEV_IP:/mnt/nfs_share/usr/local/lib/
  passwd_scp packages/libcyber_8.0.0_aarch64.deb $USERNAME@$DEV_IP:/mnt/nfs_share/cyber8/
  passwd_scp ../install/lib $USERNAME@$DEV_IP:/mnt/nfs_share/cyber8/install/
  passwd_scp /root/poco_install/lib $USERNAME@$DEV_IP:/mnt/nfs_share/cyber8/install/
  passwd_scp /root/poco_install/include $USERNAME@$DEV_IP:/mnt/nfs_share/cyber8/install/
#  passwd_ssh $USERNAME@$DEV_IP "sudo dpkg -i /mnt/nfs_share/libcyber_8.0.0_aarch64.deb"
  passwd_ssh $USERNAME@$DEV_IP "cd  /mnt/nfs_share/cyber8/; ar -x libcyber_8.0.0_aarch64.deb"
  passwd_ssh $USERNAME@$DEV_IP "cd  /mnt/nfs_share/cyber8/; tar -xvf data.tar.gz"
  popd
}

function main() {
  compile
  transfer
}

setup() {
  export LD_LIBRARY_PATH=/mnt/nfs_share/cyber8/usr/local/lib:/mnt/nfs_share/cyber8/install/lib:/usr/lib
#  export LD_LIBRARY_PATH=/usr/lib/disable:$LD_LIBRARY_PATH
  source /mnt/nfs_share/cyber8/usr/local/setup.bash
}

main "$@"