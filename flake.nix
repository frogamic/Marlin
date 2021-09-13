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
        buildInputs = with pkgs; [
          platformio
          (writeShellScriptBin "build" ''
            ${platformio}/bin/pio run -e ${platform}
          '')
          (writeShellScriptBin "push" ''
            ${openssh}/bin/scp $(${git}/bin/git rev-parse --show-toplevel)/.pio/build/${platform}/firmware.bin \
              ${host}:/mnt/${printer}/
          '')
          (writeShellScriptBin "deploy" ''
            ${openssh}/bin/ssh ${host} 'echo M997 > /dev/${printer}'
          '')
        ];
      };
    });
}
