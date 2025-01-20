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

- Right now, I'm using the latest commit of mkosi directly with no patches, so the official nixpkgs patches to fix the hardcoded paths in mkosi aren't being applied. For this reason, you should install qemu and debian-archive-keyring since they will be used from the host for the time being. After I submit the updated patches to nixpkgs, this will no longer be necessary.

- You might encounter apparmor permission issues on newer ubuntu versions, checkout workarounds [here](https://github.com/systemd/mkosi/issues/3265).

Usage
-----

```shell
nix develop -c $SHELL
mkosi --force
```

> Make sure the above command is not run with sudo, as this will clear necessary environment variables set by the nix shell

Run with:

```shell
sudo qemu-system-x86_64 \
  -machine type=q35,smm=on \
  -m 2048M \
  -nographic \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd \
  -drive file=/usr/share/edk2/x64/OVMF_VARS.4m.fd,if=pflash,format=raw \
  -kernel build/tdx-debian
```

> Ubuntu's OVMF firmware is located under a different directory, namely `/usr/share/OVMF`


Current Functionality
---------------------

- [x] Bit-for-bit reproducible/deterministic images
- [x] Uses sysvinit instead of systemd
- [x] Customizable kernel config
- [x] Doesn't use libraries or binaries from host
- [x] Build process doesn't require containerization
- [x] Small image size (<50Mb root partition base size)
- [x] Ultra minimal initramfs
- [ ] Packaged cleanly as a tiny UKI image
- [ ] Linked with a proof of concept flashbots reproducible Debian pkg repo
- [ ] Verification Script
- [ ] Proper CI
- [ ] Contains full functionality of meta-confidential-compute
