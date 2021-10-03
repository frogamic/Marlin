{
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = {self, nixpkgs, flake-utils, ...}: let
    platform = "BIGTREE_SKR_2_USB";
    host = "nammu";
    printer = "ender3v2";
  in
    flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux"] (system:
    let pkgs = nixpkgs.legacyPackages.${system}; in
    {
      devShell = pkgs.mkShell {
        buildInputs = with pkgs; let
          git-root = "$(${git}/bin/git rev-parse --show-toplevel)";
        in [
          platformio
          (writeShellScriptBin "build" ''
            cd "${git-root}"
            BUILD_INFO="$(${git}/bin/git rev-parse --short HEAD)"
            if [[ "$(${git}/bin/git diff --stat)" != "" ]]; then
              BUILD_INFO="''${BUILD_INFO} (dirty)"
            fi
            echo "#define DETAILED_BUILD_VERSION \"''${BUILD_INFO}\"" > Marlin/Buildinfo.h
            ${platformio}/bin/pio run -e ${platform}
          '')
          (writeShellScriptBin "push" ''
            cd "${git-root}"
            ${openssh}/bin/scp ".pio/build/${platform}/firmware.bin" \
              ${host}:/mnt/${printer}/
          '')
          (writeShellScriptBin "deploy" ''
            ${openssh}/bin/ssh ${host} 'echo M997 > /dev/${printer}'
          '')
        ];
      };
    });
}
