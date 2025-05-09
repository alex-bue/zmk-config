CONFIG_DIR := config
DRAW_DIR := keymap_drawer
layout := ferris/sweep
IMAGE_NAME ?= keymap-drawer-env

DRAW_CMD_NATIVE = \
    keymap -c $(DRAW_DIR)/config.yaml parse -z $(CONFIG_DIR)/base.keymap --virtual-layers Combos > $(DRAW_DIR)/base.yaml && \
    yq -i '.combos.[].l = ["Combos"]' $(DRAW_DIR)/base.yaml && \
    keymap -c $(DRAW_DIR)/config.yaml draw $(DRAW_DIR)/base.yaml -k $(layout) > $(DRAW_DIR)/base.svg

DRAW_CMD_DOCKER = \
    keymap -c $(DRAW_DIR)/config.yaml parse -z $(CONFIG_DIR)/base.keymap --virtual-layers Combos > $(DRAW_DIR)/base.yaml && \
    yq -i '.combos.[].l = [\"Combos\"]' $(DRAW_DIR)/base.yaml && \
    keymap -c $(DRAW_DIR)/config.yaml draw $(DRAW_DIR)/base.yaml -k $(layout) > $(DRAW_DIR)/base.svg

IS_IN_CONTAINER := $(shell [ "$$CODESPACES" = "true" ] || [ "$$DEVCONTAINER" = "true" ] && echo true || echo false)

draw:
ifeq ($(IS_IN_CONTAINER),true)
	$(DRAW_CMD_NATIVE)
else
	docker run --rm -v $(PWD):/workspace -w /workspace $(IMAGE_NAME) /bin/sh -c "$(DRAW_CMD_DOCKER)"
endif
