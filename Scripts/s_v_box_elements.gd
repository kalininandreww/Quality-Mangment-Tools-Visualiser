extends VBoxContainer

@export var branch_tilt:int = -15
@export var branch_length:int = 150
@export var sub_length:int = 60
@export var spine_offset_left:int = 150
@export var bones_are_alined:bool = false
@export var length_step_modifier:float = 0.23

var last_branch_pos

var file_dialog = null
@onready var save_button = %SaveButton
@onready var diagram_container = %DiagramCanvas

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
	var subbranch_container = VBoxContainer.new()
	var subbranch_header = HBoxContainer.new()
	var subbranch_margin = MarginContainer.new()
	
	subbranch_margin.add_theme_constant_override("margin_left", 20)
	
	var subbranch_label = Label.new()
	subbranch_label.text = "Подкость"
	
	var rename_button = Button.new()
	rename_button.text = "✎"
	rename_button.connect("pressed", self.rename_element.bind(subbranch_label))
	
	var add_subsubbone_button = Button.new()
	add_subsubbone_button.text = "+"
	add_subsubbone_button.connect("pressed", self.add_subsubbone.bind(subbranch_header))
	
	var delete_button = Button.new()
	delete_button.text = "🗑"
	delete_button.connect("pressed", self.delete_element.bind(subbranch_container))
	
	subbranch_header.add_child(subbranch_label)
	subbranch_header.add_child(rename_button)
	subbranch_header.add_child(add_subsubbone_button)
	subbranch_header.add_child(delete_button)
	subbranch_container.add_child(subbranch_header)
	subbranch_margin.add_child(subbranch_container)
	parent_container.add_child(subbranch_margin)
	
	# Add subbranch to diagram data
	var branch_index = parent_container.get_parent().get_index() - 1  # Get the parent branch index
	
	if branch_index >= 0 and branch_index < diagram_data["spine"]["branches"].size():
		var subbranch_data = {
			"name": subbranch_label.text,
			"label_ref": subbranch_label,
			"container_ref": subbranch_container
		}
		diagram_data["spine"]["branches"][branch_index]["subbranches"].append(subbranch_data)
	update_diagram()  # Redraw the diagram


func add_subsubbone(parent_container):
	# Create UI elements
	var subsubbone_container = HBoxContainer.new()
	var subsubbone_margin = MarginContainer.new()

	subsubbone_margin.add_theme_constant_override("margin_left", 40)

	var subsubbone_label = Label.new()
	subsubbone_label.text = "Подподкость"

	var rename_button = Button.new()
	rename_button.text = "✎"
	rename_button.connect("pressed", self.rename_element.bind(subsubbone_label))

	var delete_button = Button.new()
	delete_button.text = "🗑"
	delete_button.connect("pressed", self.delete_element.bind(subsubbone_container))

	subsubbone_container.add_child(subsubbone_label)
	subsubbone_container.add_child(rename_button)
	subsubbone_container.add_child(delete_button)
	subsubbone_margin.add_child(subsubbone_container)

	var vbox_parent = parent_container.get_parent()
	vbox_parent.add_child(subsubbone_margin)

	# Add to diagram data - Print debug info to help troubleshoot
	print("Parent container: ", parent_container)
	print("Parent hierarchy: ", parent_container.get_parent(), " -> ", parent_container.get_parent().get_parent(), " -> ", parent_container.get_parent().get_parent().get_parent())

	# Try to find the branch and subbranch in the data structure
	var branch_index = -1
	var subbranch_index = -1

	# Find the matching branch and subbranch using the container references
	for b_idx in range(diagram_data["spine"]["branches"].size()):
		var branch = diagram_data["spine"]["branches"][b_idx]

		for sb_idx in range(branch["subbranches"].size()):
			var subbranch = branch["subbranches"][sb_idx]

			if subbranch["container_ref"] == parent_container.get_parent():
				branch_index = b_idx
				subbranch_index = sb_idx
				break

		if branch_index >= 0:
			break

	print("Found branch_index: ", branch_index, ", subbranch_index: ", subbranch_index)

	if branch_index >= 0 && subbranch_index >= 0:
		var subsubbone_data = {
	"name": subsubbone_label.text,
	"label_ref": subsubbone_label,
	"container_ref": subsubbone_container
	}

		if not diagram_data["spine"]["branches"][branch_index]["subbranches"][subbranch_index].has("subsubbones"):
			diagram_data["spine"]["branches"][branch_index]["subbranches"][subbranch_index]["subsubbones"] = []

		diagram_data["spine"]["branches"][branch_index]["subbranches"][subbranch_index]["subsubbones"].append(subsubbone_data)
		print("Added subsubbone to data structure")
		print("Subsubbones array now: ", diagram_data["spine"]["branches"][branch_index]["subbranches"][subbranch_index]["subsubbones"])
	else:
		print("Could not find matching branch and subbranch in data structure")
	
	update_diagram()


func delete_element(element_container):
	# First handle branches (VBoxContainer)
	if element_container is VBoxContainer:
		for i in range(diagram_data["spine"]["branches"].size()):
			if diagram_data["spine"]["branches"][i]["container_ref"] == element_container:
				diagram_data["spine"]["branches"].remove_at(i)
				break
		# Remove the UI hierarchy
		var margin_parent = element_container.get_parent()
		if margin_parent is MarginContainer:
			margin_parent.queue_free()
			# Handle subbranches (HBoxContainer)
	elif element_container is HBoxContainer:
		var is_subsubbone = false
		for branch in diagram_data["spine"]["branches"]:
			for subbranch in branch["subbranches"]:
				if subbranch.has("subsubbones"):
					for k in range(subbranch["subsubbones"].size() - 1, -1, -1):
						if subbranch["subsubbones"][k]["container_ref"] == element_container:
							subbranch["subsubbones"].remove_at(k)
							is_subsubbone = true
							break
					if is_subsubbone:
						break
				if is_subsubbone:
					break
			
			if not is_subsubbone:
				for b in diagram_data["spine"]["branches"]:
					var subbranches = b["subbranches"]
					for j in range(subbranches.size() - 1, -1, -1):  # Iterate backwards to safely remove
						if subbranches[j]["container_ref"] == element_container:
							subbranches.remove_at(j)
							break
		# Remove the UI hierarchy
		var margin_parent = element_container.get_parent()
		if margin_parent is MarginContainer:
			margin_parent.queue_free()
			
	update_diagram()  # Redraw the diagram


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
		var found = false
		for branch in diagram_data["spine"]["branches"]:
			if label == branch["label_ref"]:
				branch["name"] = new_text
				found = true
				break
			
			if not found:
				for sub in branch["subbranches"]:
					if label == sub["label_ref"]:
						sub["name"] = new_text
						found = true
						break
					
					# HIGHLIGHT: Add check for subsubbones
					if not found and sub.has("subsubbones"):
						for subsub in sub["subsubbones"]:
							if label == subsub["label_ref"]:
								subsub["name"] = new_text
								found = true
								break
						if found:
							break
				if found:
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
	
	#Draw spine label
	var spine_name_pos = Vector2(
	spine_end.x+3,
	spine_start.y+5)
	canvas.draw_string(font, spine_name_pos, diagram_data["spine"]["name"], HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.BLACK)
	
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
				var text_pos = Vector2.ZERO
				if sub_direction == -1:  # Left side
					text_pos = sub_start - Vector2(text_width+7, 10)
					canvas.draw_string(font, text_pos, subbranch["name"], HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size, Color.BLACK)
				else:  # Right side
					text_pos = sub_start + Vector2(8, -10)
					canvas.draw_string(font, text_pos, subbranch["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.BLACK)
	
				# Draw subsubbones
				if subbranch.has("subsubbones"):
					var subsubbone_count = subbranch["subsubbones"].size()
					if subsubbone_count > 0:
						# Calculate base parameters
						var min_length = sub_length * 0.4
						var length_step = sub_length * length_step_modifier  # Length increment per subsubbone
						var sub_angle = deg_to_rad(45)  # 45 degree angle

						for k in range(subsubbone_count):
							var subsubbone = subbranch["subsubbones"][k]

							# Calculate position along subbone (evenly spaced)
							var progress = (k + 1) / float(subsubbone_count + 1)
							var subsub_start = sub_start.lerp(subbranch_end, progress)

							# Progressive length - first is shortest
							var line_length = min_length + (length_step * (subsubbone_count - 1 - k))

							# Calculate end point (45° downward)
							var subsub_end = subsub_start + Vector2(
							cos(sub_angle) * line_length * sub_direction,
							sin(sub_angle) * line_length
							)

							# Draw the line
							canvas.draw_line(subsub_start, subsub_end, Color(0, 0, 0), 1.5)

							# Text positioning at end of line
							var text = subsubbone["name"]
							var sub_text_width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x

							if sub_direction < 0:  # Left-pointing subbone
								var sub_text_pos = subsub_end - Vector2(sub_text_width + 5, -5)
								canvas.draw_string(font, sub_text_pos, text, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size, Color.BLACK)
							else:  # Right-pointing subbone
								var sub_text_pos = subsub_end + Vector2(5, 5)
								canvas.draw_string(font, sub_text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.BLACK)


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

func _on_save_button_pressed():
	# Create a FileDialog to choose where to save
	file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.current_path = "pareto_diagram.png"
	file_dialog.add_filter("*.png ; PNG Images")
	
	# Connect signal
	file_dialog.connect("file_selected", _prepare_screenshot)
	file_dialog.connect("canceled", _cancel_screenshot)
	
	# Add dialog to scene and show it
	add_child(file_dialog)
	file_dialog.popup_centered(Vector2(500, 400))

func _prepare_screenshot(path):
	# Store the path for saving
	var save_path = path
	
	# Remove file dialog so it's not in the screenshot
	if file_dialog:
		file_dialog.queue_free()
		file_dialog = null
		
	# Hide the save button temporarily
	var was_visible = save_button.visible
	save_button.visible = false
	
	# Wait for two frames to ensure UI updates
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Now take the screenshot and save
	_take_screenshot(save_path)
	
	# Restore the save button visibility
	save_button.visible = was_visible

func _cancel_screenshot():
	if file_dialog:
		file_dialog.queue_free()
		file_dialog = null

func _take_screenshot(path):
	# The actual screenshot code here
	var capture_img = get_viewport().get_texture().get_image()
	
	# Get the global rect of our diagram container
	var global_rect = diagram_container.get_global_rect()
	
	# Crop to just the diagram area
	capture_img = capture_img.get_region(global_rect)
	
	# Save the image
	var error = capture_img.save_png(path)
	if error != OK:
		print("Error saving image: ", error)
		
		# Show error dialog
		var error_dialog = AcceptDialog.new()
		error_dialog.dialog_text = "Error saving diagram to: " + path
		add_child(error_dialog)
		error_dialog.popup_centered()
	else:
		print("Image saved successfully to: ", path)
		
		# Show a confirmation dialog
		var confirm_dialog = AcceptDialog.new()
		confirm_dialog.dialog_text = "Diagram saved successfully to:\n" + path
		add_child(confirm_dialog)
		confirm_dialog.popup_centered()
