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
- `config_metadata/yazi_assets_manifest.toml` declares the packaged asset shape for consumers that need a stable manifest
- `config_metadata/yazi_render_plan.toml` and `config_templates/` feed the Rust config-pack renderer

Yazelix-specific sidebar/editor orchestration plugins remain in the main Yazelix repository because they depend on the managed pane/session contract

ccboard and CodeDB are mandatory Foundation runtime tooling, not Yazi `.yazi` Lua plugins. `yazi_assets_only` (and `default`) provides the portable asset/configuration layer on every advertised platform. Linux `yazelix_yazi_assets` composes that same layer with the runtime tools, while `yazi_runtime_tools` exposes the full Linux composition for runtime consumers. The CodeDB sandbox is never weakened or emulated on Darwin.

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

The portable layer contains `flavors/`, `plugins/`, `config_templates/`, `yazelix_starship.toml`, and `config_metadata/`. Linux `yazelix_yazi_assets` additionally contains `runtime_tools/`.

## Rust

The `yazelix_yazi_assets` crate exposes pure render-plan and config-pack functions:

```rust
use yazelix_yazi_assets::{
    YaziConfigPackRenderRequest, YaziConfigPackTemplates, compute_yazi_render_plan,
    render_yazi_config_pack,
};
```

The crate renders file contents from explicit inputs. It does not read user config paths, generated state directories, host environment variables, or a Yazelix checkout
