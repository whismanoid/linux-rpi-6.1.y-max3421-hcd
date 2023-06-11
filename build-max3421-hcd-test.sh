KERNEL=kernel7
printf "KERNEL=${KERNEL}\n"

printf "head Makefile -n 5\n"
head Makefile -n 5

printf "make -j4 zImage modules dtbs\n"
make -j4 zImage modules dtbs

printf "make modules_install\n"
sudo make modules_install

printf "copying boot files\n"
printf "sudo cp arch/arm/boot/dts/*.dtb /boot/\n"
sudo cp arch/arm/boot/dts/*.dtb /boot/

printf "sudo cp arch/arm/boot/dts/overlays/*.dtb* /boot/overlays/\n"
sudo cp arch/arm/boot/dts/overlays/*.dtb* /boot/overlays/

printf "sudo cp arch/arm/boot/dts/overlays/README /boot/overlays/\n"
sudo cp arch/arm/boot/dts/overlays/README /boot/overlays/

printf "sudo cp /boot/$KERNEL.img /boot/$KERNEL_$(uname -r).img\n"
sudo cp /boot/$KERNEL.img /boot/$KERNEL_$(uname -r).img

printf "sudo cp arch/arm/boot/zImage /boot/$KERNEL.img\n"
sudo cp arch/arm/boot/zImage /boot/$KERNEL.img

#
# sudo cp drivers/usb/host/max3421-hcd.ko /lib/modules/$(uname -r)
# assuming VERSION=6 PATCHLEVEL=1 SUBLEVEL=31
# then install in 6.1.31-v7+
printf "sudo cp drivers/usb/host/max3421-hcd.ko /lib/modules/6.1.31-v7+\n"
sudo cp drivers/usb/host/max3421-hcd.ko /lib/modules/6.1.31-v7+

printf "find /lib/modules -type f -name '*.ko' | grep -i max3421-hcd.ko\n"
find /lib/modules -type f -name '*.ko' | grep -i max3421-hcd.ko

printf "sudo modprobe max3421-hcd\n"
sudo modprobe max3421-hcd

printf "lsmod | grep -i max3421\n"
lsmod | grep -i max3421
