{
  pkgs ? import <nixpkgs> { },
}:

let
  # Input source files
  src = ./.;
  nodeDeps = import ./node-deps.nix { inherit pkgs; };
  inherit (nodeDeps) packageJSON nodeModules;
in
pkgs.stdenv.mkDerivation {
  name = "renegade-solar-co-uk";

  src = builtins.filterSource (
    path: type:
    !(builtins.elem (baseNameOf path) [
      "_site"
      "node_modules"
      ".git"
    ])
  ) src;

  nativeBuildInputs = with pkgs; [
    cacert
    lightningcss
    sass
    yarn
  ];

  configurePhase = ''
    export HOME=$TMPDIR
    rm -rf _site
    mkdir -p _site/style

    cp -r ${nodeModules}/node_modules .
    chmod -R +w node_modules
    cp ${packageJSON} package.json
  '';

  buildPhase = ''
    echo 'Building CSS'
    sass --update src/_scss:_site/css --style compressed

    echo 'Building site'
    yarn --offline eleventy
  '';

  installPhase = ''
    mkdir -p $out
    cp -r _site/* $out/
    rm -rf node_modules _site package.json
  '';
}
