# CCSwarm Nix Flake

A reproducible Nix flake that packages the [CCSwarm](https://github.com/nwiizo/ccswarm) multi-agent orchestration system and provides a ready-to-use Rust development environment.

## What You Get
- **Binary packages** for `ccswarm` built from the upstream release (`v0.3.7`) using `rustPlatform.buildRustPackage`
- **`nix run` app** entry so the CLI can be executed directly from the flake
- **Developer shell** with the latest stable Rust toolchain plus common cargo utilities
- **Checks** that build the package to ensure the pinned sources remain reproducible
- **Update helper** script for refreshing the pinned upstream release and hashes

## Quick Start
- Build the CLI and place it in `./result/bin`:
  ```bash
  nix build .#ccswarm
  ```
- Run the packaged binary without installing it system-wide:
  ```bash
  nix run .#ccswarm -- --help
  ```
- Enter the development environment (includes `rustc`, `cargo`, `clippy`, `rustfmt`, `rust-analyzer`, `cargo-watch`, `cargo-edit`, `cargo-audit`, `pkg-config`, `openssl`, `git`):
  ```bash
  nix develop
  ```
  The shell hook prints the available commands and the toolchain versions on entry.

- Validate the flake definitions:
  ```bash
  nix flake check
  ```

## Using This Flake Elsewhere
Reference the flake from another project (replace the path with the location of this repository or a remote URL once published):
```nix
{
  inputs.ccswarm-flake.url = "path:/absolute/path/to/ccswarm-flake";

  outputs = { self, nixpkgs, ccswarm-flake, ... }@inputs:
    let
      system = "x86_64-linux"; # or any supported system
    in {
      packages.${system}.my-app = ccswarm-flake.packages.${system}.ccswarm;
    };
}
```
Every supported system (`x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`) exposes `packages.ccswarm` and a matching `apps.ccswarm` entry.

## Updating the Pinned Release
The `scripts/update_ccswarm_flake.py` helper fetches the latest upstream release, calculates the source hash via `nix-prefetch-url`, and updates `flake.nix` in-place.

```bash
# Requires Python with the `requests` package and access to nix-prefetch-url.
uv run python scripts/update_ccswarm_flake.py
```
After running the script, review the diff, rebuild (`nix build`), and commit the changes.

## Repository Layout
- `flake.nix` – primary flake definition and package derivations
- `flake.lock` – pinned input revisions for reproducibility
- `scripts/` – tooling for maintaining the flake (update helper and Python project metadata)
- `ccswarm-nix-flake-plan.md` – background notes about the packaging approach

## License
This flake is distributed under the same [MIT license](LICENSE) as the upstream CCSwarm project.
