{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskell-flake.url = "github:srid/haskell-flake";
    direct-sqlcipher = {
      url = "git+https://github.com/simplex-chat/direct-sqlcipher?tag=f814ee68b16a9447fbb467ccc8f29bdd3546bfd9";
      flake = false;
    };
    sqlcipher-simple = {
      url = "https://github.com/simplex-chat/sqlcipher-simple?tag=a46bd361a19376c5211f1058908fc0ae6bf42446";
      flake = false;
    };
    aeson = {
      url = "git+https://github.com/simplex-chat/aeson?tag=aab7b5a14d6c5ea64c64dcaee418de1bb00dcc2b";
      flake = false;
    };
    hs-socks = {
      url = "git+https://github.com/simplex-chat/hs-socks?tag=a30cc7a79a08d8108316094f8f2f82a0c5e1ac51";
      flake = false;
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-linux" ];
      imports = [
        inputs.haskell-flake.flakeModule
      ];
      perSystem = { self', system, lib, config, pkgs, ... }: {
        haskellProjects.default = {
          # basePackages = pkgs.haskellPackages;
          projectRoot = ./.;
          defaults.enable = true;

          # Packages to add on top of `basePackages`, e.g. from Hackage
          packages = {
            aeson.source = inputs.aeson;
            direct-sqlcipher.source = inputs.direct-sqlcipher;
            sqlcipher-simple.source = inputs.sqlcipher-simple;
            hs-socks.source = inputs.hs-socks;
          };
          settings = {
            sqlcipher-simple = {
              extraTestToolDepends = [ pkgs.sqlcipher ];
            };
          };

          # my-haskell-package development shell configuration
          devShell = {
            hlsCheck.enable = false;
          };

          # What should haskell-flake add to flake outputs?
          autoWire = [ "packages" "apps" "checks" ]; # Wire all but the devShell
        };

        devShells.default = pkgs.mkShell {
          name = "simplexmq development shell";
          inputsFrom = [
            config.haskellProjects.default.outputs.devShell
          ];
          nativeBuildInputs = with pkgs; [
            # other development tools.
          ];
        };
      };
    };
}
