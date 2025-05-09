CONFIG_DIR := config
DRAW_DIR := keymap_drawer
layout := ferris/sweep

DRAW_CMD = \
	keymap -c $(DRAW_DIR)/config.yaml parse -z $(CONFIG_DIR)/base.keymap --virtual-layers Combos > $(DRAW_DIR)/base.yaml && \
	yq -i '.combos.[].l = ["Combos"]' $(DRAW_DIR)/base.yaml && \
	keymap -c $(DRAW_DIR)/config.yaml draw $(DRAW_DIR)/base.yaml -k $(layout) > $(DRAW_DIR)/base.svg

draw:
ifeq ($(CODESPACES),true)
	$(DRAW_CMD)
else
	docker run --rm -v $(PWD):/workspace keymap-drawer-env /bin/sh -c '$(DRAW_CMD)'
endif

