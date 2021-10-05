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

            export MACHINE_NAME="Ender 3 v2: frogamic edition"
            export SOURCE_CODE_URL="github.com/frogamic/Marlin"
            export WEBSITE_URL="https://frogamic.website"
            export DEFAULT_MACHINE_UUID="da578fa1-2049-4beb-95d7-bf0cf1802b2a"

            export STRING_DISTRIBUTION_DATE="$(date '+%Y-%m-%d')"
            export BRANCH="$(${git}/bin/git symbolic-ref -q --short HEAD 2>/dev/null || true)"
            export VERSION="$(${git}/bin/git rev-parse --short HEAD 2>/dev/null || true)"
            if [[ "$(${git}/bin/git diff --stat)" != "" ]]; then
              VERSION="''${VERSION} (dirty)"
            fi

            export DETAILED_BUILD_VERSION="''${BRANCH}-''${VERSION}"

            ./buildroot/bin/generate_version
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
