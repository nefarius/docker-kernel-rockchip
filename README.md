# FriendlyARM Rockchip Linux Kernel Build Environment

## Usage

Clone this repository on a machine with Docker installed and follow  the instructions.

### Build modified kernel

Run this on your Docker build machine.

```bash
# build the kernel
docker build -t docker-kernel-rockchip .
# extract build artifacts
docker create --name artifacts docker-kernel-rockchip
mkdir -p ./images
docker cp artifacts:/build/kernel-rockchip/kernel.img ./images/kernel.img
docker cp artifacts:/build/kernel-rockchip/resource.img ./images/resource.img
docker cp artifacts:/build/kernel-rockchip/out-modules ./images/modules
# cleanup
docker rm artifacts
```

### Transfer kernel and modules to NanoPC

Run this on your Docker build machine.

```bash
sudo rsync -avzh --rsync-path="sudo rsync" images/kernel.img pi@192.168.2.126:/root/
sudo rsync -avzh --rsync-path="sudo rsync" images/resource.img pi@192.168.2.126:/root/
sudo rsync -avzh --rsync-path="sudo rsync" images/modules/lib/modules/ pi@192.168.2.126:/lib/modules/
```

### Update files on the NanoPC

Run this on the NanoPC.

```bash
sudo chown root:root -R /lib/modules/6.1.57/
sudo -i
cd /root
dd if=resource.img of=/dev/mmcblk2p4 bs=1M
dd if=kernel.img of=/dev/mmcblk2p5 bs=1M
```

## Sources

- [NanoPC-T6 Wiki - How to Compile](https://wiki.friendlyelec.com/wiki/index.php/NanoPC-T6#How_to_Compile)
- [Unlocking secret ThinkPad functionality for emulating USB devices](https://xairy.io/articles/thinkpad-xdci)
  - [Patch #1](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=3551ff7c5cfff4dc27fdcd14fa286edc08d78088)
  - [Patch #2](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=fc85c59b85d111f51b58ecf08485fa74ac5471cd)
  - [Patch #3](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=cf9f7a6ee7b1f53f9ae13da55585b7d16aee2460)