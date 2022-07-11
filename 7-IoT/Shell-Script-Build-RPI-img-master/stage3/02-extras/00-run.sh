#!/bin/bash -e

#install -v -d ${ROOTFS_DIR}/home/
install -v -m 644 files/validator_*_armhf.deb ${ROOTFS_DIR}/home
install -v -m 644 files/run.sh ${ROOTFS_DIR}/home

chmod +x ${ROOTFS_DIR}/home/run.sh


on_chroot  << EOF
dphys-swapfile swapoff
dphys-swapfile uninstall
update-rc.d dphys-swapfile remove
sh /home/run.sh

EOF

echo "$on_chroot"


           




ln -sf pip3 ${ROOTFS_DIR}/usr/bin/pip-3.2

