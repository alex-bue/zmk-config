CONFIG_DIR := config
DRAW_DIR := keymap_drawer
layout := ferris/sweep
IMAGE_NAME ?= keymap-drawer-env

DRAW_CMD = \
    keymap -c $(DRAW_DIR)/config.yaml parse -z $(CONFIG_DIR)/base.keymap --virtual-layers Combos > $(DRAW_DIR)/base.yaml && \
    yq -i '.combos.[].l = [\"Combos\"]' $(DRAW_DIR)/base.yaml && \
    keymap -c $(DRAW_DIR)/config.yaml draw $(DRAW_DIR)/base.yaml -k $(layout) > $(DRAW_DIR)/base.svg

# Detect if running inside devcontainer
IS_IN_CONTAINER := $(shell grep -qE 'devcontainer|codespaces' /proc/1/cgroup && echo true || echo false)

draw:
ifeq ($(IS_IN_CONTAINER),true)
	$(DRAW_CMD)
else
	docker run --rm -v $(PWD):/workspace -w /workspace $(IMAGE_NAME) /bin/sh -c "$(DRAW_CMD)"
endif

