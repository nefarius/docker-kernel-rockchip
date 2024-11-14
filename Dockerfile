FROM ubuntu:20.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /build

# prepare build environment
RUN apt update && apt install git curl -y
RUN bash -c \
  "$(curl -fsSL https://raw.githubusercontent.com/friendlyarm/build-env-on-ubuntu-bionic/master/install.sh)"

ENV PATH=/opt/FriendlyARM/toolchain/11.3-aarch64/bin:$PATH
ENV GCC_COLORS=auto

RUN git clone https://github.com/friendlyarm/kernel-rockchip --single-branch --depth 1 -b nanopi6-v6.1.y kernel-rockchip

WORKDIR /build/kernel-rockchip

RUN touch .scmversion

# enable Raw Gadget API
RUN echo CONFIG_USB_RAW_GADGET=y > ./arch/arm64/configs/raw_gadget.config

# prepare build configuration
RUN make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 nanopi6_linux_defconfig raw_gadget.config

# gadget system bugfixes
# https://lore.kernel.org/linux-usb/CA+fCnZcQSYy63ichdivAH5-fYvN2UMzTtZ--h=F6nK0jfVou3Q@mail.gmail.com/T/#u
COPY ./usb-gadget-fix.patch .
RUN git apply usb-gadget-fix.patch

# build kernel (this will take a while)
RUN make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 nanopi6-images -j$(nproc)

# build kernel modules
WORKDIR /build/kernel-rockchip/out-modules
RUN make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 INSTALL_MOD_PATH="$PWD/out-modules" modules -j$(nproc)
RUN make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 INSTALL_MOD_PATH="$PWD/out-modules" modules_install

RUN KERNEL_VER=$(make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 kernelrelease) && \
  [ ! -f "$PWD/out-modules/lib/modules/${KERNEL_VER}/modules.dep" ] && depmod -b $PWD/out-modules -E Module.symvers -F System.map -w ${KERNEL_VER} && \
  (cd $PWD/out-modules && find . -name \*.ko | xargs aarch64-linux-strip --strip-unneeded)
