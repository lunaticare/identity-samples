{
  description = "My Android app";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";
    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs/stable";
    };
    gradle2nix.url = "github:lunaticare/gradle2nix?ref=feature/build_android_app";
  };

  outputs = { self, nixpkgs, flake-compat, flake-utils, android-nixpkgs, systems
    , gradle2nix, }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        android-sdk = android-nixpkgs.sdk.${system} (sdkPkgs:
          with sdkPkgs; [
            cmdline-tools-latest
            build-tools-33-0-1
            platform-tools
            platforms-android-34
            sources-android-34
            system-images-android-34-google-apis-playstore-arm64-v8a
            emulator
          ]);
        jdk = pkgs.temurin-bin-17;
        android-app = gradle2nix.builders.${system}.buildGradlePackage {
          pname = "android-app";
          version = "1.0";
          lockFile = ./gradle.lock;
          gradleFlags = [ "build" "--stacktrace" "--info" ];
          src = ./.;
          extraBuildInputs = [
            android-sdk
          ];
          postBuild = ''
          mkdir -p $out
          cp -r app/build/outputs/apk $out
          '';
        };
      in {
        packages.android-sdk = android-sdk;
        packages.default = pkgs.hello;
        packages.android-app = android-app;
        devShells.default = pkgs.mkShell {
          packages = [ android-sdk jdk ];
          shellHook = ''
            unset JAVA_HOME
            unset JAVA

            echo Welcome to Android shell!
          '';
        };
      });
}
