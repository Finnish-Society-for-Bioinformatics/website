{
  description = "A Nix-flake-based R development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs

  outputs =
    { self, ... }@inputs:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            inherit system;
            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [ inputs.self.overlays.default ];
            };
          }
        );
    in
    {
      overlays.default = final: prev: rec {
        rEnv = final.rWrapper.override {
          packages = with final.rPackages; [
            knitr
            languageserver
          ];
        };
      };

      devShells = forEachSupportedSystem (

        { pkgs, system }:
        let
          patchedQuarto = pkgs.quarto.overrideAttrs (oldAttrs: {
            postPatch = (oldAttrs.postPatch or "") + ''
              substituteInPlace bin/quarto.js \
                --replace-fail "syntax-highlighting" "highlight-style"
            '';
          });
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              rEnv
              patchedQuarto
              self.formatter.${system}
            ];
          };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);
    };
}
