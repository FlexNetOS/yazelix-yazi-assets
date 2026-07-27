# yazi-bistro

A curated tasting menu of complete dark and light
[Yazi flavors](https://yazi-rs.github.io/docs/flavors/overview/)

The catalog grew out of Yazelix but is packaged for any Yazi user. Each flavor
is pinned to an upstream revision and includes `flavor.toml`, `tmtheme.xml`,
`LICENSE`, and `LICENSE-tmtheme`. `catalog.toml` records provenance, license,
and dark/light classification.

Bluloco Light is the catalog's recommended light default. The collection is
deliberately broader than its defaults: a flavor may be expressive or
opaque-backed and still belong in the catalog when it is compatible, complete,
licensed, distinct, and readable in its intended mode.

## Nix

Build the complete catalog:

```sh
nix build
```

Build one flavor:

```sh
nix build .#bluloco-light
```

The aggregate package installs flavor directories and the catalog under:

```text
share/yazi-flavors/
```

With Home Manager, select any individual package:

```nix
programs.yazi = {
  enable = true;
  flavors = {
    inherit (inputs.yazi-bistro.packages.${pkgs.system})
      bluloco-light
      dracula;
  };
  theme.flavor = {
    dark = "dracula";
    light = "bluloco-light";
  };
};
```

## Inclusion policy

A flavor is included only when:

- its pinned package parses with the catalog's current Yazi validation target;
- its runtime theme and syntax theme are complete and carry usable licenses;
- its upstream revision and source path are reproducible;
- its intended mode remains readable across Yazi's main surfaces;
- it contributes a distinct option without repository-local theme patches.

Popularity, a matching dark/light companion, active development, and terminal
background transparency are not catalog requirements. Defaults use a stricter
bar for contrast, transparency, broad appeal, provenance, and fit with the
surrounding runtime.

## LOC scorecard

Counts tracked text files and excludes `flake.lock`.

| Language | Lines |
| --- | ---: |
| Nix | 116 |
| TOML | 4,763 |
| XML syntax themes | 26,335 |
| Markdown | 141 |
| Licenses | 1,694 |
| Ignore files | 4 |
| Total | 33,053 |
