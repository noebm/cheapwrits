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
  pname = "cheapwrits";
  version = package-version;
  src = ./CheapWrits;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/wow-addons/CheapWrits"
    cp -r ./. "$out/share/wow-addons/CheapWrits/"
    substituteInPlace "$out/share/wow-addons/CheapWrits/CheapWrits.toc" \
      --replace-fail '## Version: dev' "## Version: $version"

    runHook postInstall
  '';

  passthru = {
    addonDirectories = [ "CheapWrits" ];
    gameCompatibility = {
      flavor = "forever";
      interface = 16001;
    };
  };

  meta = {
    description = "CheapWrits for World of Warcraft: Forever";
    platforms = lib.platforms.all;
  };
}
