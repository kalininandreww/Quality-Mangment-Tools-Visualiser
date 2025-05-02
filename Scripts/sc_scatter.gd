extends Control

# Exportable variables
var background_color: Color = Color("#FEFAE0")
var axis_color: Color = Color.WHITE
var label_text_color: Color = Color.WHITE  # For all UI labels
var input_text_color: Color = Color.WHITE  # For TextEdit input
var point_color: Color = Color(0.2, 0.7, 0.9)  # Color for data points
var regression_line_color: Color = Color.RED
var grid_color: Color = Color(0.3, 0.3, 0.3, 0.5)

# Node references
@onready var split_container = $SplitContainer #
@onready var scroll_container = %ScrollContainer #
@onready var input_container = %InputContainer #
@onready var data_input_x = %DataInputX #
@onready var data_input_y = %DataInputY #
@onready var single_data_mode_checkbox = %SingleDataModeCheckBox #
@onready var checkbox_label = %CheckboxLabel #
@onready var axis_label = %AxisNamesLabel
@onready var x_axis_label_input = %XAxisLabelInput #
@onready var y_axis_label_input = %YAxisLabelInput #
@onready var analyze_button = %AnalyzeButton #
@onready var diagram_container = %DiagramContainer #
@onready var save_button = %SaveButton #
@onready var stats_label = %StatsLabel #

# Constants
const MARGIN_LEFT = 80
const MARGIN_RIGHT = 60
const MARGIN_TOP = 40
const MARGIN_BOTTOM = 60
const POINT_RADIUS = 5
const GRID_LINE_COUNT = 5

# Data storage
var x_data = []
var y_data = []
var statistics = {
	"x_mean": 0.0,
	"y_mean": 0.0,
	"x_std_dev": 0.0,
	"y_std_dev": 0.0,
	"correlation": 0.0,
	"slope": 0.0,
	"intercept": 0.0,
	"sample_size": 0
}
var file_dialog = null
var single_data_mode = true

func _ready():
	ESCManager.register_tool(self, "scatter")
	load_config_colors()
	# Apply text colors to UI elements
	_apply_text_colors()
	
	# Set up analyze button
	analyze_button.text = "Анализировать данные"
	analyze_button.connect("pressed", _on_analyze_button_pressed)
	
	# Setup save button
	save_button.text = "Сохранить"
	save_button.connect("pressed", _on_save_button_pressed)
	
	# Setup data input placeholders
	data_input_x.placeholder_text = "Введите данные разделенные запятой (пример: 1.2, 3.4, 5.6)"
	data_input_y.placeholder_text = "Введите Y-значения разделенные запятой (пример: 2.3, 4.5, 6.7)"
	data_input_y.visible = false
	
	# Setup axis label inputs
	x_axis_label_input.placeholder_text = "Название оси X"
	y_axis_label_input.placeholder_text = "Название оси Y"
	
	# Set up diagram container for drawing
	diagram_container.connect("draw", _draw_scatter_plot)
	
	# Setup the checkbox for data input mode
	single_data_mode_checkbox.button_pressed = true
	single_data_mode_checkbox.connect("toggled", _on_data_mode_toggled)


func load_config_colors():
	var config = ConfigFile.new()
	var err = config.load("user://ui_settings.cfg")
	if err != OK:
		print("No config file found. Using default colors.")
		return
	
	background_color =      config.get_value("scatter", "background_color", Color("#FEFAE0"))
	axis_color =            config.get_value("scatter", "axis_color", Color.BLACK)
	label_text_color =      config.get_value("scatter", "label_text_color", Color.BLACK)
	input_text_color =      config.get_value("scatter", "input_text_color", Color.WHITE)
	point_color =           config.get_value("scatter", "point_color", Color(0.506607, 0.591869, 0.847656, 1))
	regression_line_color = config.get_value("scatter", "regression_line_color", Color(0.454902, 0.960784, 0.592157, 1))
	grid_color =            config.get_value("scatter", "grid_color", Color(0.3, 0.3, 0.3, 0.5))


func update_colors():
	%DiagramContainer.queue_redraw()
	%Background.color = background_color
	_apply_text_colors()
	_draw_scatter_plot()
	

func _apply_text_colors():
	# Apply text colors to all relevant UI elements
	checkbox_label.add_theme_color_override("font_color", label_text_color)
	stats_label.add_theme_color_override("font_color", label_text_color)
	axis_label.add_theme_color_override("font_color", label_text_color)
	
	data_input_x.add_theme_color_override("font_color", input_text_color)
	data_input_y.add_theme_color_override("font_color", input_text_color)
	x_axis_label_input.add_theme_color_override("font_color", input_text_color)
	y_axis_label_input.add_theme_color_override("font_color", input_text_color)
	
	analyze_button.add_theme_color_override("font_color", label_text_color)
	save_button.add_theme_color_override("font_color", label_text_color)

func _on_data_mode_toggled(button_pressed):
	single_data_mode = button_pressed
	data_input_y.visible = not single_data_mode
	
	if single_data_mode:
		data_input_x.placeholder_text = "Введите пары X,Y разделенные запятой (пример: 1.2,2.3, 3.4,4.5, 5.6,6.7)"
	else:
		data_input_x.placeholder_text = "Введите X-значения разделенные запятой (пример: 1.2, 3.4, 5.6)"

func _on_analyze_button_pressed():
	# Clear previous data
	x_data.clear()
	y_data.clear()
	
	if single_data_mode:
		var text = data_input_x.text.strip_edges()
		if text.is_empty():
			_show_error("Введите данные")
			return
		
		# Parse the comma-separated pairs
		var values = text.split(",")
		var current_x = null
		
		for i in range(values.size()):
			var trimmed = values[i].strip_edges()
			
			if current_x == null:
				# We're looking for an x value
				if trimmed.is_valid_float():
					current_x = float(trimmed)
				else:
					_show_error("Invalid X value: " + trimmed)
					return
			else:
				# We're looking for a y value
				if trimmed.is_valid_float():
					x_data.append(current_x)
					y_data.append(float(trimmed))
					current_x = null
				else:
					_show_error("Invalid Y value: " + trimmed)
					return
		
		# Check if we have a dangling x value
		if current_x != null:
			_show_error("Uneven number of values. Each X needs a corresponding Y.")
			return
	else:
		# Separate X and Y inputs
		var x_text = data_input_x.text.strip_edges()
		var y_text = data_input_y.text.strip_edges()
		
		if x_text.is_empty() or y_text.is_empty():
			_show_error("Введите данные для обеих осей")
			return
		
		# Parse X values
		var x_values = x_text.split(",")
		for val_str in x_values:
			var trimmed = val_str.strip_edges()
			if trimmed.is_valid_float():
				x_data.append(float(trimmed))
			else:
				_show_error("Invalid X value: " + trimmed)
				return
		
		# Parse Y values
		var y_values = y_text.split(",")
		for val_str in y_values:
			var trimmed = val_str.strip_edges()
			if trimmed.is_valid_float():
				y_data.append(float(trimmed))
			else:
				_show_error("Invalid Y value: " + trimmed)
				return
		
		# Check if X and Y arrays have the same length
		if x_data.size() != y_data.size():
			_show_error("Количество X и Y значений должно совпадать")
			return
	
	# Check if we have enough data points
	if x_data.size() < 2:
		_show_error("Введите хотя бы две пары значений для осмысленного анализа")
		return
	
	# Calculate statistics
	_calculate_statistics()
	_update_statistics_label()
	diagram_container.queue_redraw()

func _calculate_statistics():
	statistics.sample_size = x_data.size()
	
	# Calculate mean values
	var sum_x = 0.0
	var sum_y = 0.0
	
	for i in range(statistics.sample_size):
		sum_x += x_data[i]
		sum_y += y_data[i]
	
	statistics.x_mean = sum_x / statistics.sample_size
	statistics.y_mean = sum_y / statistics.sample_size
	
	# Calculate standard deviations and covariance
	var sum_x_squared_diff = 0.0
	var sum_y_squared_diff = 0.0
	var sum_xy_diff = 0.0
	
	for i in range(statistics.sample_size):
		var x_diff = x_data[i] - statistics.x_mean
		var y_diff = y_data[i] - statistics.y_mean
		
		sum_x_squared_diff += x_diff * x_diff
		sum_y_squared_diff += y_diff * y_diff
		sum_xy_diff += x_diff * y_diff
	
	statistics.x_std_dev = sqrt(sum_x_squared_diff / statistics.sample_size)
	statistics.y_std_dev = sqrt(sum_y_squared_diff / statistics.sample_size)
	
	# Calculate Pearson correlation coefficient
	if statistics.x_std_dev > 0 and statistics.y_std_dev > 0:
		statistics.correlation = sum_xy_diff / (statistics.sample_size * statistics.x_std_dev * statistics.y_std_dev)
	else:
		statistics.correlation = 0.0
	
	# Calculate regression line (y = mx + b)
	if statistics.x_std_dev > 0:
		statistics.slope = sum_xy_diff / sum_x_squared_diff
		statistics.intercept = statistics.y_mean - statistics.slope * statistics.x_mean
	else:
		statistics.slope = 0.0
		statistics.intercept = statistics.y_mean

func _update_statistics_label():
	var text = "Статистика:\n"
	text += "Размер выборки: " + str(statistics.sample_size) + "\n"
	text += "Среднее X: " + str(snapped(statistics.x_mean, 0.001)) + "\n"
	text += "Среднее Y: " + str(snapped(statistics.y_mean, 0.001)) + "\n"
	text += "Среднекв. отклонение X: " + str(snapped(statistics.x_std_dev, 0.001)) + "\n"
	text += "Среднекв. отклонение Y: " + str(snapped(statistics.y_std_dev, 0.001)) + "\n"
	text += "Коэффициент корреляции: " + str(snapped(statistics.correlation, 0.001)) + "\n"
	text += "Уравнение регрессии: Y = " + str(snapped(statistics.slope, 0.001)) + "X + " + str(snapped(statistics.intercept, 0.001))
	
	stats_label.text = text

func _show_error(message):
	var error_dialog = AcceptDialog.new()
	error_dialog.dialog_text = message
	error_dialog.add_theme_color_override("font_color", label_text_color)
	add_child(error_dialog)
	error_dialog.popup_centered()

func _draw_scatter_plot():
	var canvas = diagram_container
	var rect = canvas.get_rect()
	var width = rect.size.x - MARGIN_LEFT - MARGIN_RIGHT
	var height = rect.size.y - MARGIN_TOP - MARGIN_BOTTOM
	
	# Skip if no data or no space
	if x_data.size() == 0 or width <= 0 or height <= 0:
		return
	
	var font = ThemeDB.fallback_font
	var font_size = 14
	
	# Find min and max values for axes
	var x_min = x_data[0]
	var x_max = x_data[0]
	var y_min = y_data[0]
	var y_max = y_data[0]
	
	for i in range(1, x_data.size()):
		x_min = min(x_min, x_data[i])
		x_max = max(x_max, x_data[i])
		y_min = min(y_min, y_data[i])
		y_max = max(y_max, y_data[i])
	
	# Add some padding to the ranges
	var x_range = x_max - x_min
	var y_range = y_max - y_min
	
	if x_range == 0:
		x_range = 1.0
		x_min -= 0.5
		x_max += 0.5
	else:
		var padding = x_range * 0.1
		x_min -= padding
		x_max += padding
		x_range = x_max - x_min
	
	if y_range == 0:
		y_range = 1.0
		y_min -= 0.5
		y_max += 0.5
	else:
		var padding = y_range * 0.1
		y_min -= padding
		y_max += padding
		y_range = y_max - y_min
	
	# Calculate scales
	var x_scale = width / x_range
	var y_scale = height / y_range
	
	# Draw grid
	_draw_grid(canvas, x_min, x_max, y_min, y_max, width, height)
	
	# Draw axes
	var start_x = MARGIN_LEFT
	var end_x = rect.size.x - MARGIN_RIGHT
	var start_y = rect.size.y - MARGIN_BOTTOM
	var end_y = MARGIN_TOP
	
	# X-axis
	canvas.draw_line(Vector2(start_x, start_y), Vector2(end_x, start_y), axis_color, 2)
	# Y-axis
	canvas.draw_line(Vector2(start_x, start_y), Vector2(start_x, end_y), axis_color, 2)
	
	# Draw axis labels
	var x_label = x_axis_label_input.text if not x_axis_label_input.text.is_empty() else "X"
	var y_label = y_axis_label_input.text if not y_axis_label_input.text.is_empty() else "Y"
	
	# X-axis label
	var x_label_width = font.get_string_size(x_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	canvas.draw_string(font, Vector2(start_x + width/2 - x_label_width/2, start_y + 45), 
				x_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_text_color)
	
	# Y-axis label (rotated)
	var y_label_width = font.get_string_size(y_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var rotation = -PI/2  # -90 degrees
	var y_label_pos = Vector2(start_x - 45, start_y - height/2)
	
	canvas.draw_set_transform(y_label_pos, rotation, Vector2(1, 1))
	canvas.draw_string(font, Vector2(-y_label_width/2, 0), 
				y_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_text_color)
	canvas.draw_set_transform(Vector2.ZERO, 0, Vector2(1, 1))  # Reset transform
	
	# Draw axis ticks and values
	_draw_axis_ticks(canvas, x_min, x_max, y_min, y_max, width, height, font, font_size)
	
	# Draw data points
	for i in range(x_data.size()):
		var x_pos = start_x + (x_data[i] - x_min) * x_scale
		var y_pos = start_y - (y_data[i] - y_min) * y_scale
		
		# Draw circle for each point
		canvas.draw_circle(Vector2(x_pos, y_pos), POINT_RADIUS, point_color)
	
	# Draw regression line if we have valid statistics
	if statistics.sample_size >= 2:
		# Calculate two points on the regression line
		var line_x1 = x_min
		var line_y1 = statistics.slope * line_x1 + statistics.intercept
		var line_x2 = x_max
		var line_y2 = statistics.slope * line_x2 + statistics.intercept
		
		# Convert to screen coordinates
		var screen_x1 = start_x + (line_x1 - x_min) * x_scale
		var screen_y1 = start_y - (line_y1 - y_min) * y_scale
		var screen_x2 = start_x + (line_x2 - x_min) * x_scale
		var screen_y2 = start_y - (line_y2 - y_min) * y_scale
		
		# Draw the line
		canvas.draw_line(Vector2(screen_x1, screen_y1), Vector2(screen_x2, screen_y2), regression_line_color, 2)
		
		# Draw equation near the line
		#var equation = "y = " + str(snapped(statistics.slope, 0.01)) + "x + " + str(snapped(statistics.intercept, 0.01))
		#canvas.draw_string(font, Vector2(end_x - 200, end_y + 20), 
					#equation, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, regression_line_color)

func _draw_grid(canvas, x_min, x_max, y_min, y_max, width, height):
	var start_x = MARGIN_LEFT
	var start_y = canvas.get_rect().size.y - MARGIN_BOTTOM
	
	# Draw vertical grid lines
	for i in range(GRID_LINE_COUNT + 1):
		var t = i / float(GRID_LINE_COUNT)
		var x_pos = start_x + t * width
		
		# Skip the main axes
		if i > 0 and i < GRID_LINE_COUNT:
			canvas.draw_dashed_line(Vector2(x_pos, start_y), Vector2(x_pos, MARGIN_TOP), grid_color, 1, 5)
	
	# Draw horizontal grid lines
	for i in range(GRID_LINE_COUNT + 1):
		var t = i / float(GRID_LINE_COUNT)
		var y_pos = start_y - t * height
		
		# Skip the main axes
		if i > 0 and i < GRID_LINE_COUNT:
			canvas.draw_dashed_line(Vector2(start_x, y_pos), Vector2(start_x + width, y_pos), grid_color, 1, 5)

func _draw_axis_ticks(canvas, x_min, x_max, y_min, y_max, width, height, font, font_size):
	var start_x = MARGIN_LEFT
	var start_y = canvas.get_rect().size.y - MARGIN_BOTTOM
	
	# Draw x-axis ticks and values
	for i in range(GRID_LINE_COUNT + 1):
		var t = i / float(GRID_LINE_COUNT)
		var x_pos = start_x + t * width
		var x_val = x_min + t * (x_max - x_min)
		
		# Draw tick
		canvas.draw_line(Vector2(x_pos, start_y), Vector2(x_pos, start_y + 5), axis_color, 1)
		
		# Draw value
		var value_text = str(snapped(x_val, 0.01))
		var text_width = font.get_string_size(value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		canvas.draw_string(font, Vector2(x_pos - text_width/2, start_y + 20), 
					value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_text_color)
	
	# Draw y-axis ticks and values
	for i in range(GRID_LINE_COUNT + 1):
		var t = i / float(GRID_LINE_COUNT)
		var y_pos = start_y - t * height
		var y_val = y_min + t * (y_max - y_min)
		
		# Draw tick
		canvas.draw_line(Vector2(start_x, y_pos), Vector2(start_x - 5, y_pos), axis_color, 1)
		
		# Draw value
		var value_text = str(snapped(y_val, 0.01))
		var text_width = font.get_string_size(value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		canvas.draw_string(font, Vector2(start_x - text_width - 10, y_pos + font_size/4), 
					value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_text_color)

func _on_save_button_pressed():
	# Create a FileDialog to choose where to save
	file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.current_path = "scatterplot.png"
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
		error_dialog.dialog_text = "Error saving scatter plot to: " + path
		error_dialog.add_theme_color_override("font_color", label_text_color)
		add_child(error_dialog)
		error_dialog.popup_centered()
	else:
		print("Image saved successfully to: ", path)
		
		# Show a confirmation dialog
		var confirm_dialog = AcceptDialog.new()
		confirm_dialog.dialog_text = "Scatter plot saved successfully to:\n" + path
		confirm_dialog.add_theme_color_override("font_color", label_text_color)
		add_child(confirm_dialog)
		confirm_dialog.popup_centered()
