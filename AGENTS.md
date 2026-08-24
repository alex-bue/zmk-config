# Customization Guide

Instructions for working on this ZMK config. They are written for coding agents, but should also
be useful when returning to the repo after a long break.

## Ground Rules

- `config/base.keymap` is the keymap source of truth. Change layers, thumb keys, custom behaviors,
  and layer-local bindings there.
- `keymap_drawer/base.yaml` and `keymap_drawer/base.svg` are generated snapshots. Do not hand-edit
  them as source files. If the keymap or drawer labels change, run `just draw` and commit the
  generated result.
- Firmware builds run through GitHub Actions using `.github/workflows/build.yml` and `build.yaml`.
  A fresh fork may need Actions enabled from GitHub's Actions tab before builds run.
- The drawing workflow runs `just draw`. On pull requests it checks that generated artifacts are
  fresh; on pushes and manual runs it commits updated drawing artifacts when they change.
- ZMK and external modules are pinned as exact SHAs in `config/west.yml`. Use `just check-west`
  to validate pins and `just bump-west` from the nix shell for routine manifest bumps, then inspect
  the resulting `config/west.yml` diff.
- The local Zephyr toolchain is pinned in `flake.nix` and `flake.lock`. Keep the `zephyr` input
  aligned with the Zephyr revision imported by the pinned ZMK release in `config/west.yml`.
- Prefer small, targeted keymap changes. Preserve the aligned key grids in `config/base.keymap`
  and avoid unrelated formatting churn.
- Use the nix shell for local tooling. It provides `west`, the Zephyr SDK, `just`,
  `keymap-drawer`, Python `yq`, `pin-west`, and `urob/zmk-helpers`. There is no Docker draw wrapper.
- After `just bump-nix`, validate `nix develop --command just list`; nixpkgs updates can change the
  Python package set used by Zephyr tooling.

## Common Commands

```sh
nix develop
just list
just init
just build all
just check-west
just draw
```

- `nix develop` enters the pinned development environment.
- `just list` prints build targets from `build.yaml`.
- `just init` creates or refreshes the local west workspace.
- `just build all` builds all targets into `firmware/`.
- `just check-west` verifies west manifest pins.
- `just draw` regenerates `keymap_drawer/base.yaml` and `keymap_drawer/base.svg` from
  `config/base.keymap`.

## How The Layout Works

`config/cradio.keymap` is the board entry point. It includes the 34-key label header from
`zmk-helpers`, defines the left, right, and thumb key-position groups, then includes
`config/base.keymap`.

The key-position labels come from `zmk-helpers/key-labels/34.h`:

- `LT0` to `LT4`, `LM0` to `LM4`, `LB0` to `LB4` for the left hand.
- `RT0` to `RT4`, `RM0` to `RM4`, `RB0` to `RB4` for the right hand.
- `LH0`, `LH1`, `RH0`, `RH1` for thumbs.

Combos, homerow-mod trigger positions, and tri-state ignored positions use these labels. Keep that
physical-position model in mind when moving bindings between keys.

## Where To Change What

| Change | File |
| --- | --- |
| Layers, thumb keys, custom behaviors | `config/base.keymap` |
| HRM timing and trigger positions | `config/includes/behaviors_homerow_mods.dtsi` |
| Combos | `config/includes/combos.dtsi` |
| Leader sequences | `config/includes/leader.dtsi` |
| Macros | `config/includes/macros.dtsi` |
| Physical key labels / board entry point | `config/cradio.keymap` |
| Board settings: sleep, combo limits, ZMK config | `config/cradio.conf` |
| Build targets | `build.yaml` |
| ZMK and external modules | `config/west.yml` |
| Local Zephyr/Nix toolchain | `flake.nix`, `flake.lock` |
| Keymap drawer labels and style | `keymap_drawer/config.yaml` |
| Generated drawing artifacts | `keymap_drawer/base.yaml`, `keymap_drawer/base.svg` |
| Draw tooling | `Justfile`, `.github/workflows/draw.yml` |
| Firmware build workflow | `.github/workflows/build.yml` |

## Drawing

The drawer parses `config/base.keymap` through `keymap_drawer/config.yaml`. Use
`raw_binding_map` in `keymap_drawer/config.yaml` for display-only labels such as `PWin` and `NWin`;
do not rename firmware behaviors just to change the diagram.

If the draw workflow fails with a `git diff --exit-code` error, the generated drawing artifacts are
stale. Run `just draw`, inspect the diff, and commit the updated `keymap_drawer/base.yaml` and
`keymap_drawer/base.svg`.

## Removing A Feature

1. Remove its bindings or behavior definitions from `config/base.keymap`.
2. Remove related combos from `config/includes/combos.dtsi` if applicable.
3. Remove includes from `config/base.keymap` when they become unused.
4. If an external module was only used by that feature, remove the module from `config/west.yml`.
5. Run `just draw` if the visible layout changed.

## Validation Expectations

- For keymap-only changes, rely on the GitHub firmware build plus `just draw`.
- For drawing-only changes, run `nix develop --command just draw` and check the generated diff.
- If changing YAML files, validate them with `yq e . <file>` when available.
- Use `nix develop --command just list` as a quick local smoke test for the nix shell and
  `build.yaml` parser.
