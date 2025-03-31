extends VBoxContainer

@export var branch_tilt:int = -15
@export var branch_length:int = 150
@export var sub_length:int = 60
@export var spine_offset_left:int = 150
@export var bones_are_alined:bool = false

var last_branch_pos

var diagram_data = {
	"spine":
		{
		"name": "Хребет",
		"label_ref": null,
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
	diagram_data["spine"]["label_ref"] = spine_label
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
	
	diagram_data["spine"]["label"] = spine_label


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
	"label_ref": branch_label,
	"container_ref": branch_container,
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
	var branch_index = parent_container.get_parent().get_index() - 1  # Get the parent branch index
	
	if branch_index >= 0 and branch_index < diagram_data["spine"]["branches"].size():
		var subbranch_data = {
			"name": subbranch_label.text,
			"label_ref": subbranch_label
		}
		diagram_data["spine"]["branches"][branch_index]["subbranches"].append(subbranch_data)
	update_diagram()  # Redraw the diagram

func delete_element(element_container):
	if element_container is VBoxContainer:  # This is a branch
		for i in range(diagram_data["spine"]["branches"].size()):
			if diagram_data["spine"]["branches"][i]["container_ref"] == element_container:
				diagram_data["spine"]["branches"].remove_at(i)
				break
		var margin_parent = element_container.get_parent()
		if margin_parent is MarginContainer:
			margin_parent.queue_free()
		#else:
			#element_container.queue_free()
		
	else:  # This is a subbranch
		# Need to find which branch contains this subbranch
		var subbranch_label = element_container.get_node("Label")
		
		for branch in diagram_data["spine"]["branches"]:
			for j in range(branch["subbranches"].size()):
				if branch["subbranches"][j]["label_ref"] == subbranch_label:
					branch["subbranches"].remove_at(j)
					break
		var margin_parent = element_container.get_parent()
		if margin_parent is MarginContainer:
			margin_parent.queue_free()
		#else:
			#element_container.queue_free()
	
	# Then delete the UI element
	element_container.queue_free()
	update_diagram()  # Make sure to redraw


func rename_element(label):
	var line_edit = LineEdit.new()
	line_edit.text = label.text
	
	var label_parent = label.get_parent()
	
	line_edit.connect("text_submitted", self.on_rename_complete.bind(label, line_edit, label_parent))
	label.replace_by(line_edit)


func on_rename_complete(new_text, label, line_edit, label_parent):
	label.text = new_text
	
	if label == diagram_data["spine"]["label_ref"]:
		diagram_data["spine"]["name"] = new_text
	else:
		for branch in diagram_data["spine"]["branches"]:
			if label == branch["label_ref"]:
				branch["name"] = new_text
				break
			else:
				for sub in branch["subbranches"]:
					if label == sub["label_ref"]:
						sub["name"] = new_text
						break
	update_diagram()
	
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
	var spine_end = Vector2(canvas.size.x - spine_offset_left, canvas.size.y / 2)
	canvas.draw_line(spine_start, spine_end, Color.BLACK, 2.0)
	
	# Draw branches
	var branch_spacing
	var branch_count = diagram_data["spine"]["branches"].size()
	
	if bones_are_alined == false:
		branch_spacing = (canvas.size.x - 100) / (diagram_data["spine"]["branches"].size() + 1)
	else:
		var branch_pairs = ceil(branch_count / 2.0)
		branch_spacing = (canvas.size.x - 100) / (branch_pairs + 1)
	
	for i in range(diagram_data["spine"]["branches"].size()):
		var branch = diagram_data["spine"]["branches"][i]
		var branch_pos
		if bones_are_alined:
			# Calculate position based on pair index
			var pair_index = floor(i / 2)
			branch_pos = spine_start + Vector2(branch_spacing * (pair_index + 1), 0)
		else:
			branch_pos = spine_start + Vector2(branch_spacing * (i + 1), 0)
			
		#var branch_start = spine_start + Vector2(branch_spacing * (i + 1), 0)
		var direction = 1 if i % 2 == 0 else -1
		var angle = deg_to_rad(branch_tilt)
		var branch_end = branch_pos + Vector2(
			sin(angle) * branch_length,
			cos(angle) * -branch_length * direction)
		canvas.draw_line(branch_pos, branch_end, Color(0, 0, 0), 2)
		
		if direction == 1:
			canvas.draw_string(font, branch_end + Vector2(-20, -5), branch["name"], HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.BLACK)
		else:
			canvas.draw_string(font, branch_end + Vector2(-20, 15), branch["name"], HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.BLACK)
		
		# Draw subbranches
		var subbranch_count = branch["subbranches"].size()
		if subbranch_count > 0:
			var sub_spacing = branch_length / (subbranch_count + 1)
			for j in range(subbranch_count):
				var subbranch = branch["subbranches"][j]
				var sub_direction = (-1 if j % 2 == 0 else 1)
				
				var sub_start = branch_pos + Vector2(
					sin(angle) * sub_spacing * (j + 1),
					cos(angle) * sub_spacing * -(j + 1) * (1 if i % 2 == 0 else -1)
					)
				
				var subbranch_end = sub_start + Vector2(
					sub_length * sub_direction,
					0)
				
				canvas.draw_line(sub_start, subbranch_end, Color(0, 0, 0), 2)
				var text_width = font.get_string_size(subbranch["name"], HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
				var text_pos = (sub_start + subbranch_end) / 2 - Vector2(text_width / 2, 10)
				canvas.draw_string(font, text_pos, subbranch["name"], HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.BLACK)
		
	var spine_name_pos = Vector2(
	spine_end.x+3,
	spine_start.y+5)
	canvas.draw_string(font, spine_name_pos, diagram_data["spine"]["name"], HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.BLACK)


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
