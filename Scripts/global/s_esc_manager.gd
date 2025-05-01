extends Node

const ESC_MENU_SCENE = preload("res://Scenes/sc_esc_menu.tscn")
var esc_menu_instance = null
var current_scene = ""

func _ready():
	# Initialize the ESC menu and add it to the root
	esc_menu_instance = ESC_MENU_SCENE.instantiate()
	add_child(esc_menu_instance)
	
	# Track scene changes
	get_tree().root.connect("tree_changed", _on_tree_changed)
	
	# Set the initial scene path
	current_scene = get_tree().current_scene.scene_file_path
	
	# Only call set_current_scene if the method exists
	if esc_menu_instance.has_method("set_current_scene"):
		esc_menu_instance.set_current_scene(current_scene)
	else:
		# Alternative: directly set a property if that's how it's designed
		if "current_scene" in esc_menu_instance:
			esc_menu_instance.current_scene = current_scene

func _on_tree_changed():
	# When the scene tree changes, check if the current scene has changed
	if get_tree().current_scene and get_tree().current_scene.scene_file_path != current_scene:
		current_scene = get_tree().current_scene.scene_file_path
		
		# Only call set_current_scene if the method exists
		if esc_menu_instance.has_method("set_current_scene"):
			esc_menu_instance.set_current_scene(current_scene)
		else:
			# Alternative: directly set a property if that's how it's designed
			if "current_scene" in esc_menu_instance:
				esc_menu_instance.current_scene = current_scene

# Call this from each tool script to register the tool with the correct group
func register_tool(tool_node, tool_type):
	match tool_type:
		"ishikawa":
			tool_node.add_to_group("ishikawa_tool")
		"pareto":
			tool_node.add_to_group("pareto_tool")
		"scatter":
			tool_node.add_to_group("scatter_tool")
		"control_charts":
			tool_node.add_to_group("control_charts_tool")
		"histogram":
			tool_node.add_to_group("histogram_tool")
