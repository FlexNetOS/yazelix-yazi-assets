# smart-tabs.yazi

Yazelix-maintained tab helper for [Yazi](https://yazi-rs.github.io)

This functional plugin keeps tab behavior focused and separate from `auto-layout.yazi`. `auto-layout.yazi` owns width-aware parent/current/preview pane layout, while `smart-tabs.yazi` owns tab creation and smart switching

## Usage

Bind it from `keymap.toml`:

```toml
[[mgr.prepend_keymap]]
on = [ "t", "t" ]
run = "plugin smart-tabs create"
desc = "Create tab from hovered directory"

[[mgr.prepend_keymap]]
on = "2"
run = "plugin smart-tabs switch 1"
desc = "Switch or create tab 2"
```

## Commands

- `plugin smart-tabs create` creates a tab for the hovered directory, or for the current directory when the hovered item is not a directory
- `plugin smart-tabs switch N` switches to zero-based tab `N`, creating missing tabs at the current directory first
- `plugin smart-tabs N` is shorthand for `plugin smart-tabs switch N`

## Yazelix Defaults

Yazelix binds `t t` to smart tab creation and `1` through `0` to smart switch/create tabs 1 through 10
