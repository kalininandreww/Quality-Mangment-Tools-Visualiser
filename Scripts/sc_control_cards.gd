extends Control

# Exportable variables
var background_color: Color = Color("#FEFAE0")
var axis_color: Color = Color.WHITE
var label_text_color: Color = Color.WHITE
var input_text_color: Color = Color.WHITE
var grid_color: Color = Color(0.3, 0.3, 0.3)
var x_line_color: Color = Color(0.2, 0.7, 0.9)  # Line for X values
var r_line_color: Color = Color(0.8, 0.3, 0.3)  # Line for R values
var ucl_color: Color = Color.RED
var lcl_color: Color = Color.RED
var cl_color: Color = Color.GREEN
var out_of_control_color: Color = Color.YELLOW
var warning_color: Color = Color.ORANGE

# Node references
@onready var split_container = %SplitContainer
@onready var scroll_container = %ScrollContainer
@onready var ui_container = %UIContainer
@onready var chart_buttons = %ButtonsContainer
@onready var xr_button = %XRButton
@onready var u_button = %UButton
@onready var z_button = %ZButton
@onready var input_area = %InputContainer
@onready var analyze_button = %AnalyseButton
@onready var stats_label = %StatsLabel
@onready var diagram_container = %DiagramContainer
@onready var save_button = %SaveButton

# Scene references
const SUBGROUP_SCENE = preload("res://Scenes/sc_subgroup_item.tscn")


# Constants
const MARGIN_LEFT = 80
const MARGIN_RIGHT = 60
const MARGIN_TOP = 40
const MARGIN_BOTTOM = 60
const POINT_RADIUS = 4
const LINE_WIDTH = 2
const GRID_LINE_WIDTH = 1

# Control chart constants based on GOST R ISO standards
const A2_FACTORS = {
	2: 1.880,
	3: 1.023,
	4: 0.729,
	5: 0.577,
	6: 0.483,
	7: 0.419,
	8: 0.373,
	9: 0.337,
	10: 0.308,
	11: 0.285,
	12: 0.266,
	13: 0.249,
	14: 0.235,
	15: 0.223,
	16: 0.212,
	17: 0.203,
	18: 0.194,
	19: 0.187,
	20: 0.180,
	21: 0.173,
	22: 0.167,
	23: 0.162,
	24: 0.157,
	25: 0.153
}

const D3_FACTORS = {
	2: 0,
	3: 0,
	4: 0,
	5: 0,
	6: 0,
	7: 0.076,
	8: 0.136,
	9: 0.184,
	10: 0.223,
	11: 0.256,
	12: 0.283,
	13: 0.307,
	14: 0.328,
	15: 0.347,
	16: 0.363,
	17: 0.378,
	18: 0.391,
	19: 0.403,
	20: 0.415,
	21: 0.425,
	22: 0.434,
	23: 0.443,
	24: 0.451,
	25: 0.459
}

const D4_FACTORS = {
	2: 3.267,
	3: 2.575,
	4: 2.282,
	5: 2.115,
	6: 2.004,
	7: 1.924,
	8: 1.864,
	9: 1.816,
	10: 1.777,
	11: 1.744,
	12: 1.717,
	13: 1.693,
	14: 1.672,
	15: 1.653,
	16: 1.637,
	17: 1.622,
	18: 1.609,
	19: 1.597,
	20: 1.585,
	21: 1.575,
	22: 1.566,
	23: 1.557,
	24: 1.549,
	25: 1.541
}

# State variables
var current_chart_type = "xr"  # "xr", "z"
var file_dialog = null
var sample_size_input = null

# Data storage
var subgroup_items = []
var defect_items = []
var z_data = {
	"values": [],
	"target_mean": 0.0,
	"std_dev": 0.0
}

# Results storage
var xr_results = {
	"subgroups": [],
	"x_values": [],
	"r_values": [],
	"x_mean": 0.0,
	"r_mean": 0.0,
	"x_ucl": 0.0,
	"x_lcl": 0.0,
	"r_ucl": 0.0,
	"r_lcl": 0.0,
	"sample_size": 0,
	"out_of_control_points_x": [],
	"out_of_control_points_r": [],
	"warning_points_x": [],
	"warning_points_r": []
}

var z_results = {
	"z_values": [],
	"ucl": 3.0,
	"lcl": -3.0,
	"out_of_control_points": [],
	"warning_points": []
}

func _ready():
	ESCManager.register_tool(self, "control_charts")
	load_config_colors()
	# Set up the UI
	_setup_buttons()
	
	# Initial setup for X-R chart (default)
	_setup_xr_chart_ui()
	
	# Set up diagram container for drawing
	diagram_container.connect("draw", _draw_control_chart)
	
	stats_label.add_theme_color_override("font_color", label_text_color)


func load_config_colors():
	var config = ConfigFile.new()
	var err = config.load("user://ui_settings.cfg")
	if err != OK:
		print("No config file found. Using default colors.")
		return
	
	background_color =     config.get_value("control_charts", "background_color", Color("#FEFAE0"))
	axis_color =           	config.get_value("control_charts", "axis_color", Color.BLACK)
	label_text_color =     	config.get_value("control_charts", "label_text_color", Color.BLACK)
	input_text_color =     	config.get_value("control_charts", "input_text_color", Color.WHITE)
	grid_color =           	config.get_value("control_charts", "grid_color", Color(0.419608, 0.419608, 0.423529, 0.356863))
	x_line_color =         	config.get_value("control_charts", "x_line_color", Color(0.4, 0.654902, 0.631005, 1))
	r_line_color =         	config.get_value("control_charts", "r_line_color", Color(0.447059, 0.654902, 0.4, 1))
	ucl_color =            	config.get_value("control_charts", "ucl_color", Color(1, 0.419608, 0.419608, 1))
	lcl_color =            	config.get_value("control_charts", "lcl_color", Color(1, 0.417969, 0.417969, 1))
	cl_color =             	config.get_value("control_charts", "cl_color", Color(0.64967, 0.600739, 0.992188, 1))
	out_of_control_color = 	config.get_value("control_charts", "out_of_control_color", Color(1, 0, 0, 1))
	warning_color =        	config.get_value("control_charts", "warning_color", Color(0.988235, 0.54902, 0.301961, 1))



func update_colors():
	%Background.color = background_color
	stats_label.add_theme_color_override("font_color", label_text_color)
	
	_update_xr_statistics_label()
	_update_z_statistics_label()
	
	_setup_xr_chart_ui()
	_setup_z_chart_ui()
	
	_draw_control_chart()
	
	_on_xr_button_pressed() #do this to clean up

#SETUP BUTTONS

func _setup_buttons():
	# Set up chart type buttons
	xr_button.text = "X-R Карта"
	z_button.text = "Z Карта"
	
	xr_button.connect("pressed", _on_xr_button_pressed)
	z_button.connect("pressed", _on_z_button_pressed)
	
	# Set up analyze button
	analyze_button.text = "Анализировать данные"
	analyze_button.connect("pressed", _on_analyze_button_pressed)
	
	save_button.text = "Сохранить"
	save_button.connect("pressed", _on_save_button_pressed)

# MANAGE BUTTON PRESSES

func _on_xr_button_pressed():
	current_chart_type = "xr"
	_clear_input_area()
	_setup_xr_chart_ui()

func _on_z_button_pressed():
	current_chart_type = "z"
	_clear_input_area()
	_setup_z_chart_ui()

func _clear_input_area():
	# Clear existing children in input area
	for child in input_area.get_children():
		input_area.remove_child(child)
		child.queue_free()
	
	# Clear data
	subgroup_items.clear()
	defect_items.clear()
	
	# Clear stats label
	stats_label.text = ""
	
	# Request redraw of diagram
	diagram_container.queue_redraw()

func _on_add_subgroup_pressed():
	var subgroup_item = SUBGROUP_SCENE.instantiate()
	input_area.add_child(subgroup_item)
	
	# Add before the Add button
	input_area.move_child(subgroup_item, input_area.get_child_count() - 1)
	
	# Connect signals
	subgroup_item.connect("deleted", _on_subgroup_deleted)
	
	# Add to our list
	subgroup_items.append(subgroup_item)

func _on_analyze_button_pressed():
	match current_chart_type:
		"xr":
			_analyze_xr_data()
		"z":
			_analyze_z_data()

# SETUP UI FUNCTIONS

func _setup_xr_chart_ui():
	# Create sample size input
	var sample_size_container = HBoxContainer.new()
	var sample_size_label = Label.new()
	sample_size_label.text = "Размер выборок (n):"
	sample_size_label.add_theme_color_override("font_color", label_text_color)
	
	sample_size_input = LineEdit.new()
	sample_size_input.placeholder_text = "Введите размер выборок (2-25)"
	sample_size_input.add_theme_color_override("font_color", input_text_color)
	sample_size_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	sample_size_container.add_child(sample_size_label)
	sample_size_container.add_child(sample_size_input)
	
	input_area.add_child(sample_size_container)
	
	# Create subgroups label
	var subgroups_label = Label.new()
	subgroups_label.text = "Данные выборок:"
	subgroups_label.add_theme_color_override("font_color", label_text_color)
	input_area.add_child(subgroups_label)
	
	# Add button for adding new subgroups
	var add_button = Button.new()
	add_button.text = "Добавить группу"
	add_button.add_theme_color_override("font_color", label_text_color)
	add_button.connect("pressed", _on_add_subgroup_pressed)
	input_area.add_child(add_button)
	
	# Add initial subgroup
	_on_add_subgroup_pressed()

func _setup_z_chart_ui():
	# Create container for values input
	var values_container = VBoxContainer.new()
	var values_label = Label.new()
	values_label.text = "Средние по подгруппам (Xᵢ):"
	values_label.add_theme_color_override("font_color", label_text_color)
	
	var values_input = TextEdit.new()
	values_input.placeholder_text = "Введите значения разделенные запятой (10.5, 11.2, 10.8, ...)"
	values_input.add_theme_color_override("font_color", input_text_color)
	values_input.size_flags_vertical = Control.SIZE_EXPAND_FILL
	values_input.custom_minimum_size = Vector2(150, 35)
	
	values_container.add_child(values_label)
	values_container.add_child(values_input)
	
	# Create container for target mean input
	var target_container = HBoxContainer.new()
	var target_label = Label.new()
	target_label.text = "Целевое среднее (μ₀):"
	target_label.add_theme_color_override("font_color", label_text_color)
	
	var target_input = LineEdit.new()
	target_input.placeholder_text = "Введите целевое среднее"
	target_input.add_theme_color_override("font_color", input_text_color)
	target_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	target_container.add_child(target_label)
	target_container.add_child(target_input)
	
	# Create container for reference std dev input
	var std_dev_container = HBoxContainer.new()
	var std_dev_label = Label.new()
	std_dev_label.text = "Станд. откл.(σ₀):"
	std_dev_label.add_theme_color_override("font_color", label_text_color)
	
	var std_dev_input = LineEdit.new()
	std_dev_input.placeholder_text = "Введите стандартное отклонение"
	std_dev_input.add_theme_color_override("font_color", input_text_color)
	std_dev_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	std_dev_container.add_child(std_dev_label)
	std_dev_container.add_child(std_dev_input)
	
	# Add all containers to input area
	input_area.add_child(values_container)
	input_area.add_child(target_container)
	input_area.add_child(std_dev_container)
	
	# Store references for later access
	z_data["values_input"] = values_input
	z_data["target_input"] = target_input
	z_data["std_dev_input"] = std_dev_input

# MANAGE DELETION

func _on_subgroup_deleted(subgroup_item):
	# Remove from tree immediately
	input_area.remove_child(subgroup_item)
	
	# Remove from our list
	var index = subgroup_items.find(subgroup_item)
	if index != -1:
		subgroup_items.remove_at(index)
	
	subgroup_item.queue_free()

#ANALYSE DATA

func _analyze_xr_data():
	# Check if sample size is valid
	var sample_size_text = sample_size_input.text.strip_edges()
	if not sample_size_text.is_valid_int():
		_show_error("Введите размер выборок n")
		return
	
	var sample_size = int(sample_size_text)
	if sample_size < 2 or sample_size > 25:
		_show_error("Размер групп должен быть больше 2 и меньше 25")
		return
	
	# Check if we have at least 2 subgroups
	if subgroup_items.size() < 2:
		_show_error("Введите хотя бы 2 подгруппы")
		return
	
	# Reset results
	xr_results.subgroups.clear()
	xr_results.x_values.clear()
	xr_results.r_values.clear()
	xr_results.out_of_control_points_x.clear()
	xr_results.out_of_control_points_r.clear()
	xr_results.warning_points_x.clear()
	xr_results.warning_points_r.clear()
	
	# Process each subgroup
	var subgroups_with_errors = []
	
	for i in range(subgroup_items.size()):
		var subgroup_item = subgroup_items[i]
		var measurements_text = subgroup_item.get_measurements().strip_edges()
		var measurements = measurements_text.split(",")
		
		# Check if this subgroup has the correct number of measurements
		if measurements.size() != sample_size:
			subgroups_with_errors.append(i + 1)  # +1 for human-readable numbering
			continue
		
		# Convert measurements to float values
		var values = []
		var valid_measurements = true
		
		for measurement in measurements:
			var trimmed = measurement.strip_edges()
			if trimmed.is_valid_float():
				values.append(float(trimmed))
			else:
				valid_measurements = false
				subgroups_with_errors.append(i + 1)
				break
		
		if valid_measurements:
			xr_results.subgroups.append(values)
	
	if subgroups_with_errors.size() > 0:
		var error_msg = "The following subgroups have invalid data or wrong sample size: "
		error_msg += ", ".join(subgroups_with_errors.map(func(num): return str(num)))
		_show_error(error_msg)
		return
	
	# Calculate X and R values for each subgroup
	for subgroup in xr_results.subgroups:
		# Mean value for subgroup
		var subgroup_sum = 0.0
		for value in subgroup:
			subgroup_sum += value
		var x_value = subgroup_sum / subgroup.size()
		xr_results.x_values.append(x_value)
		
		# Range value for subgroup
		var min_val = subgroup[0]
		var max_val = subgroup[0]
		for value in subgroup:
			min_val = min(min_val, value)
			max_val = max(max_val, value)
		var r_value = max_val - min_val
		xr_results.r_values.append(r_value)
	
	# Calculate control limits
	xr_results.sample_size = sample_size
	
	# Calculate X-bar mean
	var x_sum = 0.0
	for x_value in xr_results.x_values:
		x_sum += x_value
	xr_results.x_mean = x_sum / xr_results.x_values.size()
	
	# Calculate R-bar mean
	var r_sum = 0.0
	for r_value in xr_results.r_values:
		r_sum += r_value
	xr_results.r_mean = r_sum / xr_results.r_values.size()
	
	# Calculate control limits according to ISO standards
	var a2 = A2_FACTORS[sample_size]
	var d3 = D3_FACTORS[sample_size]
	var d4 = D4_FACTORS[sample_size]
	
	xr_results.x_ucl = xr_results.x_mean + a2 * xr_results.r_mean
	xr_results.x_lcl = xr_results.x_mean - a2 * xr_results.r_mean
	xr_results.r_ucl = d4 * xr_results.r_mean
	xr_results.r_lcl = d3 * xr_results.r_mean
	
	# Check for out of control points (beyond control limits)
	for i in range(xr_results.x_values.size()):
		var x_value = xr_results.x_values[i]
		if x_value > xr_results.x_ucl or x_value < xr_results.x_lcl:
			xr_results.out_of_control_points_x.append(i)
		
		# Warning zone: between 2 and 3 sigma
		var warning_ucl = xr_results.x_mean + (2.0/3.0) * a2 * xr_results.r_mean
		var warning_lcl = xr_results.x_mean - (2.0/3.0) * a2 * xr_results.r_mean
		if (x_value > warning_ucl and x_value <= xr_results.x_ucl) or (x_value < warning_lcl and x_value >= xr_results.x_lcl):
			xr_results.warning_points_x.append(i)
	
	for i in range(xr_results.r_values.size()):
		var r_value = xr_results.r_values[i]
		if r_value > xr_results.r_ucl or r_value < xr_results.r_lcl:
			xr_results.out_of_control_points_r.append(i)
		
		# Warning zone: defined similarly for R chart
		var warning_r_ucl = xr_results.r_mean + (2.0/3.0) * (xr_results.r_ucl - xr_results.r_mean)
		var warning_r_lcl = xr_results.r_mean - (2.0/3.0) * (xr_results.r_mean - xr_results.r_lcl)
		if (r_value > warning_r_ucl and r_value <= xr_results.r_ucl) or (r_value < warning_r_lcl and r_value >= xr_results.r_lcl):
			xr_results.warning_points_r.append(i)
	
	# Update statistics label
	_update_xr_statistics_label()
	
	# Request redraw
	diagram_container.queue_redraw()

func _analyze_z_data():
	# Get input values
	var values_text = z_data.values_input.text.strip_edges()
	var target_text = z_data.target_input.text.strip_edges()
	var std_dev_text = z_data.std_dev_input.text.strip_edges()
	
	# Validate inputs
	if values_text.is_empty():
		_show_error("Please enter values")
		return
	
	if not target_text.is_valid_float():
		_show_error("Please enter a valid target mean value")
		return
	
	if not std_dev_text.is_valid_float() or float(std_dev_text) <= 0:
		_show_error("Please enter a valid positive standard deviation")
		return
	
	# Parse values
	var values_array = values_text.split(",")
	z_data.values.clear()
	
	for val_str in values_array:
		var trimmed = val_str.strip_edges()
		if trimmed.is_valid_float():
			z_data.values.append(float(trimmed))
		else:
			_show_error("Invalid value: " + trimmed)
			return
	
	if z_data.values.size() < 2:
		_show_error("Please enter at least 2 values")
		return
	
	# Get target mean and std dev
	z_data.target_mean = float(target_text)
	z_data.std_dev = float(std_dev_text)
	
	# Calculate Z values
	z_results.z_values.clear()
	z_results.out_of_control_points.clear()
	z_results.warning_points.clear()
	
	for value in z_data.values:
		var z_value = (value - z_data.target_mean) / z_data.std_dev
		z_results.z_values.append(z_value)
	
	# Check for out of control points (beyond 3 sigma)
	for i in range(z_results.z_values.size()):
		var z_value = z_results.z_values[i]
		if z_value > z_results.ucl or z_value < z_results.lcl:
			z_results.out_of_control_points.append(i)
			
		# Warning zone: between 2 and 3 sigma
		if (abs(z_value) > 2.0 and abs(z_value) <= 3.0):
			z_results.warning_points.append(i)
	
	# Update statistics label
	_update_z_statistics_label()
	
	# Request redraw
	diagram_container.queue_redraw()

#DRAWING FUNCTIONS

# Managing what to draw
func _draw_control_chart():
	# Clear previous drawings
	var diagram_rect = diagram_container.get_rect()

	# Calculate chart area
	var chart_width = diagram_rect.size.x - MARGIN_LEFT - MARGIN_RIGHT
	var chart_height = diagram_rect.size.y - MARGIN_TOP - MARGIN_BOTTOM

	if chart_width <= 0 or chart_height <= 0:
		return  # Not enough space to draw

	# Draw based on current chart type
	match current_chart_type:
		"xr":
			_draw_xr_chart(diagram_rect, chart_width, chart_height)
		"z":
			_draw_z_chart(diagram_rect, chart_width, chart_height)

# Draw X-R control chart
func _draw_xr_chart(diagram_rect, chart_width, chart_height):
	if xr_results.x_values.size() == 0:
		return  # No data to draw
	
	# Calculate position and size for X and R charts
	var x_chart_height = chart_height * 0.5 - 10
	var r_chart_height = chart_height * 0.5 - 10
	var x_chart_top = MARGIN_TOP
	var r_chart_top = MARGIN_TOP + x_chart_height + 50
	
	# Draw X chart
	_draw_grid(diagram_rect, chart_width, x_chart_height, x_chart_top, xr_results.x_values.size())
	
	# Draw X control limits
	_draw_horizontal_line(MARGIN_LEFT, chart_width, x_chart_top + x_chart_height * 0.5, cl_color, 2)  # CL
	_draw_horizontal_line(MARGIN_LEFT, chart_width, _value_to_y(xr_results.x_ucl, xr_results.x_mean, xr_results.x_ucl - xr_results.x_lcl, x_chart_height, x_chart_top), ucl_color, 2)  # UCL
	_draw_horizontal_line(MARGIN_LEFT, chart_width, _value_to_y(xr_results.x_lcl, xr_results.x_mean, xr_results.x_ucl - xr_results.x_lcl, x_chart_height, x_chart_top), lcl_color, 2)  # LCL
	
	# Draw warning limits for X chart (2-sigma limits)
	var warning_ucl = xr_results.x_mean + (2.0/3.0) * (xr_results.x_ucl - xr_results.x_mean)
	var warning_lcl = xr_results.x_mean - (2.0/3.0) * (xr_results.x_mean - xr_results.x_lcl)
	_draw_horizontal_line(MARGIN_LEFT, chart_width, _value_to_y(warning_ucl, xr_results.x_mean, xr_results.x_ucl - xr_results.x_lcl, x_chart_height, x_chart_top), warning_color, 1, true)  # Warning UCL
	_draw_horizontal_line(MARGIN_LEFT, chart_width, _value_to_y(warning_lcl, xr_results.x_mean, xr_results.x_ucl - xr_results.x_lcl, x_chart_height, x_chart_top), warning_color, 1, true)  # Warning LCL
	
	# Draw X values
	var data_range = xr_results.x_ucl - xr_results.x_lcl
	for i in range(xr_results.x_values.size()):
		var x_pos = MARGIN_LEFT + (i + 0.5) * chart_width / xr_results.x_values.size()
		var y_pos = _value_to_y(xr_results.x_values[i], xr_results.x_mean, data_range, x_chart_height, x_chart_top)
		
		# Connect points with lines
		if i > 0:
			var prev_x = MARGIN_LEFT + (i - 0.5) * chart_width / xr_results.x_values.size()
			var prev_y = _value_to_y(xr_results.x_values[i-1], xr_results.x_mean, data_range, x_chart_height, x_chart_top)
			diagram_container.draw_line(Vector2(prev_x, prev_y), Vector2(x_pos, y_pos), x_line_color, LINE_WIDTH)
			
			# Draw point
			var point_color = x_line_color
			if xr_results.out_of_control_points_x.has(i):
				point_color = out_of_control_color
			elif xr_results.warning_points_x.has(i):
				point_color = warning_color
				
			diagram_container.draw_circle(Vector2(x_pos, y_pos), POINT_RADIUS, point_color)
	
	# Draw R chart
	_draw_grid(diagram_rect, chart_width, r_chart_height, r_chart_top, xr_results.r_values.size())
	
	# Draw R control limits
	_draw_horizontal_line(MARGIN_LEFT, chart_width, r_chart_top + r_chart_height * 0.5, cl_color, 2)  # CL
	_draw_horizontal_line(MARGIN_LEFT, chart_width, _value_to_y(xr_results.r_ucl, xr_results.r_mean, xr_results.r_ucl - xr_results.r_lcl, r_chart_height, r_chart_top), ucl_color, 2)  # UCL
	_draw_horizontal_line(MARGIN_LEFT, chart_width, _value_to_y(xr_results.r_lcl, xr_results.r_mean, xr_results.r_ucl - xr_results.r_lcl, r_chart_height, r_chart_top), lcl_color, 2)  # LCL
	
	# Draw warning limits for R chart
	var warning_r_ucl = xr_results.r_mean + (2.0/3.0) * (xr_results.r_ucl - xr_results.r_mean)
	var warning_r_lcl = xr_results.r_mean - (2.0/3.0) * (xr_results.r_mean - xr_results.r_lcl)
	_draw_horizontal_line(MARGIN_LEFT, chart_width, _value_to_y(warning_r_ucl, xr_results.r_mean, xr_results.r_ucl - xr_results.r_lcl, r_chart_height, r_chart_top), warning_color, 1, true)  # Warning UCL
	_draw_horizontal_line(MARGIN_LEFT, chart_width, _value_to_y(warning_r_lcl, xr_results.r_mean, xr_results.r_ucl - xr_results.r_lcl, r_chart_height, r_chart_top), warning_color, 1, true)  # Warning LCL
	
	# Draw R values
	data_range = xr_results.r_ucl - xr_results.r_lcl
	for i in range(xr_results.r_values.size()):
		var x_pos = MARGIN_LEFT + (i + 0.5) * chart_width / xr_results.r_values.size()
		var y_pos = _value_to_y(xr_results.r_values[i], xr_results.r_mean, data_range, r_chart_height, r_chart_top)
		
		# Connect points with lines
		if i > 0:
			var prev_x = MARGIN_LEFT + (i - 0.5) * chart_width / xr_results.r_values.size()
			var prev_y = _value_to_y(xr_results.r_values[i-1], xr_results.r_mean, data_range, r_chart_height, r_chart_top)
			diagram_container.draw_line(Vector2(prev_x, prev_y), Vector2(x_pos, y_pos), r_line_color, LINE_WIDTH)
		
		# Draw point
		var point_color = r_line_color
		if xr_results.out_of_control_points_r.has(i):
			point_color = out_of_control_color
		elif xr_results.warning_points_r.has(i):
			point_color = warning_color
			
		diagram_container.draw_circle(Vector2(x_pos, y_pos), POINT_RADIUS, point_color)
	
	# Draw chart titles and labels
	var font_size = 14
	
	# X chart title
	diagram_container.draw_string(
		ThemeDB.fallback_font, 
		Vector2(MARGIN_LEFT + chart_width / 2, x_chart_top - 20), 
		"X-Карта", 
		HORIZONTAL_ALIGNMENT_CENTER, 
		-1, font_size, label_text_color)
	
	# R chart title
	diagram_container.draw_string(
		ThemeDB.fallback_font, 
		Vector2(MARGIN_LEFT + chart_width / 2, r_chart_top - 20), 
		"R-Карта", 
		HORIZONTAL_ALIGNMENT_CENTER, 
		-1, 
		font_size, 
		label_text_color
	)
	
	# Draw value labels
	_draw_value_labels(xr_results.x_mean, xr_results.x_ucl, xr_results.x_lcl, MARGIN_LEFT - 5, x_chart_top, x_chart_height)
	_draw_value_labels(xr_results.r_mean, xr_results.r_ucl, xr_results.r_lcl, MARGIN_LEFT - 5, r_chart_top, r_chart_height)

# Draw Z control chart
func _draw_z_chart(diagram_rect, chart_width, chart_height):
	if z_results.z_values.size() == 0:
		return  # No data to draw
	
	# Draw grid
	_draw_grid(diagram_rect, chart_width, chart_height, MARGIN_TOP, z_results.z_values.size())
	
	# Find min and max for scaling
	var min_val = min(-3.0, z_results.z_values.min())
	var max_val = max(3.0, z_results.z_values.max())
	var data_range = max_val - min_val
	
	# Draw horizontal lines at +3, +2, 0, -2, -3 sigma
	_draw_horizontal_line(MARGIN_LEFT, chart_width, _value_to_y(0, (max_val + min_val) / 2, data_range, chart_height, MARGIN_TOP), cl_color, 2)  # Center line (0)
	_draw_horizontal_line(MARGIN_LEFT, chart_width, _value_to_y(3, (max_val + min_val) / 2, data_range, chart_height, MARGIN_TOP), ucl_color, 2)  # +3 sigma
	_draw_horizontal_line(MARGIN_LEFT, chart_width, _value_to_y(-3, (max_val + min_val) / 2, data_range, chart_height, MARGIN_TOP), lcl_color, 2)  # -3 sigma
	_draw_horizontal_line(MARGIN_LEFT, chart_width, _value_to_y(2, (max_val + min_val) / 2, data_range, chart_height, MARGIN_TOP), warning_color, 1, true)  # +2 sigma
	_draw_horizontal_line(MARGIN_LEFT, chart_width, _value_to_y(-2, (max_val + min_val) / 2, data_range, chart_height, MARGIN_TOP), warning_color, 1, true)  # -2 sigma
	
	# Draw Z values
	for i in range(z_results.z_values.size()):
		var x_pos = MARGIN_LEFT + (i + 0.5) * chart_width / z_results.z_values.size()
		var y_pos = _value_to_y(z_results.z_values[i], (max_val + min_val) / 2, data_range, chart_height, MARGIN_TOP)
		
		# Connect points with lines
		if i > 0:
			var prev_x = MARGIN_LEFT + (i - 0.5) * chart_width / z_results.z_values.size()
			var prev_y = _value_to_y(z_results.z_values[i-1], (max_val + min_val) / 2, data_range, chart_height, MARGIN_TOP)
			diagram_container.draw_line(Vector2(prev_x, prev_y), Vector2(x_pos, y_pos), x_line_color, LINE_WIDTH)
			
			# Draw point
			var point_color = x_line_color
			if z_results.out_of_control_points.has(i):
				point_color = out_of_control_color
			elif z_results.warning_points.has(i):
				point_color = warning_color
				
			diagram_container.draw_circle(Vector2(x_pos, y_pos), POINT_RADIUS, point_color)
	
	# Draw chart title
	var font_size = 14
	diagram_container.draw_string(
		ThemeDB.fallback_font, 
		Vector2(MARGIN_LEFT + chart_width / 2, MARGIN_TOP - 20), 
		"Z-Карта", 
		HORIZONTAL_ALIGNMENT_CENTER, 
		-1, 
		font_size, 
		label_text_color
	)
	
	# Draw value labels
	_draw_z_chart_value_labels(min_val, max_val, MARGIN_LEFT - 5, MARGIN_TOP, chart_height)

# Helper function to draw grid
func _draw_grid(diagram_rect, chart_width, chart_height, chart_top, num_points):
	# Draw axis borders
	var top_left = Vector2(MARGIN_LEFT, chart_top)
	var bottom_right = Vector2(MARGIN_LEFT + chart_width, chart_top + chart_height)

	# Draw axis lines
	diagram_container.draw_rect(Rect2(top_left, Vector2(chart_width, chart_height)), axis_color, false, LINE_WIDTH)

	# Draw vertical grid lines
	for i in range(num_points):
		var x_pos = MARGIN_LEFT + (i + 0.5) * chart_width / num_points
		diagram_container.draw_line(
			Vector2(x_pos, chart_top), 
			Vector2(x_pos, chart_top + chart_height), 
			grid_color, 
			GRID_LINE_WIDTH
		)
		
		# Draw point number
		diagram_container.draw_string(
			ThemeDB.fallback_font, 
			Vector2(x_pos, chart_top + chart_height + 15), 
			str(i + 1), 
			HORIZONTAL_ALIGNMENT_CENTER, 
			-1, 
			12, 
			label_text_color
		)
	
	# Draw horizontal grid lines (5 lines)
	for i in range(5):
		var y_pos = chart_top + i * chart_height / 4
		diagram_container.draw_line(
			Vector2(MARGIN_LEFT, y_pos), 
			Vector2(MARGIN_LEFT + chart_width, y_pos), 
			grid_color, 
			GRID_LINE_WIDTH
		)

# Helper function to draw a horizontal line
func _draw_horizontal_line(x_start, width, y_pos, color, thickness, dashed = false):
	if dashed:
		var dash_length = 5
		var gap_length = 3
		var x = x_start
		while x < x_start + width:
			var end_x = min(x + dash_length, x_start + width)
			diagram_container.draw_line(Vector2(x, y_pos), Vector2(end_x, y_pos), color, thickness)
			x = end_x + gap_length
	else:
		diagram_container.draw_line(Vector2(x_start, y_pos), Vector2(x_start + width, y_pos), color, thickness)

# Helper function to draw value labels for X-R chart
func _draw_value_labels(mean_val, ucl_val, lcl_val, x_pos, chart_top, chart_height):
	var font_size = 12
	var data_range = ucl_val - lcl_val
	
	# Draw UCL value
	diagram_container.draw_string(
		ThemeDB.fallback_font, 
		Vector2(x_pos - 80, _value_to_y(ucl_val, mean_val, data_range, chart_height, chart_top) + 5), "UCL=" + str(snapped(ucl_val, 0.001)), 
		HORIZONTAL_ALIGNMENT_RIGHT, 
		-1, 
		font_size, 
		ucl_color
	)
	
	# Draw CL value
	diagram_container.draw_string(
		ThemeDB.fallback_font, 
		Vector2(x_pos - 80, _value_to_y(mean_val, mean_val, data_range, chart_height, chart_top) + 5), 
		"CL=" + str(snapped(mean_val, 0.001)), 
		HORIZONTAL_ALIGNMENT_RIGHT, 
		-1, 
		font_size, 
		cl_color
	)
	
	# Draw LCL value
	diagram_container.draw_string(
		ThemeDB.fallback_font, 
		Vector2(x_pos - 80, _value_to_y(lcl_val, mean_val, data_range, chart_height, chart_top) + 5), 
		"LCL=" + str(snapped(lcl_val, 0.001)), 
		HORIZONTAL_ALIGNMENT_RIGHT, 
		-1, 
		font_size, 
		lcl_color
	)

# Helper function to draw value labels for Z chart
func _draw_z_chart_value_labels(min_val, max_val, x_pos, chart_top, chart_height):
	var font_size = 12
	var data_range = max_val - min_val
	var mid_val = (max_val + min_val) / 2
	
	# Draw sigma lines labels
	diagram_container.draw_string(
		ThemeDB.fallback_font, 
		Vector2(x_pos - 20, _value_to_y(3, mid_val, data_range, chart_height, chart_top) + 5), 
		"+3σ", 
		HORIZONTAL_ALIGNMENT_RIGHT, 
		-1, 
		font_size, 
		ucl_color
	)
	
	diagram_container.draw_string(
		ThemeDB.fallback_font, 
		Vector2(x_pos - 20, _value_to_y(2, mid_val, data_range, chart_height, chart_top) + 5), 
		"+2σ", 
		HORIZONTAL_ALIGNMENT_RIGHT, 
		-1, 
		font_size, 
		warning_color
	)
	
	diagram_container.draw_string(
		ThemeDB.fallback_font, 
		Vector2(x_pos - 20, _value_to_y(0, mid_val, data_range, chart_height, chart_top) + 5), 
		"0", 
		HORIZONTAL_ALIGNMENT_RIGHT, 
		-1, 
		font_size, 
		cl_color
	)
	
	diagram_container.draw_string(
		ThemeDB.fallback_font, 
		Vector2(x_pos - 20, _value_to_y(-2, mid_val, data_range, chart_height, chart_top) + 5), 
		"-2σ", 
		HORIZONTAL_ALIGNMENT_RIGHT, 
		-1, 
		font_size, 
		warning_color
	)
	
	diagram_container.draw_string(
		ThemeDB.fallback_font, 
		Vector2(x_pos - 20, _value_to_y(-3, mid_val, data_range, chart_height, chart_top) + 5), 
		"-3σ", 
		HORIZONTAL_ALIGNMENT_RIGHT, 
		-1, 
		font_size, 
		lcl_color
	)

#UPDATE STATISTICS LABELS

func _update_z_statistics_label():
	var text = "Данные по Z-карте:\n"
	text += "Количество значений: " + str(z_data.values.size()) + "\n\n"
	
	text += "Среднее (μ₀): " + str(snapped(z_data.target_mean, 0.001)) + "\n"
	text += "Квадратичное отклонение (σ₀): " + str(snapped(z_data.std_dev, 0.001)) + "\n"
	text += "Верхняя контрольная граница: +3σ\n"
	text += "Нижняя контрольная граница: -3σ\n"
	
	# Calculate some additional statistics
	var min_z = z_results.z_values.min() if z_results.z_values.size() > 0 else 0
	var max_z = z_results.z_values.max() if z_results.z_values.size() > 0 else 0
	
	text += "Минимальное Z: " + str(snapped(min_z, 0.001)) + "\n"
	text += "Максимальное Z: " + str(snapped(max_z, 0.001)) + "\n"
	text += "Точки вне границ: " + (", ".join(_get_point_numbers(z_results.out_of_control_points)) if z_results.out_of_control_points.size() > 0 else "Отсутствуют") + "\n"
	text += "Опасные точки (между 2σ и 3σ): " + (", ".join(_get_point_numbers(z_results.warning_points)) if z_results.warning_points.size() > 0 else "Отсутствуют")
	
	# Update the label
	stats_label.text = text

func _update_xr_statistics_label():
	var text = "Статистика по X-R карте:\n"
	text += "Количество подгрупп: " + str(xr_results.subgroups.size()) + "\n"
	text += "Размер подгрупп(n): " + str(xr_results.sample_size) + "\n\n"
	
	text += "X Карта:\n"
	text += "Среднее (CL): " + str(snapped(xr_results.x_mean, 0.001)) + "\n"
	text += "Верхняя контрольная граница (UCL): " + str(snapped(xr_results.x_ucl, 0.001)) + "\n"
	text += "Нижняя контрольная граница (LCL): " + str(snapped(xr_results.x_lcl, 0.001)) + "\n"
	text += "Точки за пределами: " + (", ".join(_get_point_numbers(xr_results.out_of_control_points_x)) if xr_results.out_of_control_points_x.size() > 0 else "Отсутствуют") + "\n\n"
	
	text += "R Карта:\n"
	text += "Среднее (CL): " + str(snapped(xr_results.r_mean, 0.001)) + "\n"
	text += "Верхняя контрольная граница (UCL): " + str(snapped(xr_results.r_ucl, 0.001)) + "\n"
	text += "Нижняя контрольная граница (LCL): " + str(snapped(xr_results.r_lcl, 0.001)) + "\n"
	text += "Точки за пределами: " + (", ".join(_get_point_numbers(xr_results.out_of_control_points_r)) if xr_results.out_of_control_points_r.size() > 0 else "Отсутствуют")
	
	# Update the label
	stats_label.text = text

#HELPER FUNCS

# Helper function to convert data value to y position
func _value_to_y(value, center_value, data_range, chart_height, chart_top):
	if data_range == 0:
		return chart_top + chart_height / 2  # Avoid division by zero
	
	# Map the value to y position
	# Center value should be in the middle of the chart
	var relative_pos = (center_value - value) / (data_range / 2)
	return chart_top + chart_height / 2 + relative_pos * (chart_height / 2) * 0.8  # 0.8 factor to leave margin

# Function to show error message
func _show_error(message):
	var dialog = AcceptDialog.new()
	dialog.title = "Error"
	dialog.dialog_text = message
	dialog.connect("confirmed", dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()

# Function to format point numbers for display
func _get_point_numbers(points_array):
	var result = []
	for point in points_array:
		result.append(str(point + 1))  # +1 for human-readable numbering
	return result

#HANDLE SAVING

func _on_save_button_pressed():
	# Create a FileDialog to choose where to save
	file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.current_path = "histogram.png"
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
		error_dialog.dialog_text = "Error saving histogram to: " + path
		error_dialog.add_theme_color_override("font_color", label_text_color)
		add_child(error_dialog)
		error_dialog.popup_centered()
	else:
		print("Image saved successfully to: ", path)
		
		# Show a confirmation dialog
		var confirm_dialog = AcceptDialog.new()
		confirm_dialog.dialog_text = "Histogram saved successfully to:\n" + path
		confirm_dialog.add_theme_color_override("font_color", label_text_color)
		add_child(confirm_dialog)
		confirm_dialog.popup_centered()
