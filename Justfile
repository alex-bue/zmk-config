[private]
default:
    @just --list --unsorted

config := absolute_path("config")
build := absolute_path(".build")
out := absolute_path("firmware")
draw_dir := absolute_path("keymap_drawer")
build_matrix := "build.yaml"

# Parse build.yaml and filter targets by expression.
_parse_targets expr: _check_yq_version
    #!/usr/bin/env bash
    set -euo pipefail
    expr="{{ expr }}"
    attrs='[.board, .shield, .snippet, ."artifact-name", ."cmake-args"]'
    filter="(($attrs | map(. // [.]) | combinations), ((.include // {})[] | $attrs)) | join(\",\")"
    yq -r "$filter" {{ build_matrix }} \
        | grep -v "^," \
        | grep -i "${expr/#all/.*}" || true

# Build firmware for one board + shield combination.
_build_single board shield snippet artifact cmake_args *west_args:
    #!/usr/bin/env bash
    set -euo pipefail
    board="{{ board }}"
    shield="{{ shield }}"
    snippet="{{ snippet }}"
    artifact="{{ artifact }}"
    cmake_args="{{ cmake_args }}"
    artifact="${artifact:-${shield:+${shield// /+}-}${board//\//_}}"
    build_dir="{{ build }}/$artifact"

    echo "Building firmware for $artifact..."
    west build -s zmk/app -d "$build_dir" -b "$board" {{ west_args }} ${snippet:+-S "$snippet"} -- \
        -DZMK_CONFIG="{{ config }}" ${shield:+-DSHIELD="$shield"} ${cmake_args}

    mkdir -p "{{ out }}"
    if [[ -f "$build_dir/zephyr/zmk.uf2" ]]; then
        cp "$build_dir/zephyr/zmk.uf2" "{{ out }}/$artifact.uf2"
    else
        cp "$build_dir/zephyr/zmk.bin" "{{ out }}/$artifact.bin"
    fi

# Flash firmware for one board + shield combination.
_flash_single board shield artifact:
    #!/usr/bin/env bash
    set -euo pipefail
    board="{{ board }}"
    shield="{{ shield }}"
    artifact="{{ artifact }}"
    artifact="${artifact:-${shield:+${shield// /+}-}${board//\//_}}"
    build_dir="{{ build }}/$artifact"

    echo "Flashing firmware for $artifact..."
    west flash -d "$build_dir"

# List build targets.
[group("build & draw")]
list:
    @just _parse_targets all \
        | awk -F, '{ print ($2 != "" ? $2 : $1) }' \
        | sort

# Build firmware for targets matching <expr>.
[group("build & draw")]
build expr *west_args:
    #!/usr/bin/env bash
    set -euo pipefail
    targets=$(just _parse_targets {{ expr }})

    [[ -z "$targets" ]] && echo "No matching targets found. Aborting..." >&2 && exit 1

    echo "$targets" | while IFS=, read -r board shield snippet artifact cmake_args; do
        just _build_single "$board" "$shield" "$snippet" "$artifact" "$cmake_args" {{ west_args }}
    done

# Build and flash firmware for targets matching <expr>.
[group("build & draw")]
flash expr: (build expr)
    #!/usr/bin/env bash
    set -euo pipefail
    targets=$(just _parse_targets {{ expr }})

    [[ -z "$targets" ]] && echo "No matching targets found. Aborting..." >&2 && exit 1

    echo "$targets" | while IFS=, read -r board shield snippet artifact cmake_args; do
        just _flash_single "$board" "$shield" "$artifact"
    done

# Generate the committed keymap drawer artifacts from config/base.keymap.
[group("build & draw")]
draw: _check_yq_version
    #!/usr/bin/env bash
    set -euo pipefail
    keymap -c "{{ draw_dir }}/config.yaml" parse -z "{{ config }}/base.keymap" --virtual-layers Combos > "{{ draw_dir }}/base.yaml"
    jq_expr='
        .combos = [.combos[] | .l = ["Combos"]] |
        .layers.num[30] = {"type": "held"} |
        .layers.navigation[30] = {"type": "held"} |
        .layers.sys[30] = {"type": "held"} |
        .layers.sys[33] = {"type": "held"} |
        .layers = {
            Default: .layers.default,
            Navigation: .layers.navigation,
            Fn: .layers.fn,
            Num: .layers.num,
            Sys: .layers.sys,
            WM: .layers.wm,
            Combos: .layers.Combos
        }
    '
    yq -Yi "$jq_expr" "{{ draw_dir }}/base.yaml"
    keymap -c "{{ draw_dir }}/config.yaml" draw "{{ draw_dir }}/base.yaml" -k ferris/sweep > "{{ draw_dir }}/base.svg"
    perl -0pi -e 's|(</style>\n)|$1<rect width="100%" height="100%" fill="#2d353b"/>\n|' "{{ draw_dir }}/base.svg"

# Initialize the west workspace.
[group("workspace")]
init:
    west init -l config
    west update --fetch-opt=--filter=blob:none
    west zephyr-export

# Synchronize the west workspace after manifest changes.
[group("workspace")]
sync:
    west update --fetch-opt=--filter=blob:none

# Bump west manifest revisions and re-sync the workspace.
[group("workspace")]
bump-west: && sync
    pin-west bump -f "{{ config }}/west.yml"

# Check that west manifest revisions are exact pins.
[group("workspace")]
check-west:
    pin-west check -f "{{ config }}/west.yml"

# Bump nix toolchain pins in flake.lock.
[group("workspace")]
bump-nix:
    nix flake update --flake .

# Remove local build outputs.
[group("cleanup")]
clean:
    rm -rf "{{ build }}" "{{ out }}"

[no-exit-message]
_check_yq_version:
    #!/usr/bin/env bash
    if yq --help 2>&1 | grep -qi 'eval'; then
        echo "This recipe requires python-yq. Use the included nix shell: nix develop" >&2
        exit 1
    fi
