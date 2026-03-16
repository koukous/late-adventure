extends CanvasLayer
# Dialogue UI - shows NPC dialogue

@onready var dialogue_panel = $DialoguePanel
@onready var npc_name_label = $DialoguePanel/NameLabel
@onready var dialogue_text = $DialoguePanel/DialogueText
@onready var continue_label = $DialoguePanel/ContinueLabel

func _ready():
	# Hide at start
	hide_dialogue()

func show_dialogue(npc_name: String, text: String):
	dialogue_panel.visible = true
	npc_name_label.text = npc_name
	dialogue_text.text = text
	continue_label.text = "Press E to continue..."

func hide_dialogue():
	dialogue_panel.visible = false
	npc_name_label.text = ""
	dialogue_text.text = ""
