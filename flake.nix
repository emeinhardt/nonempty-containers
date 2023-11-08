{
  description = "A Haskell package for nonempty-containers.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        compiler = "ghc928";

        haskellPackages = pkgs.haskell.packages."${compiler}";

        jailbreakUnbreak = pkg:
          pkgs.haskell.lib.doJailbreak (pkg.overrideAttrs (_: { meta = { }; }));

        overlay = self: super: {
          nonempty-containers-alt  = self.callCabal2nix "nonempty-containers-alt"  ./nonempty-containers-alt  { };
          nonempty-containers-test = self.callCabal2nix "nonempty-containers-test" ./nonempty-containers-test { };
        };
        haskellPackages' = haskellPackages.extend overlay;

      in {

        packages = {
          inherit (haskellPackages') nonempty-containers-alt nonempty-containers-test;
          default = haskellPackages'.nonempty-containers-alt;
        };
        defaultPackage = self.packages.${system}.default;

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [

            cabal-install

            haskellPackages'.haskell-language-server

            haskellPackages'.hlint

          ];
          inputsFrom = map (__getAttr "env") (__attrValues self.packages.${system});
        };
        devShell = self.devShells.${system}.default;

      });
}

