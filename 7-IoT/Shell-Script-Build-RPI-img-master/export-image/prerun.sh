#!/bin/bash -e
IMG_FILE="${STAGE_WORK_DIR}/${IMG_DATE}-${IMG_NAME}${IMG_SUFFIX}.img"

unmount_image ${IMG_FILE}

rm -f ${IMG_FILE}

rm -rf ${ROOTFS_DIR}
mkdir -p ${ROOTFS_DIR}
mkdir -p ${EXPORT_ROOTFS_DIR}/storage

BOOT_SIZE=$(du -sh ${EXPORT_ROOTFS_DIR}/boot -B M | cut -f 1 | tr -d M)
echo "boot size $BOOT_SIZE"
echo "${EXPORT_ROOTFS_DIR}"
echo "${EXPORT_ROOTFS_DIR}/boot"
echo " $(du -sh ${EXPORT_ROOTFS_DIR}/boot -B M )"
echo " $(du -sh ${EXPORT_ROOTFS_DIR}/boot -B M | cut -f 1)"

echo " $(du -sh ${EXPORT_ROOTFS_DIR}/boot -B M | cut -f 1 | tr -d M)"
echo " "
STORAGE_SIZE=$(du -sh ${EXPORT_ROOTFS_DIR}/storage -B M | cut -f 1 | tr -d M)
#STORAGE_SIZE=100
echo "storage size $STORAGE_SIZE"
TOTAL_SIZE=$(du -sh ${EXPORT_ROOTFS_DIR} -B M | cut -f 1 | tr -d M)

IMG_SIZE=$(expr $BOOT_SIZE \* 2 \+ $STORAGE_SIZE \* 100 \+ $TOTAL_SIZE \+ 512)M

echo "img size $IMG_SIZE"
fallocate -l ${IMG_SIZE} ${IMG_FILE}
echo "afiseaza fallocate"
echo " $fallocate"

echo "incepe partitionarea"

fdisk ${IMG_FILE} > /dev/null 2>&1 <<EOF
o
n


8192
+63M
p
t
c
n


137216
+100M
p
n


342016

p
w
EOF

echo "se termina partitionarea"

PARTED_OUT=$(parted -s ${IMG_FILE} unit b print)
echo "parted out afisare:"

echo "$PARTED_OUT"
echo " afiseaza boot  offset"
BOOT_OFFSET=$(echo "$PARTED_OUT" | grep -e '^ 1'| xargs echo -n \
| cut -d" " -f 2 | tr -d B)
echo "$BOOT_OFFSET"
BOOT_LENGTH=$(echo "$PARTED_OUT" | grep -e '^ 1'| xargs echo -n \
| cut -d" " -f 4 | tr -d B)
echo "$BOOT_LENGTH"
echo " afiseaza storage offset"
STORAGE_OFFSET=$(echo "$PARTED_OUT" | grep -e '^ 2'| xargs echo -n \
| cut -d" " -f 2 | tr -d B)
echo "$STORAGE_OFFSET"
STORAGE_LENGTH=$(echo "$PARTED_OUT" | grep -e '^ 2'| xargs echo -n \
| cut -d" " -f 4 | tr -d B)
echo "$STORAGE_LENGTH"
echo " "
echo "afisam root offset"
ROOT_OFFSET=$(echo "$PARTED_OUT" | grep -e '^ 3'| xargs echo -n \
| cut -d" " -f 2 | tr -d B)
ROOT_LENGTH=$(echo "$PARTED_OUT" | grep -e '^ 3'| xargs echo -n \
| cut -d" " -f 4 | tr -d B)
echo "$ROOT_OFFSET"
echo "$ROOT_LENGTH"
echo "se afiseaza size"
BOOT_DEV=$(losetup --show -f -o ${BOOT_OFFSET} --sizelimit ${BOOT_LENGTH} ${IMG_FILE})
echo "boot dev $BOOT_DEV"
STORAGE_DEV=$(losetup --show -f -o ${STORAGE_OFFSET} --sizelimit ${STORAGE_LENGTH} ${IMG_FILE})
echo "ce da storage dev  $STORAGE_DEV"
ROOT_DEV=$(losetup --show -f -o ${ROOT_OFFSET} --sizelimit ${ROOT_LENGTH} ${IMG_FILE})
echo "/boot: offset $BOOT_OFFSET, length $BOOT_LENGTH"
echo "/storage: offset $STORAGE_OFFSET, length $STORAGE_LENGTH"
echo "/:     offset $ROOT_OFFSET, length $ROOT_LENGTH"

echo "mount"
#mkfs.ext4 -0 ^huge_file $BOOT_DEV > /dev/null

#mkdosfs -n boot -F32 -v $BOOT_DEV > /dev/null

#mkfs.ext4 -O ^huge_file $BOOT_DEV > /dev/null

mkdosfs -n boot -F 32 -v $BOOT_DEV > /dev/null
mkfs.ext4 -O ^huge_file $STORAGE_DEV > /dev/null
mkfs.ext4 -O ^huge_file $ROOT_DEV > /dev/null


echo "mount root"
mount -v $ROOT_DEV ${ROOTFS_DIR} -t ext4
echo "trece mount root"

echo "creaza directorul de boot"
mkdir -p ${ROOTFS_DIR}/boot
echo "trece de creare boot"

echo "incepe mount boot"
mount -v $BOOT_DEV ${ROOTFS_DIR}/boot -t vfat
#mount -v $BOOT_DEV ${ROOTFS_DIR}/boot -t ext4
echo "trece mount boot"

mkdir -p ${ROOTFS_DIR}/storage
echo "trece CREARE storage"
echo "incepe mount storage"
mount -v $STORAGE_DEV ${ROOTFS_DIR}/storage -t ext4



rsync -aHAXx ${EXPORT_ROOTFS_DIR}/ ${ROOTFS_DIR}/
