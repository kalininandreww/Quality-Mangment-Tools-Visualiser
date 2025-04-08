extends Control



func _on_b_ishikawa_pressed() -> void:
	get_tree().change_scene_to_packed(load("res://Scenes/Tabs/SC_Ishikava.tscn"))


func _on_b_paretto_pressed() -> void:
	get_tree().change_scene_to_packed(load("res://Scenes/Tabs/SC_Paretto.tscn"))
