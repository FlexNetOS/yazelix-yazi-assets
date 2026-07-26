# Agent Guidelines

Shared Yazelix agent workflow and release policy live in the main repo:

- https://github.com/luccahuguet/yazelix/blob/main/AGENTS.md
- In sibling local checkouts, read `../yazelix/AGENTS.md` first

Only Yazi flavor catalog-specific guidance belongs here.

## Local Scope

- This repo owns a curated collection of complete Yazi flavor packages and
  their provenance and dark/light classification.
- Main Yazelix owns managed Yazi plugins, prompt configuration, launch-time
  appearance projection, and session policy.
- Preserve each upstream flavor and tmTheme license when refreshing packages.
- Do not patch incompatible or ambiguously licensed flavors into the catalog.

## Local Commands

- `nix flake check`
- `nix build --no-link`

## Integration Notes

Main Yazelix consumes the catalog package through its flake input.
