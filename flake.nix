{
  description = "CheapWrits addon for World of Warcraft: Forever";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    in
    {
      checks = nixpkgs.lib.genAttrs systems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          tests = pkgs.runCommand "cheapwrits-tests" {
            nativeBuildInputs = [ pkgs.lua5_1 ];
            src = ./.;
          } ''
            cd "$src"

            for test in tests/*.lua; do
              if [ "$test" = tests/testing.lua ]; then
                continue
              fi

              echo "Running $test"
              lua "$test"
            done

            touch "$out"
          '';
        }
      );

      packages = nixpkgs.lib.genAttrs systems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          addon = pkgs.callPackage ./package.nix {
            version = self.shortRev or self.dirtyShortRev or "dev";
          };
        in
        {
          cheapwrits = addon;
          default = addon;
        }
      );
    };
}
