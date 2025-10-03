{
  description = "CCSwarm - Multi-agent orchestration system: declarative and reprodicible package";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      flake-parts,
      nixpkgs,
      rust-overlay,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          lib,
          ...
        }:
        let
          overlays = [ (import rust-overlay) ];
          pkgsWithRust = import nixpkgs {
            inherit system overlays;
          };

          rustToolchain = pkgsWithRust.rust-bin.stable.latest.default.override {
            extensions = [
              "rust-src"
              "rustfmt"
              "clippy"
            ];
          };

          ccswarm = pkgsWithRust.rustPlatform.buildRustPackage rec {
            pname = "ccswarm";
            version = "0.3.7";

            src = pkgsWithRust.fetchFromGitHub {
              owner = "nwiizo";
              repo = "ccswarm";
              rev = "v0.3.7";
              hash = "10rwq77d9bg7gn934hr2pgldhzc68xwidj78wc83hfh8h6ka7qra";
            };

            cargoHash = "sha256-RNHnpQzcG8mwAvO8e5rcrmqIjlZHyqrCGDl98ombBV8=";

            doCheck = false;

            nativeBuildInputs = with pkgsWithRust; [
              pkg-config
              rustToolchain
            ];

            buildInputs =
              with pkgsWithRust;
              [
                openssl
                git
              ]
              ++ lib.optionals pkgsWithRust.stdenv.isDarwin [
                libiconv
              ];

            # Handle workspace structure if needed - will be determined during build

            meta = with lib; {
              description = "Multi-agent orchestration system";
              homepage = "https://github.com/nwiizo/ccswarm";
              license = licenses.mit;
              maintainers = [ ];
              platforms = platforms.unix;
              mainProgram = "ccswarm";
            };
          };
        in
        {
          packages = {
            default = ccswarm;
            ccswarm = ccswarm;
          };

          apps = {
            default = {
              type = "app";
              program = "${ccswarm}/bin/ccswarm";
            };
            ccswarm = {
              type = "app";
              program = "${ccswarm}/bin/ccswarm";
            };
          };

          devShells.default = pkgsWithRust.mkShell {
            buildInputs =
              with pkgsWithRust;
              [
                rustToolchain
                rust-analyzer
                pkg-config
                openssl
                git

                # Additional development tools
                cargo-watch
                cargo-edit
                cargo-audit
              ]
              ++ lib.optionals pkgsWithRust.stdenv.isDarwin [
                libiconv
              ];

            shellHook = ''
              echo "🦀 CCSwarm development environment"
              echo "Rust version: $(rustc --version)"
              echo "Cargo version: $(cargo --version)"
              echo ""
              echo "Available commands:"
              echo "  cargo build --release  # Build CCSwarm"
              echo "  cargo test            # Run tests"
              echo "  cargo clippy          # Run linter"
              echo "  cargo fmt             # Format code"
            '';

            RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
          };

          checks = {
            ccswarm-build = ccswarm;
          };
        };
    };
}
