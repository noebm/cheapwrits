{
  lib,
  stdenvNoCC,
  version ? "dev",
  releaseTag ? "",
}:
let
  releaseVersion = lib.removePrefix "v" releaseTag;
  package-version =
    if releaseTag == "" then
      version
    else if
      builtins.match "[0-9]+\\.[0-9]+\\.[0-9]+(-[0-9A-Za-z.-]+)?(\\+[0-9A-Za-z.-]+)?" releaseVersion
      != null
    then
      releaseVersion
    else
      throw "Expected a release tag such as v0.1.0 or v0.1.0-rc.1";
in
stdenvNoCC.mkDerivation {
  pname = "writ-maxxer";
  version = package-version;
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
    platforms = lib.platforms.all;
  };
}
