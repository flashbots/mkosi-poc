{ pkgs ? import <nixpkgs> {} }:
pkgs.stdenv.mkDerivation rec {
  pname = "linux-tdx";
  version = "6.13.1";

  depsBuildBuild = with pkgs.pkgsBuildBuild; [
    stdenv.cc
  ];

  nativeBuildInputs = with pkgs.buildPackages; [
    git flex bison elfutils openssl
    bc perl gawk zstd
  ];

  src = pkgs.fetchFromGitHub {
    owner = "gregkh";
    repo = "linux";
    rev = "v${version}";
    sha256 = "sha256-eiceHrOC2K2nBEbs7dD9AfpCNesorMhC9X24UtSPkMY=";
  };

  # patches = [];

  configurePhase = ''cp ${./kernel-yocto.config} .config'';

  buildPhase = ''
    patchShebangs ./scripts/ld-version.sh
    export KBUILD_BUILD_TIMESTAMP="$(date -u -d @$SOURCE_DATE_EPOCH)"
    export KBUILD_BUILD_USER="nixbuild"
    export KBUILD_BUILD_HOST="nixbuilder"
    make olddefconfig bzImage -j "$NIX_BUILD_CORES" \
      ARCH="x86_64" \
      HOSTCC="$CC_FOR_BUILD" \
      HOSTCXX="$CXX_FOR_BUILD" \
      HOSTAR="$AR_FOR_BUILD" \
      HOSTLD="$LD_FOR_BUILD" \
      CC="$CC" LD="$LD" \
      OBJCOPY="$OBJCOPY" \
      OBJDUMP="$OBJDUMP" \
      READELF="$READELF" \
      STRIP="$STRIP" \
      CONFIG_EFI_STUB=y
  '';

  installPhase = ''
    mkdir -p $out
    cp arch/x86_64/boot/bzImage $out/
  '';

  meta = {
    description = "Linux Kernel ${version}";
    homepage = https://kernel.org;
    license = "gpl2Only";
  };
}