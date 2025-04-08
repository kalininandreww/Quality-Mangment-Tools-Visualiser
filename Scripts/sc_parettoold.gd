extends Node

signal visibility_changed

@export var minimal_bar_value: float = 0

const ADD_BUTTON_TEXT = "Add"
const PARAMETERS_CONTAINER = "ParametersContainer"
const NAME_EDIT_TEXT = "Name"
const VALUE_EDIT_TEXT = "Value"
const MAX_VALUE = 100
const CUMULATIVE_LINE_COLOR = Color(0, 0.8, 0.2)
const PARETO_LINE_COLOR = Color(0.2, 0.8, 0.8)
const GRID_COLOR = Color(0.5, 0.5, 0.5)
const AXES_COLOR = Color(0, 0, 0)
const DEFAULT_FONT_SIZE = 14
const DEFAULT_PADDING = 5

# UI Elements
var add_button: Button
var parameters_container: VBoxContainer
var diagram_canvas: CanvasItem
var parameter_containers = []
var parameters = []
var diagram_data = []

func _ready():
	# Add parameters where the parameters are going to be listed
	add_button = get_node("Canvas/SplitContainer/PanelContainer/Panel/VBoxContainer/Button")
	parameters_container = get_node("Canvas/SplitContainer/PanelContainer/Panel/VBoxContainer/ParametersContainer")
	
	# Create the initial container for parameters
	parameters_container.vbox.add_child(create_parameter_container())
	
	# Add the diagram canvas
	diagram_canvas = get_node("Canvas/SplitContainer/PanelContainer/Panel/CanvasItem")
	self.connect("visibility_changed", self, "_update_diagram")

func _onVisibilityChanged():
	_update_diagram()

func _onaddButton_pressed():
	add_parameter()

func add_parameter():
	var container = create_parameter_container()
	parameters_container.vbox.add_child(container)

func create_parameter_container() -> HBoxContainer:
	var container = HBoxContainer.new()
	
	var name_edit = LineEdit.new()
	name_edit.text = NAME_EDIT_TEXT
	name_edit.hint_text = NAME_EDIT_TEXT
	name_edit.connect("text_changed", self, "_update_diagram")
	name_edit.minimum_height = DEFAULT_FONT_SIZE
	container.add_child(name_edit)
	
	var value_edit = LineEdit.new()
	value_edit.text = str(VALUE_EDIT_TEXT)
	value_edit.hint_text = str(VALUE_EDIT_TEXT)
	value_edit.connect("text_changed", self, "_update_diagram")
	value_edit.text = str(parse_num(value_edit.text))
	value_edit.minimum_height = DEFAULT_FONT_SIZE
	container.add_child(value_edit)
	
	parameter_containers.append(container)
	return container

func parse_num(text):
	if text.isdigit():
		return float(text)
	else:
		return 0.0

func _update_diagram():
	diagram_data = []
	parameters.clear()
	
	# Collect parameter data
	for idx in range(parameters_container.vbox.get_child_count()):
		var container = parameters_container.vbox.get_child(idx) as HBoxContainer
		var name_edit = container.get_child(0) as LineEdit
		var value_edit = container.get_child(1) as LineEdit
		
		var name = name_edit.text
		var value = parse_num(value_edit.text)
		
		if value != 0:
			parameters.append({"name": name, "value": value})
	
	# Sort parameters by value descending
	parameters = parameters.sorted( func(a, b):
		return b.value - a.value )
	
	# Calculate cumulative percentage
	var total = 0
	for param in parameters:
		total += param.value
	var cumulative = 0
	
	for i in range(parameters.size()):
		cumulative += parameters[i].value
		diagram_data.append({
			"name": parameters[i].name,
			"value": parameters[i].value,
			"cumulative": cumulative / total * 100
		})
	
	# Draw the diagram
	_draw_diagram()

func _draw_diagram():
	diagram_canvas.clear()
	var canvas = diagram_canvas
	var font_size = DEFAULT_FONT_SIZE
	var padding = DEFAULT_PADDING
	var width = canvas.rect_size.width
	var height = canvas.rect_size.height
	
	# Scale values to fit the canvas
	var max_value: float
	if !diagram_data.empty():
		var values = diagram_data.map( func(p): return p.value )
		
		max_value = values.max()
	else:
		max_value = 1
	var max_cumulative = 100
	var scale_x = (width - padding * 2) / (max_value if max_value > 0 else 1)
	var scale_y = (height - padding * 2) / 4
	
	# Draw axes
	canvas.draw_rect(Rect2(position + Vector2(padding, padding), Vector2(width - padding, height - padding)), GRID_COLOR, false, 1)
	
	# Draw X-axis
	canvas.draw_line(Vector2(padding, height - padding), Vector2(width - padding, height - padding), AXES_COLOR)
	# Draw Y-axis
	canvas.draw_line(Vector2(padding, padding), Vector2(padding, height - padding), AXES_COLOR)
	
	# Draw value labels on X-axis
	var num_ticks = 5
	var tick_step = max_value / (num_ticks - 1)
	
	for i in range(num_ticks):
		var value = i * tick_step
		var x = padding + value * scale_x
		var label = str(round(value))
		canvas.draw_string(Vector2(x, height - padding + font_size), label, DEFAULT_FONT_SIZE)
	
	# Draw cumulative percentage on X-axis
	for i in range(num_ticks):
		var percentage = i * (100 / (num_ticks - 1))
		var x = width - padding - i * ((width - 2 * padding) / (num_ticks - 1))
		var label = str(round(percentage)) + "%"
		canvas.draw_string(Vector2(x, height - padding + font_size), label, DEFAULT_FONT_SIZE)
	
	# Draw bars
	for i in range(diagram_data.size()):
		var data = diagram_data[i]
		var y = padding + i * scale_y
		var bar_height = scale_y * (data.value / max_value)
		var bar_width = data.value * scale_x
		var bar_rect = Rect2(Vector2(padding, y), Vector2(bar_width, bar_height))
		canvas.draw_rect(bar_rect, Color(0.6, 0.6, 0.6), false, 2)
		
		# Draw cumulative line
		if i == 0:
			var prev_point = Vector2(padding, y + bar_height / 2)
		var current_point = Vector2(padding + data.value * scale_x, y + bar_height / 2)
		canvas.draw_line(prev_point, current_point, CUMULATIVE_LINE_COLOR)
		prev_point = current_point
	
	# Draw 80% line
	var eighty_percent_line_x = padding + (0.8 * max_value) * scale_x
	canvas.draw_line(Vector2(eighty_percent_line_x, padding), Vector2(eighty_percent_line_x, height - padding), PARETO_LINE_COLOR, 1, true)
	
	# Draw Y-axis labels
	for i in range(diagram_data.size()):
		var data = diagram_data[i]
		var y = padding + i * scale_y + bar_height / 2
		var text = data.name
		canvas.draw_string(Vector2(padding - font_size, y), text, DEFAULT_FONT_SIZE)
	
	canvas.request_update()

func _on_enter_pressed():
	add_parameter()
