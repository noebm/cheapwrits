{
  description = "WritMaxxer addon for World of Warcraft: Forever";

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
      packages = nixpkgs.lib.genAttrs systems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          addon = pkgs.stdenvNoCC.mkDerivation {
            pname = "writ-maxxer";
            version = self.shortRev or self.dirtyShortRev or "dev";
            src = ./WritMaxxer;
            dontBuild = true;

            installPhase = ''
              runHook preInstall

              mkdir -p "$out/share/wow-addons/WritMaxxer"
              cp -r ./. "$out/share/wow-addons/WritMaxxer/"
              substituteInPlace "$out/share/wow-addons/WritMaxxer/WritMaxxer.toc" \
                --replace-fail '## Version: dev' "## Version: $version"

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
