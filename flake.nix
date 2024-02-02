{
  description = "Nhost Hasura Auth";

  inputs = {
    nixops.url = "github:nhost/nixops";
    nixpkgs.follows = "nixops/nixpkgs";
    flake-utils.follows = "nixops/flake-utils";
    nix-filter.follows = "nixops/nix-filter";
  };

  outputs = { self, nixops, nixpkgs, flake-utils, nix-filter }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [
          nixops.overlays.default
          (final: prev: {
            nodejs = prev.nodejs-18_x;
          })
        ];

        pkgs = import nixpkgs {
          inherit overlays system;
        };

        nix-src = nix-filter.lib.filter {
          root = ./.;
          include = [
            (nix-filter.lib.matchExt "nix")
          ];
        };

        node_modules = pkgs.stdenv.mkDerivation {
          inherit version;

          pname = "node_modules";

          nativeBuildInputs = with pkgs; [
            nodePackages.pnpm
          ];

          src = nix-filter.lib.filter {
            root = ./.;
            include = [
              ./package.json
              ./pnpm-lock.yaml
            ];
          };

          buildPhase = ''
            pnpm install
          '';

          installPhase = ''
            mkdir -p $out
            cp -r node_modules $out
          '';
        };


        name = "hasura-auth";
        version = "0.0.0-dev";

        buildInputs = [ ];
        nativeBuildInputs = with pkgs; [
          nodePackages.pnpm
        ];
      in
      {
        checks = {
          nixpkgs-fmt = pkgs.runCommand "check-nixpkgs-fmt"
            {
              nativeBuildInputs = with pkgs;
                [
                  nixpkgs-fmt
                ];
            }
            ''
              mkdir $out
              nixpkgs-fmt --check ${nix-src}
            '';

        };

        devShells = flake-utils.lib.flattenTree rec {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              nixpkgs-fmt
              nodejs
              gnumake
            ] ++ buildInputs ++ nativeBuildInputs;

            # shellHook = ''
            #   export PATH=${node_modules}/node_modules/.bin:$PATH
            #   rm -rf node_modules
            #   ln -sf ${node_modules}/node_modules/ node_modules
            # '';
          };
        };
      }
    );
}
