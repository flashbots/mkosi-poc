FROM ubuntu:25.04

RUN apt-get update && apt-get install -y \
    curl git sudo qemu-system-x86 qemu-utils \
    debian-archive-keyring systemd-boot reprepro xz-utils

RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu && \
    chmod 0440 /etc/sudoers.d/ubuntu

COPY --chown=ubuntu:ubuntu . /home/ubuntu/mkosi
RUN mkdir -p /home/ubuntu/mkosi/mkosi.packages /home/ubuntu/mkosi/mkosi.cache \
        /home/ubuntu/mkosi/mkosi.builddir /home/ubuntu/mkosi/build /nix && \
    chown -R ubuntu:ubuntu /home/ubuntu/mkosi /nix

USER ubuntu
RUN curl -L https://nixos.org/nix/install | sh -s -- --no-daemon && \
    mkdir -p ~/.config/nix ~/.cache/mkosi/ && \
    echo 'experimental-features = nix-command flakes' > ~/.config/nix/nix.conf

WORKDIR /home/ubuntu/mkosi
RUN /home/ubuntu/.nix-profile/bin/nix develop -c /bin/true
ENTRYPOINT ["/home/ubuntu/.nix-profile/bin/nix", "develop", "-c", "/bin/bash"]