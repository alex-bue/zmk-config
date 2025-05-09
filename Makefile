CONFIG_DIR := config
DRAW_DIR := keymap_drawer
layout := ferris/sweep

draw:
	keymap -c $(DRAW_DIR)/config.yaml parse -z $(CONFIG_DIR)/base.keymap --virtual-layers Combos > $(DRAW_DIR)/base.yaml
	yq -i '.combos.[].l = ["Combos"]' $(DRAW_DIR)/base.yaml
	keymap -c $(DRAW_DIR)/config.yaml draw $(DRAW_DIR)/base.yaml -k $(layout) > $(DRAW_DIR)/base.svg

