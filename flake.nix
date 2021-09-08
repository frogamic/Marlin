{
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = {self, nixpkgs, flake-utils, ...}:
    flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux"] (system:
    let pkgs = nixpkgs.legacyPackages.${system}; in
    {
      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [
          platformio
        ];
      };
    });
}
