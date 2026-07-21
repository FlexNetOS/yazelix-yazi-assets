# Changelog

## Unreleased

- Split the Yazi asset outputs into a truly portable layer and a Linux full
  composition. `yazi_assets_only` (and `default`) now carries only
  cross-platform flavors, plugins, config templates, and a portable
  `yazi_assets_manifest.toml` that sets `runtime_tools_available = false` and
  makes no runtime-tool claims.
- Move the ccboard and CodeDB runtime-tool descriptors and the new
  `yazi_runtime_tools_manifest.toml` (`runtime_tools_available = true`) into the
  Linux-only composition, so the portable layer no longer advertises tooling it
  does not ship.
- Constrain the Linux `yazelix_yazi_assets` composition's `meta.platforms` to
  Linux instead of inheriting the all-platform portable metadata.
- Remove the duplicate `yazi_runtime_tools` package output. `yazi_assets_only`
  is the single portable owner and `yazelix_yazi_assets` is the single full
  Linux owner; both expose the same underlying assets without duplication.
- Add `checks.<system>.portable_closure_isolation`, which inspects the portable
  derivation's Nix closure graph and fails if ccboard, CodeDB, `nu_plugin_codedb`,
  or Bubblewrap ever appear — a real cross-platform isolation contract rather
  than a bare evaluation check.
- Extend `asset_shape` and `runtime_tool_shape` checks to prove portable-manifest
  accuracy and Linux runtime-tool availability, and add the first README LOC
  scorecard for this repository.
