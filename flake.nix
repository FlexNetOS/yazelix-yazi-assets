{
  description = "Standalone Yazi flavor, plugin, and runtime tool assets from Yazelix";

  inputs = {
    codedbNuPlugin = {
      url = "github:FlexNetOS/nu_plugin?rev=2c0272ca324550c684086ecc74ab4ea56fe8ef36";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ccboardSource = {
      url = "github:FlexNetOS/ccboard?rev=f127e8a948bdd98ed57abff6759b715dfa345f1a";
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
          # Assets must evaluate on every advertised platform.  The CodeDB
          # runtime tool deliberately remains Linux-only: its upstream package
          # owns the Bubblewrap sandbox and must never be emulated on Darwin.
          assetsOnly = pkgs.stdenvNoCC.mkDerivation {
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
              cp -R config_templates "$install_root/config_templates"
              install -Dm644 yazelix_starship.toml "$install_root/yazelix_starship.toml"
              install -Dm644 README.md "$out/share/doc/yazelix_yazi_assets/README.md"
              install -Dm644 LICENSE "$out/share/doc/yazelix_yazi_assets/LICENSE"
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
              test -f "$install_root/config_metadata/yazi_assets_manifest.toml"
              test -f "$install_root/config_metadata/yazi_render_plan.toml"
              # The portable layer must make no runtime-tool claims and must not
              # leak Linux-only runtime-tool descriptors or binaries.
              manifest="$install_root/config_metadata/yazi_assets_manifest.toml"
              grep -q '^runtime_tools_available = false$' "$manifest"
              if grep -q 'runtime_tool_paths' "$manifest"; then
                echo "portable manifest must not declare runtime_tool_paths" >&2
                exit 1
              fi
              if grep -qE '^runtime_tools = ' "$manifest"; then
                echo "portable manifest must not list runtime_tools" >&2
                exit 1
              fi
              test ! -e "$install_root/config_metadata/ccboard_runtime_tool.toml"
              test ! -e "$install_root/config_metadata/codedb_runtime_tool.toml"
              test ! -e "$install_root/config_metadata/yazi_runtime_tools_manifest.toml"
              test ! -e "$install_root/runtime_tools"
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
            };

            meta = {
              description = "Cross-platform reusable Yazi flavor, plugin, and configuration assets from Yazelix";
              license = pkgs.lib.licenses.mit;
              platforms = systems;
            };
          };

          runtimeTools =
            if pkgs.stdenv.hostPlatform.isLinux then
              pkgs.stdenvNoCC.mkDerivation {
                pname = "yazelix_yazi_runtime_tools";
                version = "0.1.0";
                dontUnpack = true;
                dontConfigure = true;
                dontBuild = true;
                installPhase = ''
                  base="$out/share/yazelix_yazi_assets"
                  install_root="$base/runtime_tools"
                  mkdir -p "$install_root/ccboard/bin" "$install_root/codedb/bin"
                  ln -s "${ccboardPackage}/bin/ccboard" "$install_root/ccboard/bin/ccboard"
                  cat > "$install_root/ccboard/runtime-tool-metadata.json" <<EOF
{"schema_version":1,"name":"ccboard","kind":"runtime-tool","source_repo":"https://github.com/FlexNetOS/ccboard","source_rev":"f127e8a948bdd98ed57abff6759b715dfa345f1a","commands":["ccboard"]}
EOF
                  ln -s "${codedbNuPlugin.packages.${system}.codedb_runtime_tools}/bin/codedb" "$install_root/codedb/bin/codedb"
                  ln -s "${codedbNuPlugin.packages.${system}.codedb_runtime_tools}/bin/nu_plugin_codedb" "$install_root/codedb/bin/nu_plugin_codedb"
                  install -Dm644 "${codedbNuPlugin.packages.${system}.codedb_runtime_tools}/share/codedb/runtime-tool-metadata.json" "$install_root/codedb/runtime-tool-metadata.json"

                  # Linux-only runtime-tool descriptors and aggregate manifest.
                  # These deliberately live only in the Linux composition so the
                  # portable layer stays free of runtime-tool claims.
                  install -Dm644 ${./config_metadata/ccboard_runtime_tool.toml} "$base/config_metadata/ccboard_runtime_tool.toml"
                  install -Dm644 ${./config_metadata/codedb_runtime_tool.toml} "$base/config_metadata/codedb_runtime_tool.toml"
                  install -Dm644 ${./config_metadata/yazi_runtime_tools_manifest.toml} "$base/config_metadata/yazi_runtime_tools_manifest.toml"
                '';
              }
            else
              null;

          assetsWithRuntimeTools =
            if pkgs.stdenv.hostPlatform.isLinux then
              pkgs.symlinkJoin {
                name = "yazelix_yazi_assets";
                paths = [ assetsOnly runtimeTools ];
                passthru = assetsOnly.passthru // {
                  runtimeToolsPath = "share/yazelix_yazi_assets/runtime_tools";
                  ccboardRuntimeToolMetadataPath = "share/yazelix_yazi_assets/runtime_tools/ccboard/runtime-tool-metadata.json";
                  codedbRuntimeToolMetadataPath = "share/yazelix_yazi_assets/runtime_tools/codedb/runtime-tool-metadata.json";
                };
                meta = assetsOnly.meta // {
                  description = "Linux Yazi assets with mandatory ccboard and sandboxed CodeDB runtime tools";
                  platforms = pkgs.lib.platforms.linux;
                };
              }
            else
              null;
        in
        {
          default = assetsOnly;
          yazi_assets_only = assetsOnly;
        } // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          yazelix_yazi_assets = assetsWithRuntimeTools;
        }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          package = self.packages.${system}.yazi_assets_only;
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
            test -f "$install_root/config_metadata/yazi_assets_manifest.toml"
            test -f "$install_root/config_metadata/yazi_render_plan.toml"
            test -f "$install_root/config_templates/yazelix_yazi.toml"
            # The portable layer must exclude every Linux-only runtime-tool
            # artifact and make no runtime-tool claims.
            test ! -e "$install_root/runtime_tools"
            test ! -e "$install_root/config_metadata/ccboard_runtime_tool.toml"
            test ! -e "$install_root/config_metadata/codedb_runtime_tool.toml"
            test ! -e "$install_root/config_metadata/yazi_runtime_tools_manifest.toml"
            ${pkgs.gnugrep}/bin/grep -q '^runtime_tools_available = false$' "$install_root/config_metadata/yazi_assets_manifest.toml"
            if ${pkgs.gnugrep}/bin/grep -q 'runtime_tool_paths' "$install_root/config_metadata/yazi_assets_manifest.toml"; then
              echo "portable manifest must not declare runtime_tool_paths" >&2
              exit 1
            fi
            touch "$out"
          '';
          # Meaningful cross-platform contract: prove the portable derivation
          # closure never contains ccboard, CodeDB, nu_plugin_codedb, or the
          # Bubblewrap sandbox -- not merely that evaluation succeeds.
          portable_closure_isolation = pkgs.runCommand "yazelix-yazi-portable-closure-isolation"
            {
              exportReferencesGraph = [ "closure" package ];
            }
            ''
              if ${pkgs.gnugrep}/bin/grep -E -i 'ccboard|codedb|nu_plugin_codedb|bubblewrap|bwrap' closure; then
                echo "FAIL: portable yazi_assets_only closure leaks Linux runtime tooling" >&2
                exit 1
              fi
              touch "$out"
            '';
        } // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          runtime_tool_shape = pkgs.runCommand "yazelix-yazi-runtime-tools-shape" { } ''
            install_root="${self.packages.${system}.yazelix_yazi_assets}/share/yazelix_yazi_assets"
            test -x "$install_root/runtime_tools/ccboard/bin/ccboard"
            test -f "$install_root/runtime_tools/ccboard/runtime-tool-metadata.json"
            ${pkgs.gnugrep}/bin/grep -F "ccboard" "$install_root/runtime_tools/ccboard/runtime-tool-metadata.json"
            test -x "$install_root/runtime_tools/codedb/bin/codedb"
            test -x "$install_root/runtime_tools/codedb/bin/nu_plugin_codedb"
            test -f "$install_root/runtime_tools/codedb/runtime-tool-metadata.json"
            ${pkgs.gnugrep}/bin/grep -F "nu_plugin_codedb" "$install_root/runtime_tools/codedb/runtime-tool-metadata.json"
            # The Linux composition explicitly models runtime-tool availability
            # via its own descriptors and aggregate manifest, while the portable
            # manifest it also carries still declares no runtime tools.
            test -f "$install_root/config_metadata/ccboard_runtime_tool.toml"
            test -f "$install_root/config_metadata/codedb_runtime_tool.toml"
            test -f "$install_root/config_metadata/yazi_runtime_tools_manifest.toml"
            ${pkgs.gnugrep}/bin/grep -q '^runtime_tools_available = true$' "$install_root/config_metadata/yazi_runtime_tools_manifest.toml"
            ${pkgs.gnugrep}/bin/grep -q '^runtime_tools_available = false$' "$install_root/config_metadata/yazi_assets_manifest.toml"
            touch "$out"
          '';
        }
      );
    };
}
