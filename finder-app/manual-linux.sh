#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-linux-gnu-
BASE=$(pwd)
pwd
if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}
    
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper

    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig

    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all

    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
    
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs



    # TODO: Add your kernel build steps here
fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image "$OUTDIR"
echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi
mkdir -p ${OUTDIR}/rootfs
cd ${OUTDIR}/rootfs
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log
# TODO: Create necessary base directories
echo "Next step"
cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
else
    cd busybox
fi
make distclean
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig

sed -i 's/CONFIG_TC=y/# CONFIG_TC is not set/' .config
make -j8 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} 

make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} \
    CONFIG_PREFIX=${OUTDIR}/rootfs install

    cd ${OUTDIR}/rootfs
    pwd
    sudo chown root:root bin/busybox
    sudo chmod u+s bin/busybox
echo "successfully install"
# TODO: Make and install busybox

echo "Library dependencies"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library"

SYSROOT=$(aarch64-linux-gnu-gcc -print-sysroot)
#find $SYSROOT -name ld-linux-aarch64.so.1
cp -v /usr/aarch64-linux-gnu/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib64
cp -v /usr/aarch64-linux-gnu/lib/libm.so.6 ${OUTDIR}/rootfs/lib64
cp -v /usr/aarch64-linux-gnu/lib/libresolv.so.2 ${OUTDIR}/rootfs/lib64
cp -v /usr/aarch64-linux-gnu/lib/libc.so.6 ${OUTDIR}/rootfs/lib64
cp -v /usr/aarch64-linux-gnu/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib
cp -v /usr/aarch64-linux-gnu/lib/libm.so.6 ${OUTDIR}/rootfs/lib
cp -v /usr/aarch64-linux-gnu/lib/libresolv.so.2 ${OUTDIR}/rootfs/lib
cp -v /usr/aarch64-linux-gnu/lib/libc.so.6 ${OUTDIR}/rootfs/lib


# TODO: Add library dependencies to rootfs
cd ${OUTDIR}/rootfs
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 600 dev/console c 5 1
sudo mknod -m 666 dev/tty c 5 0
# TODO: Make device nodes
# use arch
#cd /home/siyaya/Documents/gitclone/homework/assignment-1-Tillingxianyu/finder-app
#use docker
#cd /home/assignment/finder-app
cd ${BASE}
pwd
make clean 
make CROSS_COMPILE=${CROSS_COMPILE}
cp -v writer ${OUTDIR}/rootfs/home


# TODO: Clean and build the writer utility
mkdir ${OUTDIR}/rootfs/home/conf
cp -v finder.sh ${OUTDIR}/rootfs/home
cp -v conf/username.txt ${OUTDIR}/rootfs/home/conf
cp -v conf/assignment.txt ${OUTDIR}/rootfs/home/conf 
cp -v finder-test.sh ${OUTDIR}/rootfs/home
cp -v autorun-qemu.sh ${OUTDIR}/rootfs/home
 
# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs

cd ${OUTDIR}/rootfs
sudo chown -R root:root .

# TODO: Chown the root directory
cd ${OUTDIR}/rootfs
#sudo ln -sf  ${OUTDIR}/rootfs/sbin/init ${OUTDIR}/rootfs/bin/busybox 
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ${OUTDIR}/initramfs.cpio.gz
# TODO: Create initramfs.cpio.gz
echo "successful"
