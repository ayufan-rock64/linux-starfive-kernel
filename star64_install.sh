#!/bin/bash

set -xeo pipefail

if [[ $(id -u) -ne 0 ]]; then
  sudo --preserve-env=SSH_AUTH_SOCK $0 "$@"
  exit 1
fi

export CCACHE=ccache
export PATH="/usr/lib/ccache:$PATH"
export CROSS_COMPILE="ccache riscv64-linux-gnu-"
export ARCH="riscv"
export ROOT="$PWD"
export LOCALVERSION="-dev"
export INSTALL_PATH="$ROOT/.output"

set -xeo pipefail
mkdir -p "$INSTALL_PATH/boot"

if [[ "$1" == "menuconfig" ]]; then
  make menuconfig
  exit
fi

make -j$(nproc)
make -j$(nproc) install modules_install dtbs_install \
  INSTALL_PATH="$INSTALL_PATH/boot" \
  INSTALL_MOD_PATH="$INSTALL_PATH"

rm -f "$INSTALL_PATH/boot"/*.old

rsync --partial --checksum -rv "$INSTALL_PATH/boot/." root@star64.home:/boot/
rsync --partial --checksum -rv "$INSTALL_PATH/lib/modules/." root@star64.home:/lib/modules/
ssh root@star64.home "sync && reboot"
