{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    kernel = import ./kernel.nix { inherit pkgs; };
    mkosi = pkgs.mkosi;
    reprepro = pkgs.stdenv.mkDerivation rec {
      name = "reprepro-${version}";
      version = "4.16.0";

      src = pkgs.fetchurl {
        url = "https://alioth.debian.org/frs/download.php/file/"
            + "4109/reprepro_${version}.orig.tar.gz";
        sha256 = "14gmk16k9n04xda4446ydfj8cr5pmzsmm4il8ysf69ivybiwmlpx";
      };

      nativeBuildInputs = [ pkgs.makeWrapper ];
      buildInputs = pkgs.lib.singleton (pkgs.gpgme.override { gnupg = pkgs.gnupg; })
                ++ (with pkgs; [ db libarchive bzip2 xz zlib ]);

      postInstall = ''
        wrapProgram "$out/bin/reprepro" --prefix PATH : "${pkgs.gnupg}/bin"
      '';
    };
  in {
    packages.${system} = {
      kernel = kernel;
      default = kernel;
    };

    devShells.${system}.default = pkgs.mkShell {
      nativeBuildInputs = with pkgs; [
        apt dpkg gnupg debootstrap
        squashfsTools dosfstools e2fsprogs mtools mustache-go
        cryptsetup util-linux zstd qemu
      ] ++ [ reprepro mkosi ];

      KERNEL_IMAGE = "${kernel}/bzImage";
      KERNEL_VERSION = kernel.version;

      shellHook = ''
        mkdir -p mkosi.packages mkosi.cache mkosi.builddir
      '';
    };
  };
}