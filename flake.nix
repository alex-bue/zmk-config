{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Keep this aligned with the Zephyr revision imported by ZMK v0.3.
    zephyr.url = "github:zmkfirmware/zephyr/v3.5.0+zmk-fixes";
    zephyr.flake = false;

    zephyr-nix.url = "github:nix-community/zephyr-nix";
    zephyr-nix.inputs.zephyr.follows = "zephyr";
    zephyr-nix.inputs.nixpkgs.follows = "nixpkgs";

    zmk-helpers.url = "github:urob/zmk-helpers/v0.3";
    zmk-helpers.flake = false;

    pin-west.url = "github:urob/pin-west";
    pin-west.flake = false;
  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          zephyr = inputs.zephyr-nix.packages.${system};
          pin-west = pkgs.python3Packages.callPackage "${inputs.pin-west}/package.nix" { };
        in
        {
          default = pkgs.mkShellNoCC {
            packages = [
              zephyr.pythonEnv
              (zephyr.sdk-0_16.override { targets = [ "arm-zephyr-eabi" ]; })

              pkgs.cmake
              pkgs.dtc
              pkgs.gcc
              pkgs.git
              pkgs.ninja

              pkgs.just
              pkgs.keymap-drawer
              pkgs.yq
              pin-west
            ];

            env = {
              PYTHONPATH = "${zephyr.pythonEnv}/${zephyr.pythonEnv.sitePackages}";
            };

            shellHook = ''
              mkdir -p .nix
              ln -sfn ${inputs.zmk-helpers} .nix/zmk-helpers

              export ZMK_BUILD_DIR="$(pwd)/.build"
              export ZMK_SRC_DIR="$(pwd)/zmk/app"
            '';
          };
        }
      );
    };
}
