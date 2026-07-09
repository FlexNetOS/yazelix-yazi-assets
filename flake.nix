{
  description = "Standalone Yazi flavor, plugin, and runtime tool assets from Yazelix";

  inputs = {
    codedbNuPlugin = {
      url = "github:FlexNetOS/nu_plugin?rev=532a461841316a6623701f9e206b97cafa994d40";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ccboardSource = {
      url = "github:FlexNetOS/ccboard?rev=fc41394e447ca02080324796fcf563ebbb7727be";
      flake = false;
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      ccboardSource,
      codedbNuPlugin,
      nixpkgs,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          ccboardPackage = pkgs.rustPlatform.buildRustPackage {
            pname = "ccboard";
            version = "0.24.0";
            src = ccboardSource;
            cargoLock.lockFile = "${ccboardSource}/Cargo.lock";
            cargoBuildFlags = [
              "--package"
              "ccboard"
            ];
            doCheck = false;
          };
          codedbRuntimeTools = codedbNuPlugin.packages.${system}.codedb_runtime_tools;

          assets = pkgs.stdenvNoCC.mkDerivation {
            pname = "yazelix_yazi_assets";
            version = "0.1.0";
            src = pkgs.lib.cleanSource ./.;

            dontConfigure = true;
            dontBuild = true;

            installPhase = ''
              runHook preInstall

              install_root="$out/share/yazelix_yazi_assets"
              mkdir -p "$install_root"

              cp -R flavors "$install_root/flavors"
              cp -R plugins "$install_root/plugins"
              mkdir -p "$install_root/runtime_tools/ccboard/bin"
              ln -s "${ccboardPackage}/bin/ccboard" "$install_root/runtime_tools/ccboard/bin/ccboard"
              cat > "$install_root/runtime_tools/ccboard/runtime-tool-metadata.json" <<EOF
{"schema_version":1,"name":"ccboard","kind":"runtime-tool","source_repo":"https://github.com/FlexNetOS/ccboard","source_rev":"fc41394e447ca02080324796fcf563ebbb7727be","commands":["ccboard"]}
EOF
              mkdir -p "$install_root/runtime_tools/codedb/bin"
              ln -s "${codedbRuntimeTools}/bin/codedb" "$install_root/runtime_tools/codedb/bin/codedb"
              ln -s "${codedbRuntimeTools}/bin/nu_plugin_codedb" "$install_root/runtime_tools/codedb/bin/nu_plugin_codedb"
              install -Dm644 "${codedbRuntimeTools}/share/codedb/runtime-tool-metadata.json" "$install_root/runtime_tools/codedb/runtime-tool-metadata.json"
              cp -R config_templates "$install_root/config_templates"
              install -Dm644 yazelix_starship.toml "$install_root/yazelix_starship.toml"
              install -Dm644 README.md "$out/share/doc/yazelix_yazi_assets/README.md"
              install -Dm644 LICENSE "$out/share/doc/yazelix_yazi_assets/LICENSE"
              install -Dm644 config_metadata/ccboard_runtime_tool.toml "$out/share/yazelix_yazi_assets/config_metadata/ccboard_runtime_tool.toml"
              install -Dm644 config_metadata/codedb_runtime_tool.toml "$out/share/yazelix_yazi_assets/config_metadata/codedb_runtime_tool.toml"
              install -Dm644 config_metadata/yazi_assets_manifest.toml "$out/share/yazelix_yazi_assets/config_metadata/yazi_assets_manifest.toml"
              install -Dm644 config_metadata/yazi_render_plan.toml "$out/share/yazelix_yazi_assets/config_metadata/yazi_render_plan.toml"
              install -Dm644 config_metadata/vendored_yazi_plugins.toml "$out/share/yazelix_yazi_assets/config_metadata/vendored_yazi_plugins.toml"
              install -Dm644 config_metadata/vendored_yazi_plugin_patches/git.yazi.patch "$out/share/yazelix_yazi_assets/config_metadata/vendored_yazi_plugin_patches/git.yazi.patch"

              runHook postInstall
            '';

            doInstallCheck = true;
            nativeInstallCheckInputs = [
              pkgs.coreutils
              pkgs.findutils
              pkgs.gnugrep
              pkgs.lua
            ];
            installCheckPhase = ''
              runHook preInstallCheck

              install_root="$out/share/yazelix_yazi_assets"
              test -f "$install_root/yazelix_starship.toml"
              test -f "$install_root/flavors/catppuccin-mocha.yazi/flavor.toml"
              test -f "$install_root/plugins/git.yazi/main.lua"
              test -f "$install_root/plugins/lazygit.yazi/main.lua"
              test -f "$install_root/plugins/smart-tabs.yazi/main.lua"
              test -f "$install_root/plugins/starship.yazi/main.lua"
              test -f "$install_root/plugins/auto-layout.yazi/main.lua"
              test -x "$install_root/runtime_tools/ccboard/bin/ccboard"
              test -f "$install_root/runtime_tools/ccboard/runtime-tool-metadata.json"
              grep -F "ccboard" "$install_root/runtime_tools/ccboard/runtime-tool-metadata.json"
              test -x "$install_root/runtime_tools/codedb/bin/codedb"
              test -x "$install_root/runtime_tools/codedb/bin/nu_plugin_codedb"
              test -f "$install_root/runtime_tools/codedb/runtime-tool-metadata.json"
              grep -F "nu_plugin_codedb" "$install_root/runtime_tools/codedb/runtime-tool-metadata.json"
              test -f "$install_root/config_metadata/ccboard_runtime_tool.toml"
              test -f "$install_root/config_metadata/codedb_runtime_tool.toml"
              test -f "$install_root/config_metadata/yazi_assets_manifest.toml"
              test -f "$install_root/config_metadata/yazi_render_plan.toml"
              test -f "$install_root/config_templates/yazelix_yazi.toml"
              test -f "$install_root/config_templates/yazelix_keymap.toml"
              test -f "$install_root/config_templates/yazelix_theme.toml"
              lua -e "assert(loadfile('$install_root/plugins/lazygit.yazi/main.lua'))"
              lua -e "assert(loadfile('$install_root/plugins/smart-tabs.yazi/main.lua'))"

              flavor_count="$(find "$install_root/flavors" -name flavor.toml | wc -l | tr -d ' ')"
              test "$flavor_count" = "24"

              runHook postInstallCheck
            '';

            passthru = {
              assetsRoot = "share/yazelix_yazi_assets";
              configTemplatesPath = "share/yazelix_yazi_assets/config_templates";
              flavorsPath = "share/yazelix_yazi_assets/flavors";
              manifestPath = "share/yazelix_yazi_assets/config_metadata/yazi_assets_manifest.toml";
              pluginsPath = "share/yazelix_yazi_assets/plugins";
              renderPlanMetadataPath = "share/yazelix_yazi_assets/config_metadata/yazi_render_plan.toml";
              runtimeToolsPath = "share/yazelix_yazi_assets/runtime_tools";
              ccboardRuntimeToolMetadataPath = "share/yazelix_yazi_assets/runtime_tools/ccboard/runtime-tool-metadata.json";
              codedbRuntimeToolMetadataPath = "share/yazelix_yazi_assets/runtime_tools/codedb/runtime-tool-metadata.json";
            };

            meta = {
              description = "Reusable Yazi flavor, plugin, and runtime tool assets from Yazelix";
              license = pkgs.lib.licenses.mit;
              platforms = systems;
            };
          };
        in
        {
          default = assets;
          yazelix_yazi_assets = assets;
        }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          package = self.packages.${system}.yazelix_yazi_assets;
        in
        {
          install = package;
          asset_shape = pkgs.runCommand "yazelix-yazi-assets-shape" { } ''
            install_root="${package}/share/yazelix_yazi_assets"
            test -d "$install_root/flavors"
            test -d "$install_root/plugins"
            test -f "$install_root/plugins/git.yazi/main.lua"
            test -f "$install_root/plugins/smart-tabs.yazi/main.lua"
            test -f "$install_root/plugins/starship.yazi/main.lua"
            test -f "$install_root/plugins/auto-layout.yazi/main.lua"
            test -x "$install_root/runtime_tools/ccboard/bin/ccboard"
            test -f "$install_root/runtime_tools/ccboard/runtime-tool-metadata.json"
            ${pkgs.gnugrep}/bin/grep -F "ccboard" "$install_root/runtime_tools/ccboard/runtime-tool-metadata.json"
            test -x "$install_root/runtime_tools/codedb/bin/codedb"
            test -x "$install_root/runtime_tools/codedb/bin/nu_plugin_codedb"
            test -f "$install_root/runtime_tools/codedb/runtime-tool-metadata.json"
            ${pkgs.gnugrep}/bin/grep -F "nu_plugin_codedb" "$install_root/runtime_tools/codedb/runtime-tool-metadata.json"
            test -f "$install_root/config_metadata/ccboard_runtime_tool.toml"
            test -f "$install_root/config_metadata/codedb_runtime_tool.toml"
            test -f "$install_root/config_metadata/yazi_assets_manifest.toml"
            test -f "$install_root/config_metadata/yazi_render_plan.toml"
            test -f "$install_root/config_templates/yazelix_yazi.toml"
            touch "$out"
          '';
        }
      );
    };
}
