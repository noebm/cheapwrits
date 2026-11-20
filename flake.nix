{
  description = "WritMaxxer addon for World of Warcraft: Forever";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    in
    {
      packages = nixpkgs.lib.genAttrs systems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          addon = pkgs.stdenvNoCC.mkDerivation {
            pname = "writ-maxxer";
            version = "0.1.0";
            src = ./WritMaxxer;
            dontBuild = true;

            installPhase = ''
              runHook preInstall

              mkdir -p "$out/share/wow-addons/WritMaxxer"
              cp -r ./. "$out/share/wow-addons/WritMaxxer/"

              runHook postInstall
            '';

            passthru = {
              addonDirectories = [ "WritMaxxer" ];
              gameCompatibility = {
                flavor = "forever";
                interface = 16001;
              };
            };

            meta = {
              description = "WritMaxxer for World of Warcraft: Forever";
              platforms = nixpkgs.lib.platforms.all;
            };
          };
        in
        {
          writ-maxxer = addon;
          default = addon;
        }
      );
    };
}
