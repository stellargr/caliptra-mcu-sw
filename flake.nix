{
  description = "An empty flake template that you can adapt to your own environment";

  # Flake inputs
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # Unstable Nixpkgs (choose 0 for stable)
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  # Flake outputs
  outputs =
    { self, rust-overlay, ... }@inputs:
    let
      # The systems supported for this flake's outputs
      supportedSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        "aarch64-linux" # 64-bit ARM Linux
        "x86_64-darwin" # 64-bit Intel macOS
        "aarch64-darwin" # 64-bit ARM macOS
      ];

      overlays = [ (import rust-overlay) ];

      # Helper for providing system-specific attributes
      forEachSupportedSystem =
        f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {

            # Provides a system-specific, configured Nixpkgs
            pkgs = import inputs.nixpkgs {
              inherit system overlays;
              # Enable using unfree packages
              config.allowUnfree = true;
            };
          }
        );
    in
    {
      # Development environments output by this flake
      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          # Run `nix develop` to activate this environment or `direnv allow` if you have direnv installed
          default = pkgs.mkShell {
            # Disable nix hardening flags that conflict with third-party C
            # builds (e.g. spdm-emu): _FORTIFY_SOURCE requires -O,
            # -Werror=format-security conflicts with -Wno-format, etc.
            hardeningDisable = [ "all" ];

            # The Nix packages provided in the environment
            packages = with pkgs; [
              gdb
              picocom
              openssl
              udev
              pkg-config
              cargo-binutils
              cmake
              gnumake
              (rust-bin.fromRustupToolchainFile ./rust-toolchain.toml)
            ];

            # Set any environment variables for your development environment
            env = { };

            # Add any shell logic you want executed when the environment is activated
            shellHook = ''
              # Override the GNU objcopy set by nix stdenv; the firmware builder
              # needs llvm-objcopy for its --strip-sections flag.
              export OBJCOPY=llvm-objcopy
            '';
          };
        }
      );
    };
}
