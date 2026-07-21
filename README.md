# yazelix-yazi-assets

Standalone Yazi flavor, plugin, and runtime tool assets extracted from Yazelix

This repository exists for non-Yazelix users who want the reusable Yazi pieces without adopting the full Yazelix runtime. Regular Yazelix users do not need to install or configure this package directly; Yazelix wires it into the managed runtime

## Contents

- `flavors/` contains the bundled Yazelix Yazi flavor catalog
- `plugins/git.yazi/`, `plugins/lazygit.yazi/`, and `plugins/starship.yazi/` contain reusable Yazi plugins with their upstream license files
- `plugins/auto-layout.yazi/` contains the Yazelix-maintained Yazi auto-layout helper
- `plugins/smart-tabs.yazi/` contains the Yazelix-maintained smart tab helper
- Linux `yazelix_yazi_assets` additionally carries the ccboard CLI and the sandboxed CodeDB CLI plus `nu_plugin_codedb`; these mandatory Foundation tools remain separate from portable Yazi assets because CodeDB's upstream Bubblewrap sandbox is Linux-only
- `yazelix_starship.toml` contains the Starship prompt config used by the Yazi integration
- `config_metadata/yazi_assets_manifest.toml` declares the portable asset shape (no runtime-tool claims); the Linux composition additionally ships `config_metadata/yazi_runtime_tools_manifest.toml` for the ccboard/CodeDB runtime tools
- `config_metadata/yazi_render_plan.toml` and `config_templates/` feed the Rust config-pack renderer

Yazelix-specific sidebar/editor orchestration plugins remain in the main Yazelix repository because they depend on the managed pane/session contract

ccboard and CodeDB are mandatory Foundation runtime tooling, not Yazi `.yazi` Lua plugins. `yazi_assets_only` (and `default`) provides the portable asset/configuration layer on every advertised platform; its `config_metadata/yazi_assets_manifest.toml` sets `runtime_tools_available = false` and makes no runtime-tool claims. Linux `yazelix_yazi_assets` is the single full Linux owner: it composes that same portable layer with the runtime tools and adds `config_metadata/yazi_runtime_tools_manifest.toml` (`runtime_tools_available = true`) plus the per-tool descriptors. The CodeDB sandbox is never weakened or emulated on Darwin.

## Nix

Build the package:

```bash
nix build .#yazelix_yazi_assets
```

For the portable, cross-platform asset layer, use:

```bash
nix build .#yazi_assets_only
```

Regenerate the checked-in Starship config:

```bash
cargo run --bin generate_yazelix_starship > yazelix_starship.toml
```

The package installs assets under:

```text
share/yazelix_yazi_assets/
```

The portable layer contains `flavors/`, `plugins/`, `config_templates/`, `yazelix_starship.toml`, and a portable `config_metadata/` (no runtime-tool descriptors). Linux `yazelix_yazi_assets` additionally contains `runtime_tools/` plus the runtime-tool descriptors and `yazi_runtime_tools_manifest.toml` under `config_metadata/`.

## LOC scorecard

The reproducible tracked-text scorecard excludes lockfiles, Beads issues, and
binary assets. Regenerate with:

```bash
{ git ls-files; git ls-files --others --exclude-standard; } | sort -u \
  | grep -vE '(^|/)\.beads/|\.lock$' \
  | while read -r f; do [ -f "$f" ] && grep -Iq . "$f" && wc -l "$f"; done \
  | awk '{t+=$1} END{print t}'
```

| Surface | Lines |
| --- | ---: |
| TOML (flavors, config templates, manifests) | 5,194 |
| Rust (render-plan / config-pack crate) | 1,054 |
| Lua (Yazi plugins) | 940 |
| Markdown (docs) | 567 |
| Vendored plugin patch | 310 |
| Nix (flake) | 270 |
| Licenses / other tracked text | 300 |
| **Total tracked text** | **8,635** |

## Rust

The `yazelix_yazi_assets` crate exposes pure render-plan and config-pack functions:

```rust
use yazelix_yazi_assets::{
    YaziConfigPackRenderRequest, YaziConfigPackTemplates, compute_yazi_render_plan,
    render_yazi_config_pack,
};
```

The crate renders file contents from explicit inputs. It does not read user config paths, generated state directories, host environment variables, or a Yazelix checkout
