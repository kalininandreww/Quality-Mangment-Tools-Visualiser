extends HBoxContainer

signal name_changed
signal value_changed
signal deleted

@onready var name_edit = $NameEdit
@onready var value_edit = $ValueEdit
@onready var delete_button = $DeleteButton

func _ready():
	name_edit.text = "Параметр " + str(get_index())
	value_edit.text = str(randi() % 100 + 1)  # Random initial value for testing
	
	name_edit.connect("text_changed", _on_name_changed)
	value_edit.connect("text_changed", _on_value_changed)
	delete_button.connect("pressed", _on_delete_pressed)
	delete_button.text = "X"

func _on_name_changed(_new_text):
	emit_signal("name_changed")

func _on_value_changed(_new_text):
	emit_signal("value_changed")

func _on_delete_pressed():
	# No queue_free here, let the parent handle removal
	emit_signal("deleted", self)

func get_parameter_name() -> String:
	return name_edit.text

func get_parameter_value() -> float:
	var text = value_edit.text
	if text.is_valid_float():
		return float(text)
	return 0.0
