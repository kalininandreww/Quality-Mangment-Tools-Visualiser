extends HBoxContainer

@warning_ignore("unused_signal")
signal deleted(item)

# Node references
@onready var measurements_input = $MeasurementsInput
@onready var delete_button = $DeleteButton

func _ready():
	# Set up delete button
	delete_button.connect("pressed", _on_delete_button_pressed)

func _on_delete_button_pressed():
	# Signal that this item should be deleted
	emit_signal("deleted", self)

func get_measurements() -> String:
	return measurements_input.text
