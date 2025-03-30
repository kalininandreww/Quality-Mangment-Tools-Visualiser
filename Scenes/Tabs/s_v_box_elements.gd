extends VBoxContainer

@export var branch_tilt:int = -15
@export var branch_length:int = 150
@export var sub_length:int = 60


var diagram_data = {
	"spine":
		{
		"name": "Хребет",
		"branches": []
		}
}

var elements_panel:Node

func _ready():
	elements_panel = %VBoxElements
	add_spine()
	setup_styles()
	%DiagramCanvas.draw.connect(_draw_diagram)
	


func add_spine():
	var spine_container = VBoxContainer.new()
	var spine_header = HBoxContainer.new()
	
	var spine_label = Label.new()
	spine_label.text = "Хребет"
	
	var rename_button = Button.new()
	rename_button.text = "✎"
	rename_button.connect("pressed", self.rename_element.bind(spine_label))
	
	var add_branch_button = Button.new()
	add_branch_button.text = "+"
	add_branch_button.connect("pressed", self.add_branch.bind(spine_container))
	
	spine_header.add_child(spine_label)
	spine_header.add_child(rename_button)
	spine_header.add_child(add_branch_button)
	spine_container.add_child(spine_header)
	elements_panel.add_child(spine_container)


func add_branch(parent_container):
	var branch_container = VBoxContainer.new()
	var branch_header = HBoxContainer.new()
	var branch_margin = MarginContainer.new()
	
	branch_margin.add_theme_constant_override("margin_left", 20)
	
	var branch_label = Label.new()
	branch_label.text = "Кость"
	
	var rename_button = Button.new()
	rename_button.text = "✎"
	rename_button.connect("pressed", self.rename_element.bind(branch_label))
	
	var add_subbranch_button = Button.new()
	add_subbranch_button.text = "+"
	add_subbranch_button.connect("pressed", self.add_subbranch.bind(branch_container))
	
	var delete_button = Button.new()
	delete_button.text = "🗑"
	delete_button.connect("pressed", self.delete_element.bind(branch_container))
	
	branch_header.add_child(branch_label)
	branch_header.add_child(rename_button)
	branch_header.add_child(add_subbranch_button)
	branch_header.add_child(delete_button)
	branch_container.add_child(branch_header)
	branch_margin.add_child(branch_container)
	parent_container.add_child(branch_margin)
	
	# Add branch to diagram data
	var branch_data = {
		"name": branch_label.text,
		"subbranches": [] }
		
	diagram_data["spine"]["branches"].append(branch_data)
	update_diagram()  # Redraw the diagram


func add_subbranch(parent_container):
	var subbranch_container = HBoxContainer.new()
	var subbranch_margin = MarginContainer.new()
	
	subbranch_margin.add_theme_constant_override("margin_left", 20)
	
	var subbranch_label = Label.new()
	subbranch_label.text = "Подкость"
	
	var rename_button = Button.new()
	rename_button.text = "✎"
	#rename_button.icon = edit_icon
	#rename_button.icon.
	rename_button.connect("pressed", self.rename_element.bind(subbranch_label))
	
	var delete_button = Button.new()
	delete_button.text = "🗑"
	delete_button.connect("pressed", self.delete_element.bind(subbranch_container))
	
	subbranch_container.add_child(subbranch_label)
	subbranch_container.add_child(rename_button)
	subbranch_container.add_child(delete_button)
	subbranch_margin.add_child(subbranch_container)
	parent_container.add_child(subbranch_margin)
	
	# Add subbranch to diagram data
	var branch_index = parent_container.get_index() - 1  # Get the parent branch index
	var subbranch_data = {
		"name": subbranch_label.text
		}
	diagram_data["spine"]["branches"][branch_index]["subbranches"].append(subbranch_data)
	update_diagram()  # Redraw the diagram

func delete_element(element_container):
	element_container.queue_free()


func rename_element(label):
	var line_edit = LineEdit.new()
	line_edit.text = label.text
	
	var label_parent = label.get_parent()
	
	line_edit.connect("text_submitted", self.on_rename_complete.bind(label, line_edit, label_parent))
	label.replace_by(line_edit)


func on_rename_complete(new_text, label, line_edit, label_parent):
	label.text = new_text
	line_edit.queue_free()
	label_parent.add_child(label)
	label_parent.move_child(label, 0)
	label.show()

func update_diagram():
	# Clear the diagram
	%DiagramCanvas.queue_redraw()

func _draw_diagram():
	var font = get_theme_default_font()
	var font_size = get_theme_default_font_size()
	theme.set_color("font_color", "Label", Color.BLACK)
	
	var canvas = %DiagramCanvas
	canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), Color("#FEFAE0"), true)  # Clear the canvas
	
	# Draw the spine
	var spine_start = Vector2(50, canvas.size.y / 2)
	var spine_end = Vector2(canvas.size.x - 50, canvas.size.y / 2)
	canvas.draw_line(spine_start, spine_end, Color.BLACK, 2.0)
	# Draw branches
	var branch_spacing = (canvas.size.x - 100) / (diagram_data["spine"]["branches"].size() + 1)
	for i in range(diagram_data["spine"]["branches"].size()):
		var branch = diagram_data["spine"]["branches"][i]
		var branch_start = spine_start + Vector2(branch_spacing * (i + 1), 0)
		var direction = 1 if i % 2 == 0 else -1
		var angle = deg_to_rad(branch_tilt)
		var branch_end = branch_start + Vector2(
			sin(angle) * branch_length,
			cos(angle) * -branch_length * direction)
		canvas.draw_line(branch_start, branch_end, Color(0, 0, 0), 2)
		canvas.draw_string(font, branch_end + Vector2(-20, -10), branch["name"], HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.BLACK)
		
		# Draw subbranches
		var subbranch_count = branch["subbranches"].size()
		var sub_spacing = branch_length / (subbranch_count + 1)
		if sub_spacing > 0:
			for j in range(branch["subbranches"].size()):
				var subbranch = branch["subbranches"][j]
				var sub_angle = deg_to_rad(0)  # Parallel to spine
				var sub_direction = (1 if j % 2 == 0 else -1)
				
				var sub_start = branch_start + Vector2(
					sin(angle) * sub_spacing * (j + 1),
					cos(angle) * sub_spacing * -(j + 1) * (1 if i % 2 == 0 else -1)
					)
				
				var subbranch_end = sub_start + Vector2(
					sub_length * sub_direction,
					0)
				
				canvas.draw_line(sub_start, subbranch_end, Color(0, 0, 0), 2)
				var text_offset = Vector2(10 * sub_direction, -5)
				canvas.draw_string(font, subbranch_end + text_offset, subbranch["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.BLACK)


func setup_styles():
	# Style for buttons
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color("8EB8E5")
	button_style.corner_radius_top_left = 15
	button_style.corner_radius_top_right = 15
	button_style.corner_radius_bottom_left = 15
	button_style.corner_radius_bottom_right = 15
	
	# Apply styles
	var theme = Theme.new()
	theme.set_stylebox("normal", "Button", button_style)
	theme.set_color("font_color", "Label", Color(211103))
	theme.set_color("font_color", "Button", Color(211103))
	
	# Assign the theme to the root node
	self.theme = theme
