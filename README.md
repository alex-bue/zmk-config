# ZMK Config

## Keymap

![Keymap](keymap_drawer/base.svg) 

## Local Workflow

Enter the pinned development shell:

```sh
nix develop
```

Initialize or refresh the local ZMK workspace:

```sh
just init
just sync
```

Build firmware into `firmware/`:

```sh
just list
just build all
just build cradio_left
```

Check or bump west manifest pins:

```sh
just check-west
just bump-west
```

Regenerate the committed diagram:

```sh
just draw
```

`flake.nix` pins the local Zephyr toolchain to the Zephyr revision used by the pinned ZMK release.
GitHub Actions uses the same `nix develop --command just draw` path for drawing checks.
