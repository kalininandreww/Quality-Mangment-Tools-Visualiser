extends Control

# Exportable variables
@export var min_bar_value: float = 0.0
@export var other_name: String = "Others"
@export_color_no_alpha var axis_color: Color = Color.WHITE
@export_color_no_alpha var bar_text_color: Color = Color.WHITE
@export_color_no_alpha var cumulative_line_color: Color = Color.RED
@export_color_no_alpha var cutoff_line_color: Color = Color.YELLOW

# Node references
@onready var split_container = $SplitContainer
@onready var parameters_container = %ParametersContainer
@onready var add_button = %AddButton
@onready var diagram_container = %DiagramContainer
@onready var save_button = %SaveButton

# Constants
const PARAM_SCENE = preload("res://Scenes/sc_parameter_item.tscn")
const MARGIN_LEFT = 60
const MARGIN_RIGHT = 60
const MARGIN_TOP = 40
const MARGIN_BOTTOM = 60
const BAR_GAP = 10
const MAX_NAME_WIDTH = 150

# Data storage
var parameters = []
var file_dialog = null

func _ready():
	add_button.text = "Add Parameter"
	add_button.connect("pressed", _on_add_button_pressed)
	
	# Setup save button
	save_button.text = "Save as PNG"
	save_button.connect("pressed", _on_save_button_pressed)
	
	# Add initial parameter for testing
	_on_add_button_pressed()
	_on_add_button_pressed()
	
	# Set up diagram container for drawing
	diagram_container.connect("draw", _draw_diagram)

func _on_add_button_pressed():
	var param_item = PARAM_SCENE.instantiate()
	parameters_container.add_child(param_item)
	
	# Add before the Add button
	parameters_container.move_child(param_item, parameters_container.get_child_count() - 1)
	
	# Connect signals
	param_item.connect("name_changed", _update_diagram)
	param_item.connect("value_changed", _update_diagram)
	param_item.connect("deleted", _on_parameter_deleted)
	
	_update_diagram()

func _on_parameter_deleted(param_item):
	# Remove from tree immediately
	parameters_container.remove_child(param_item)
	param_item.queue_free()
	
	# Update diagram immediately
	_update_diagram()

func _update_diagram():
	# Collect parameters data
	parameters.clear()
	
	for child in parameters_container.get_children():
		if child == add_button:
			continue
			
		if child.get_parameter_value() > min_bar_value:
			parameters.append({
				"name": child.get_parameter_name(),
				"value": child.get_parameter_value()
			})
	
	# Sort parameters by value (descending)
	if parameters.size() > 0:
		parameters.sort_custom(func(a, b): return a.value > b.value)
		
		# Move "Others" to the end
		var others_index = -1
		for i in range(parameters.size()):
			if parameters[i].name == other_name:
				others_index = i
				break
		
		if others_index != -1:
			var others = parameters[others_index]
			parameters.remove_at(others_index)
			parameters.append(others)
		
		# Calculate total and cumulative percentages
		var total = 0
		for param in parameters:
			total += param.value
		
		var cumulative = 0
		for param in parameters:
			param.percentage = param.value / total * 100 if total > 0 else 0
			cumulative += param.percentage
			param.cumulative = cumulative
	
	# Request redraw
	diagram_container.queue_redraw()

func _draw_diagram():
	var canvas = diagram_container
	var rect = canvas.get_rect()
	var width = rect.size.x - MARGIN_LEFT - MARGIN_RIGHT
	var height = rect.size.y - MARGIN_TOP - MARGIN_BOTTOM
	
	# Skip if no data or no space
	if parameters.size() == 0 or width <= 0 or height <= 0:
		return
	
	var font = ThemeDB.fallback_font
	var font_size = 14
	
	# Draw axes
	var start_x = MARGIN_LEFT
	var end_x = rect.size.x - MARGIN_RIGHT
	var start_y = rect.size.y - MARGIN_BOTTOM
	var end_y = MARGIN_TOP
	
	# X-axis
	canvas.draw_line(Vector2(start_x, start_y), Vector2(end_x, start_y), axis_color, 2)
	# Y-axis
	canvas.draw_line(Vector2(start_x, start_y), Vector2(start_x, end_y), axis_color, 2)
	
	# Calculate bar width
	var bar_width = (width - BAR_GAP * (parameters.size() - 1)) / parameters.size()
	
	# Draw bars and names
	var x = start_x
	var points = []  # For cumulative line
	
	for i in range(parameters.size()):
		var param = parameters[i]
		var bar_height = (param.value / parameters[0].value) * height if parameters[0].value > 0 else 0
		var bar_x = x
		var bar_y = start_y - bar_height
		
		# Draw bar
		var color = Color(0.2 + 0.6 * (i / float(parameters.size())), 
						  0.7 - 0.4 * (i / float(parameters.size())), 
						  0.9 - 0.6 * (i / float(parameters.size())))
		canvas.draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), color)
		
		# Draw parameter name
		var name_text = param.name
		var font_height = font.get_height(font_size)
		var text_width = font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		
		# Handle long names that might be wider than the bar
		if text_width > bar_width:
			var words = name_text.split(" ")
			var lines = []
			var current_line = ""
			
			for word in words:
				var test_line = current_line + " " + word if current_line else word
				var test_width = font.get_string_size(test_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
				
				if test_width <= bar_width:
					current_line = test_line
				else:
					if current_line:
						lines.append(current_line)
						current_line = word
					else:
						# If a single word is too long, force it on its own line
						lines.append(word)
						current_line = ""
			
			if current_line:
				lines.append(current_line)
			
			for j in range(lines.size()):
				canvas.draw_string(font, Vector2(bar_x + bar_width/2 - font.get_string_size(lines[j], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x/2, 
											 start_y + 10 + j * font_height), 
								lines[j], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, bar_text_color)
		else:
			canvas.draw_string(font, Vector2(bar_x + bar_width/2 - text_width/2, start_y + 10 + font_height), 
							name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, bar_text_color)
		
		# Draw value on top of the bar
		var value_text = str(param.value)
		var value_width = font.get_string_size(value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		canvas.draw_string(font, Vector2(bar_x + bar_width/2 - value_width/2, bar_y - 5), 
						value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, bar_text_color)
		
		# Add point for cumulative line
		points.append(Vector2(bar_x + bar_width/2, start_y - (param.cumulative / 100) * height))
		
		# Move to next bar position
		x += bar_width + BAR_GAP
	
	# Draw cumulative percentage line
	if points.size() > 1:
		for i in range(points.size() - 1):
			canvas.draw_line(points[i], points[i + 1], cumulative_line_color, 2)
	
	# Draw percentage labels on right side
	for i in range(0, 101, 20):
		var y_pos = start_y - (i / 100.0) * height
		var percent_text = str(i) + "%"
		var text_width = font.get_string_size(percent_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		
		# Draw tick
		canvas.draw_line(Vector2(end_x - 5, y_pos), Vector2(end_x, y_pos), axis_color, 1)
		
		# Draw percentage text
		canvas.draw_string(font, Vector2(end_x + 5, y_pos + font_size/4), 
					percent_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, bar_text_color)
	
	# Draw 80% horizontal line (Pareto principle)
	var y_80 = start_y - 0.8 * height
	canvas.draw_dashed_line(Vector2(start_x, y_80), Vector2(end_x, y_80), cutoff_line_color, 1, 5)
	
	# Draw "80%" label
	canvas.draw_string(font, Vector2(start_x - font.get_string_size("80%", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x - 5, y_80 + font_size/4), 
				"80%", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, bar_text_color)

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
