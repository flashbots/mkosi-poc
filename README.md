Mkosi Debian Proof of Concept
=============================


Prerequisites
-------------

- Nix should be installed (single user mode is sufficient) and the `nix-command` and `flakes` features should be enabled.
```
sh <(curl -L https://nixos.org/nix/install) --no-daemon
nix --extra-experimental-features nix-command develop --extra-experimental-features flakes -c $SHELL
```

- For now, the Debian archive keyring needs to be installed on your computer. This will be fixed in a future update

```shell
sudo apt update
sudo apt install -y debian-archive-keyring
```

- Install QEMU and utilities:

```shell
sudo apt update
sudo apt install -y qemu-system-x86 qemu-utils
```

- Create the mkosi cache directory:

```shell
mkdir -p ~/.cache/mkosi
```

Usage
-----

```shell
nix develop -c $SHELL
mkosi --force -I buildernet.conf
```

> Note: Make sure the above command is not run with sudo, as this will clear necessary environment variables set by the nix shell

Create a qcow2 image to store persistent files:

```shell
qemu-img create -f qcow2 persistent.qcow2 2048G
```

Run with:

```shell
sudo qemu-system-x86_64 \
  -enable-kvm \
  -machine type=q35,smm=on \
  -m 16384M \
  -nographic \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd \
  -drive file=/usr/share/edk2/x64/OVMF_VARS.4m.fd,if=pflash,format=raw \
  -kernel build/tdx-debian \
  -netdev user,id=net0 \
  -device virtio-net-pci,netdev=net0 \
  -device virtio-scsi-pci,id=scsi0 \
  -drive file=persistent.qcow2,format=qcow2,if=none,id=disk0 \
  -device scsi-hd,drive=disk0,bus=scsi0.0,channel=0,scsi-id=0,lun=10
```

Developing
----------

<h3>Building the Kernel</h3>

Just running `mkosi` itself will not trigger a kernel build. To rebuild the kernel, run:

```shell
exit # if you're currently in the nix develop shell
nix-build kernel.nix # not needed if you only modified kernel.nix
nix develop -c $SHELL
```

> Note: Changing the kernel version requires updating the sha256 checksum in `kernel.nix` 

<h3>Mkosi Debugging</h3>

To debug the mkosi environment, insert the following line in the mkosi script where you want to break:
```shell
socat UNIX-LISTEN:$SRCDIR/debug.sock,fork EXEC:/bin/bash,pty,stderr
```

Then, once the breakpoint is hit, you can get a shell on your computer with:
```shell
script -qfc "socat STDIO UNIX-CONNECT:debug.sock" /dev/null
```

From here, you can run `mkosi-chroot /bin/bash` to get inside Debian
