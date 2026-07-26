{
  description = "Yazi Bistro: curated complete Yazi flavor packages";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    eachSystem = nixpkgs.lib.genAttrs systems;
    catalog = builtins.fromTOML (builtins.readFile ./catalog.toml);
    flavorNames = builtins.attrNames catalog.flavors;
    validModes =
      builtins.all
      (name: builtins.elem catalog.flavors.${name}.mode ["dark" "light"])
      flavorNames;
  in
    assert catalog.schema_version == 1;
    assert validModes;
    assert catalog.flavors.${catalog.default_light}.mode == "light"; {
      lib = {
        inherit catalog flavorNames;
        defaultLight = catalog.default_light;
      };

      packages = eachSystem (
        system: let
          pkgs = import nixpkgs {inherit system;};
          flavorPackages =
            builtins.mapAttrs (
              name: metadata:
                pkgs.runCommand "yazi-flavor-${name}" {
                  meta = {
                    description = "${name} flavor for Yazi";
                    license =
                      if metadata.license == "LGPL-3.0-only"
                      then pkgs.lib.licenses.lgpl3Only
                      else pkgs.lib.licenses.mit;
                    platforms = systems;
                  };
                } ''
                  cp -R ${./flavors + "/${name}.yazi"} "$out"
                  for file in flavor.toml tmtheme.xml LICENSE LICENSE-tmtheme; do
                    test -s "$out/$file"
                  done
                ''
            )
            catalog.flavors;
          bundle =
            pkgs.runCommand "yazi-flavors" {
              meta = {
                description = "Curated complete dark and light Yazi flavor packages";
                license = [
                  pkgs.lib.licenses.mit
                  pkgs.lib.licenses.lgpl3Only
                ];
                platforms = systems;
              };
            } ''
                root="$out/share/yazi-flavors"
                mkdir -p "$root/flavors"
                install -m 644 ${./catalog.toml} "$root/catalog.toml"
                ${pkgs.lib.concatMapStringsSep "\n" (
                  name: ''ln -s ${flavorPackages.${name}} "$root/flavors/${name}.yazi"''
                )
                flavorNames}
              test "$(find "$root/flavors" -mindepth 1 -maxdepth 1 -type l | wc -l | tr -d ' ')" = "${
                toString (builtins.length flavorNames)
              }"
            '';
        in
          flavorPackages
          // {
            default = bundle;
          }
      );

      checks = eachSystem (
        system: let
          pkgs = import nixpkgs {inherit system;};
          bundle = self.packages.${system}.default;
        in {
          catalog = bundle;
          yazi =
            pkgs.runCommand "yazi-flavor-compatibility" {
              nativeBuildInputs = [
                pkgs.libxml2
                pkgs.yazi
              ];
            } ''
              export HOME="$TMPDIR/home"
              mkdir -p "$HOME"
              for flavor_path in ${bundle}/share/yazi-flavors/flavors/*.yazi; do
                flavor_dir="''${flavor_path##*/}"
                flavor="''${flavor_dir%.yazi}"
                config="$TMPDIR/$flavor"
                mkdir -p "$config/flavors"
                ln -s "$flavor_path" "$config/flavors/$flavor_dir"
                xmllint --noout "$flavor_path/tmtheme.xml"
                printf '[flavor]\ndark = "%s"\nlight = "%s"\n' \
                  "$flavor" "$flavor" > "$config/theme.toml"
                YAZI_CONFIG_HOME="$config" yazi --debug > "$config/debug"
                grep -q "Dark/light flavor:.*$flavor" "$config/debug"
              done
              touch "$out"
            '';
        }
      );
    };
}
