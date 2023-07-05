#!/usr/bin/env bash
# 
# A small test/demo integration project to enable 
# building the max3421-hcd usb module and connecting it to
# some specific hardware interface pins on a specific board
#
# TODO: make sure we can perform each of these edits with ex
#
printf "TODO: edits for max3421-hcd integration test example\n"
#
# -------------------------------------
# install the development tools
# sudo apt install git bc bison flex libssl-dev make libncurses5-dev
#
# -------------------------------------
# download the linux kernel source code
# cd ~
# mkdir linux
# cd ~/linux
# git clone --depth=1 git@github.com:whismanoid/linux-rpi-6.1.y-max3421-hcd.git
# git clone --depth=1 https://github.com/raspberrypi/linux
#
# check what version the source code is currently on
head Makefile -n 5
#
# -------------------------------------
printf "generate ./.config bcm2709 default configuration for Raspberry Pi 3+ 32-bit\n"
# default configuration for Rpi3+ 32-bit
# cd ~/linux/linux
KERNEL=kernel7
make bcm2709_defconfig
#
# -------------------------------------
# enable the MAX3421 device driver module, not part of the standard build
printf "edit ./.config update: set CONFIG_USB_MAX3421_HCD=m (build max3421-hcd module)\n"
# edit file ./.config
# (.config already included in whismanoid/linux-rpi-6.1.y-max3421-hcd.git)
# equivalent to make menuconfig ...Device Drivers | USB Support | MAX3421 HCD (USB-over-SPI) support: set it to <M>
# Substitute "# CONFIG_USB_MAX3421_HCD is not set" with "CONFIG_USB_MAX3421_HCD=m"
ex ./.config <<EOF
" % -- in the entire file"
" s/original/replacement/g -- substitute"
:%s/# CONFIG_USB_MAX3421_HCD is not set/CONFIG_USB_MAX3421_HCD=m/g
" wq -- Write and Quit"
:wq
EOF
#
# -------------------------------------
printf "new file arch/arm/boot/dts/overlays/max3421-hcd.dts"
# Write new file with contents given by the following here-document.
# <<EOF defines a here-document on subsequent lines until EOF limit line.
# <<-EOF suppresses leading tabs (but not spaces) in the here-document.
cat >arch/arm/boot/dts/overlays/max3421-hcd.dts <<EOF
/dts-v1/;
/plugin/;

/ {

	usb@0 {
		compatible = "maxim,max3421";
		reg = <0>;
		maxim,vbus-en-pin = <3 1>;
		spi-max-frequency = <26000000>;
		interrupt-parent = <&PIC>;
		interrupts = <42>;
	};

};
EOF
# -------------------------------------
#
printf "new file arch/arm/boot/dts/overlays/spi0-max3421e.dts"
# Write new file with contents given by the following here-document.
# <<EOF defines a here-document on subsequent lines until EOF limit line.
# <<-EOF suppresses leading tabs (but not spaces) in the here-document.
cat >arch/arm/boot/dts/overlays/spi0-max3421e.dts <<EOF
/dts-v1/;
/plugin/;

/ {
    compatible = "brcm,bcm2835";
    /* Disable spidev for spi0.1 - release resource */
    fragment@0 {
        target = <&spi0>;
        __overlay__ {
            status = "okay";
            spidev@1{
                status = "disabled";
            };
        };
    };

    /* Set pins used (IRQ) */
    fragment@1 {
        target = <&gpio>;
        __overlay__ {
            max3421_pins: max3421_pins {
                brcm,pins = <25>;		//GPIO25
                brcm,function = <0>;	//Input
            };
        };
    };

    /* Create the MAX3421 node */
    fragment@2 {
        target = <&spi0>;
        __overlay__ {
            //avoid dtc warning 
            #address-cells = <1>;
            #size-cells = <0>;
            max3421: max3421@1 {
                reg = <1>;	//CS 1
                spi-max-frequency = <20000000>;
                compatible = "maxim,max3421";
                pinctrl-names = "default";
                pinctrl-0 = <&max3421_pins>;
                interrupt-parent = <&gpio>;
                interrupts = <25 0x2>; 		//GPIO25, high-to-low
                maxim,vbus-en-pin = <1 1>;	//MAX GPOUT1, active high
            };
        };
    };

    __overrides__ {
        spimaxfrequency = <&max3421>,"spi-max-frequency:0";
        interrupt = <&max3421_pins>,"brcm,pins:0",<&max3421>,"interrupts:0";
        vbus-en-pin = <&max3421>,"maxim,vbus-en-pin:0";
        vbus-en-level = <&max3421>,"maxim,vbus-en-pin:4";
    };
};
EOF
# -------------------------------------
#
# -------------------------------------
printf "edit ./arch/arm/boot/dts/overlays/Makefile insert max3421-hcd.dts above matching line max98357a\n"
# edit file ./arch/arm/boot/dts/overlays/Makefile
# (make sure the backslashes are escaped properly; these quoted literal strings contain a literal backslash character at the end)
# find line containing "	max98357a.dtbo \"
#   insert new line above that one, containing "	max3421-hcd.dts \"
# TODO: shold this be .dtbo instead of .dts?
ex ./arch/arm/boot/dts/overlays/Makefile <<EOF
" /pattern/ -- find pattern match"
" i -- insert text given on subsequent lines, until a '.'-only line"
" insert/append a line ending in a backslash must use four backslashes"
:/max98357a.dtbo/i
	max3421-hcd.dtbo \\\\
.
" wq -- Write and Quit"
:wq
EOF
#
# -------------------------------------
printf "edit ./arch/arm/boot/dts/overlays/Makefile append spi0-max3421e.dtbo below matching line spi0-2cs\n"
# edit file ./arch/arm/boot/dts/overlays/Makefile
# (make sure the backslashes are escaped properly; these quoted literal strings contain a literal backslash character at the end)
# find line containing "	spi0-2cs.dtbo \"
#   insert new line below that one, containing "	spi0-max3421e.dtbo \"
ex ./arch/arm/boot/dts/overlays/Makefile <<EOF
" /pattern/ -- find pattern match"
" a -- append text below, given on subsequent lines, until a '.'-only line"
" insert/append a line ending in a backslash must use four backslashes"
:/spi0-2cs.dtbo/a
	spi0-max3421e.dtbo \\\\
.
"      "
" wq -- Write and Quit"
:wq
EOF
#
# -------------------------------------
#printf "build new kernel\n"
#KERNEL=kernel7
#printf "KERNEL=${KERNEL}\n"
#
#printf "head Makefile -n 5\n"
#head Makefile -n 5
#
#printf "make -j4 zImage modules dtbs\n"
#make -j4 zImage modules dtbs
#
#printf "make modules_install\n"
#sudo make modules_install
#
#printf "backing up old boot files\n"
#
#printf "sudo cp /boot/config.txt /boot/config-previous.txt\n"
#sudo cp /boot/config.txt /boot/config-previous.txt
#
#printf "sudo cp /boot/config.txt /boot/config-previous.txt\n"
#sudo cp /boot/config.txt /boot/config-previous.txt
#
#printf "edit /boot/config.txt to include max3421-hcd module: dtoverlay=spi0-max3421e\n"
## TODO
#
#printf "copying boot files\n"
#
#printf "sudo cp arch/arm/boot/dts/*.dtb /boot/\n"
#sudo cp arch/arm/boot/dts/*.dtb /boot/
#
#printf "sudo cp arch/arm/boot/dts/overlays/*.dtb* /boot/overlays/\n"
#sudo cp arch/arm/boot/dts/overlays/*.dtb* /boot/overlays/
#
#printf "sudo cp arch/arm/boot/dts/overlays/README /boot/overlays/\n"
#sudo cp arch/arm/boot/dts/overlays/README /boot/overlays/
#
#printf "sudo cp /boot/$KERNEL.img /boot/$KERNEL_$(uname -r).img\n"
#sudo cp /boot/$KERNEL.img /boot/$KERNEL_$(uname -r).img
#
#printf "sudo cp arch/arm/boot/zImage /boot/$KERNEL.img\n"
#sudo cp arch/arm/boot/zImage /boot/$KERNEL.img
#
#
## sudo cp drivers/usb/host/max3421-hcd.ko /lib/modules/$(uname -r)
## assuming VERSION=6 PATCHLEVEL=1 SUBLEVEL=31
## then install in 6.1.31-v7+
#printf "sudo cp drivers/usb/host/max3421-hcd.ko /lib/modules/6.1.31-v7+\n"
#sudo cp drivers/usb/host/max3421-hcd.ko /lib/modules/6.1.31-v7+
#
#printf "find /lib/modules -type f -name '*.ko' | grep -i max3421-hcd.ko\n"
#find /lib/modules -type f -name '*.ko' | grep -i max3421-hcd.ko
#
#printf "sudo modprobe max3421-hcd\n"
#sudo modprobe max3421-hcd
#
#printf "lsmod | grep -i max3421\n"
#lsmod | grep -i max3421
#
#printf "lsusb -v --tree\n"
#lsusb -v --tree
# -------------------------------------
#
