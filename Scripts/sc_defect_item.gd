extends HBoxContainer

signal deleted(item)

# Node references
@onready var defects_input = $DefectsInput
@onready var sample_size_input = $SampleSizeInput
@onready var delete_button = $DeleteButton

func _ready():
	# Set up delete button
	delete_button.connect("pressed", _on_delete_button_pressed)

func _on_delete_button_pressed():
	# Signal that this item should be deleted
	emit_signal("deleted", self)

func get_defects() -> String:
	return defects_input.text

func get_sample_size() -> String:
	return sample_size_input.text
