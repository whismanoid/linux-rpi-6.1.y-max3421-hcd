make -j4 zImage modules dtbs
sudo make modules_install
printf "copying boot files\n"
sudo cp arch/arm/boot/dts/*.dtb /boot/
sudo cp arch/arm/boot/dts/overlays/*.dtb* /boot/overlays/
sudo cp arch/arm/boot/dts/overlays/README /boot/overlays/
sudo cp arch/arm/boot/zImage /boot/$KERNEL.img
sudo cp drivers/usb/host/max3421-hcd.ko /lib/modules/$(uname -r)
