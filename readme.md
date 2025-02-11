Mkosi Debian Proof of Concept
=============================


Prerequisites
-------------

- Nix should be installed and the `nix-command` and `flakes` features should be enabled.
```shell
curl -L https://nixos.org/nix/install | sh
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

- For now, the Debian archive keyring needs to be installed on your computer. This will be fixed in a future update

- You might encounter apparmor permission issues on newer ubuntu versions, checkout workarounds [here](https://github.com/systemd/mkosi/issues/3265).

Usage
-----

```shell
nix develop -c $SHELL
mkosi --force
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
  -drive file=persistent.qcow2,format=qcow2,if=virtio,cache=writeback
```


> Note: Your OVMF firmware may be located under a different directory such as `/usr/share/OVMF`

Developing
----------

<h3>Building the Kernel</h3>

Just running `mkosi` itself will not trigger a kernel build. To rebuild the kernel, run:

```shell
exit # if you're currently in the nix develop shell
nix build --rebuild flake.nix # not needed if you only modified kernel.nix
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

Directory Structure
-------------------

```
.
├── mkosi.conf                # Main mkosi configuration file
├── mkosi.prepare             # Copies nix-generated kernel into the image
├── mkosi.finalize            # Cleans up stray files at the end of the image generation process
├── debloat.conf              # Configuration to remove unnecessary files from the base image
├── env.json.example          # Example environment variable configuration
├── mkosi.skeleton            # Files to be directly copied into all images
│   ├── etc/rcS.d             # Early boot scripts
│   │   ├── S02network        # Minimal network interface and dhcp setup script
│   │   └── S02persistence    # Script to setup /persistent directory
│   └── init                  # Initramfs entrypoint. This is called directly by the kernel
├── scripts                   # Contains helper scripts for building and installing services
│   ├── install_service.sh    # Configures a script from services/ to run on boot with logs
│   └── build_rust_package.sh # Helper script to reproducibly build rust binaries inside chroot
├── services                  # Contains runit service files
│
├── flake.nix                 # Defines a shell environment with fixed deps for mkosi
├── kernel-yocto.config       # Kernel configuration for kernel.nix, copied directly from Yocto
├── kernel.nix                # Nix derivation to reproducibly build the kernel
│
├── buildernet                # Contains all buildernet-specific configuration
│   ├── mkosi.skeleton/etc    # Template files for services, rendered using env.json 
│   ├── render-config.sh      # Renders mustache files using env.json and download rbuilder-bidding
│   ├── buildernet.conf       # Primary configuration file for rbuilder mkosi configuration
│   ├── mkosi.build           # Calls rust build script to build lighthouse, reth, and rbuilder
│   └── mkosi.postinst        # Handles buildernet-specific users/permissions
│
└── devtools                  # Configuration for image development and testing
    ├── devtools.conf         # Primary configuration file for devtools
    └── rcS.d/S00console      # Early boot script for an interactive shell over serial
```