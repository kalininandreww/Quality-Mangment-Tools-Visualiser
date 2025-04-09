extends Control

# Exportable variables
@export var min_bin_count: int = 5  # Minimum number of bins
@export var max_bin_count: int = 20  # Maximum number of bins
@export_color_no_alpha var axis_color: Color = Color.WHITE
@export_color_no_alpha var label_text_color: Color = Color.WHITE  # For all UI labels
@export_color_no_alpha var input_text_color: Color = Color.WHITE  # For TextEdit input
@export_color_no_alpha var bar_text_color: Color = Color.WHITE    # For text on histogram bars
@export_color_no_alpha var bar_first_color: Color = Color(0.2, 0.7, 0.9)  # Color for the first bar
@export_color_no_alpha var bar_last_color: Color = Color(0.8, 0.3, 0.3)   # Color for the last bar
@export_color_no_alpha var normal_curve_color: Color = Color.RED
@export_color_no_alpha var mean_line_color: Color = Color.GREEN
@export_color_no_alpha var std_dev_line_color: Color = Color.YELLOW

# Node references
@onready var split_container = $SplitContainer
@onready var input_container = %InputContainer
@onready var data_input = %DataInput
@onready var analyze_button = %AnalyzeButton
@onready var bin_slider = %BinSlider
@onready var bin_value_label = %BinValueLabel
@onready var diagram_container = %DiagramContainer
@onready var save_button = %SaveButton
@onready var stats_label = %StatsLabel
@onready var data_label = %NumOfbinsLabel
@onready var bin_count_label = %BinValueLabel
@onready var label_all_bins_checkbox = %LabelAllBinsCheckBox
@onready var checkbox_label = %CheckboxLabel


# Constants
const MARGIN_LEFT = 80
const MARGIN_RIGHT = 60
const MARGIN_TOP = 40
const MARGIN_BOTTOM = 60
const NORMAL_CURVE_POINTS = 100  # Number of points to draw the normal curve

# Data storage
var raw_data = []
var histogram_data = {
	"bins": [],
	"counts": [],
	"bin_edges": []
}
var statistics = {
	"mean": 0.0,
	"median": 0.0,
	"mode": 0.0,
	"std_dev": 0.0,
	"min": 0.0,
	"max": 0.0,
	"range": 0.0,
	"sample_size": 0
}
var file_dialog = null
var label_all_bins = false

func _ready():
	# Apply text colors to UI elements
	_apply_text_colors()
	
	# Set up analyze button
	analyze_button.text = "Анализировать данные"
	analyze_button.connect("pressed", _on_analyze_button_pressed)
	
	# Set up bin slider
	bin_slider.min_value = min_bin_count
	bin_slider.max_value = max_bin_count
	bin_slider.step = 1
	bin_slider.value = 10  # Default bin count
	bin_slider.connect("value_changed", _on_bin_slider_changed)
	_update_bin_label(bin_slider.value)
	
	# Setup save button
	save_button.text = "Сохранить"
	save_button.connect("pressed", _on_save_button_pressed)
	
	# Setup data input placeholder
	data_input.placeholder_text = "Введите данные разделенные запятой (пример: 1.2, 3.4, 5.6)   "
	
	# Set up diagram container for drawing
	diagram_container.connect("draw", _draw_histogram)
	
	# Setup the checkbox for bin labeling
	label_all_bins_checkbox.connect("toggled", _on_label_all_bins_toggled)

func _apply_text_colors():
	# Apply text colors to all relevant UI elements
	data_label.add_theme_color_override("font_color", label_text_color)
	bin_count_label.add_theme_color_override("font_color", label_text_color)
	bin_value_label.add_theme_color_override("font_color", label_text_color)
	stats_label.add_theme_color_override("font_color", label_text_color)
	checkbox_label.add_theme_color_override("font_color", label_text_color)
	
	data_input.add_theme_color_override("font_color", input_text_color)
	
	analyze_button.add_theme_color_override("font_color", label_text_color)
	save_button.add_theme_color_override("font_color", label_text_color)

func _update_bin_label(value):
	bin_value_label.text = str(int(value))

func _on_bin_slider_changed(value):
	_update_bin_label(value)
	if raw_data.size() > 0:
		_calculate_histogram()
		_update_statistics_label()
		diagram_container.queue_redraw()

func _on_label_all_bins_toggled(button_pressed):
	label_all_bins = button_pressed
	# Redraw the histogram with the new labeling preference
	if raw_data.size() > 0:
		diagram_container.queue_redraw()

func _on_analyze_button_pressed():
	var text = data_input.text.strip_edges()
	if text.is_empty():
		_show_error("Введите данные")
		return
	
	# Parse the comma-separated values
	var values = text.split(",")
	raw_data.clear()
	
	for val_str in values:
		var trimmed = val_str.strip_edges()
		if trimmed.is_valid_float():
			raw_data.append(float(trimmed))
		else:
			_show_error("Invalid value: " + trimmed)
			return
	
	if raw_data.size() < 2:
		_show_error("Введите хотя бы два значения для осмысленного анализа")
		return
	
	# Calculate histogram and statistics
	_calculate_histogram()
	_update_statistics_label()
	diagram_container.queue_redraw()

func _calculate_histogram():
	if raw_data.size() == 0:
		return
		
	# Sort data for easier statistics calculation
	raw_data.sort()
	
	# Calculate basic statistics
	statistics.sample_size = raw_data.size()
	statistics.min = raw_data[0]
	statistics.max = raw_data[raw_data.size() - 1]
	statistics.range = statistics.max - statistics.min
	
	# Calculate mean
	var sum = 0.0
	for val in raw_data:
		sum += val
	statistics.mean = sum / statistics.sample_size
	
	# Calculate median
	var middle = statistics.sample_size / 2
	if statistics.sample_size % 2 == 0:
		statistics.median = (raw_data[middle - 1] + raw_data[middle]) / 2
	else:
		statistics.median = raw_data[middle]
	
	# Calculate standard deviation
	var sum_squared_diff = 0.0
	for val in raw_data:
		var diff = val - statistics.mean
		sum_squared_diff += diff * diff
	statistics.std_dev = sqrt(sum_squared_diff / statistics.sample_size)
	
	# Calculate mode (most frequent value)
	var value_counts = {}
	var max_count = 0
	statistics.mode = raw_data[0]  # Default to first value
	
	for val in raw_data:
		# For floats, round to 2 decimal places for counting
		var rounded_val = round(val * 100) / 100
		if value_counts.has(rounded_val):
			value_counts[rounded_val] += 1
		else:
			value_counts[rounded_val] = 1
			
		if value_counts[rounded_val] > max_count:
			max_count = value_counts[rounded_val]
			statistics.mode = rounded_val
	
	# Create bins for histogram
	var num_bins = int(bin_slider.value)
	var bin_width = statistics.range / num_bins
	
	# Ensure minimum bin width to avoid division by zero
	if bin_width <= 0:
		bin_width = 1.0
		num_bins = 1
	
	# Calculate bin edges
	histogram_data.bin_edges.clear()
	for i in range(num_bins + 1):
		histogram_data.bin_edges.append(statistics.min + i * bin_width)
	
	# Calculate bin centers
	histogram_data.bins.clear()
	for i in range(num_bins):
		histogram_data.bins.append(statistics.min + (i + 0.5) * bin_width)
	
	# Count values in each bin
	histogram_data.counts.clear()
	for i in range(num_bins):
		histogram_data.counts.append(0)
	
	for val in raw_data:
		# Find the appropriate bin
		for i in range(num_bins):
			if i == num_bins - 1:  # Last bin includes the upper bound
				if val >= histogram_data.bin_edges[i] and val <= histogram_data.bin_edges[i + 1]:
					histogram_data.counts[i] += 1
					break
			elif val >= histogram_data.bin_edges[i] and val < histogram_data.bin_edges[i + 1]:
				histogram_data.counts[i] += 1
				break

func _update_statistics_label():
	var text = "Статистика:\n"
	text += "Размер выборки: " + str(statistics.sample_size) + "\n"
	text += "Среднее: " + str(snapped(statistics.mean, 0.001)) + "\n"
	text += "Медиана: " + str(snapped(statistics.median, 0.001)) + "\n"
	text += "Мода: " + str(snapped(statistics.mode, 0.001)) + "\n"
	text += "Среднекв. отклонение: " + str(snapped(statistics.std_dev, 0.001)) + "\n"
	text += "Минимальное: " + str(snapped(statistics.min, 0.001)) + "\n"
	text += "Максимально: " + str(snapped(statistics.max, 0.001)) + "\n"
	text += "Размах: " + str(snapped(statistics.range, 0.001))
	
	stats_label.text = text

func _show_error(message):
	var error_dialog = AcceptDialog.new()
	error_dialog.dialog_text = message
	error_dialog.add_theme_color_override("font_color", label_text_color)
	add_child(error_dialog)
	error_dialog.popup_centered()

func _draw_histogram():
	var canvas = diagram_container
	var rect = canvas.get_rect()
	var width = rect.size.x - MARGIN_LEFT - MARGIN_RIGHT
	var height = rect.size.y - MARGIN_TOP - MARGIN_BOTTOM
	
	# Skip if no data or no space
	if raw_data.size() == 0 or width <= 0 or height <= 0:
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
	
	# Draw bars
	if histogram_data.bins.size() == 0 or histogram_data.counts.size() == 0:
		return
	
	# Find the maximum count for scaling
	var max_count = 0
	for count in histogram_data.counts:
		max_count = max(max_count, count)
	
	if max_count == 0:
		return
	
	# Calculate bar width
	var bar_width = width / histogram_data.bins.size()
	
	# Draw bars and bin labels
	for i in range(histogram_data.bins.size()):
		var bin_center = histogram_data.bins[i]
		var count = histogram_data.counts[i]

		# Calculate position
		var bar_height = (count / float(max_count)) * height
		var bar_x = start_x + i * bar_width
		var bar_y = start_y - bar_height

		# Calculate gradient color based on position in sequence
		var t = i / float(max(1, histogram_data.bins.size() - 1))  # Normalized position [0..1]
		var bar_color = bar_first_color.lerp(bar_last_color, t)   # Linear interpolation between colors

		# Draw bar with gradient color
		canvas.draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), bar_color)

		# Draw count on top of the bar
		var count_text = str(count)
		var count_width = font.get_string_size(count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if bar_height > font_size:
			canvas.draw_string(font, Vector2(bar_x + bar_width/2 - count_width/2, bar_y - 5), 
			count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, bar_text_color)

		# Draw bin range label on x-axis
		var lower_edge = histogram_data.bin_edges[i]
		var upper_edge = histogram_data.bin_edges[i + 1]

		# Different labeling based on checkbox state
		if label_all_bins:
			# Label all bins with their range
			var bin_range_text = str(snapped(lower_edge, 0.01)) + "-" + str(snapped(upper_edge, 0.01))

			# Calculate text position and rotation as needed
			var text_width = font.get_string_size(bin_range_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

			# For many bins, rotate the text to fit better
			if histogram_data.bins.size() > 8:
				# Rotate labels to prevent overlap
				var rotation = PI/4  # 45 degrees
				var text_pos = Vector2(bar_x + bar_width/2, start_y + 10)

				# Save canvas state, rotate, draw text, restore state
				canvas.draw_set_transform(text_pos, rotation, Vector2(1, 1))
				canvas.draw_string(font, Vector2(0, 0), bin_range_text, 
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, bar_text_color)
				canvas.draw_set_transform(Vector2.ZERO, 0, Vector2(1, 1))  # Reset transform
			else:
				# For fewer bins, show horizontal labels
				var text_pos = Vector2(bar_x + bar_width/2 - text_width/2, start_y + 20)
				canvas.draw_string(font, text_pos, bin_range_text, 
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, bar_text_color)
		else:
			# Original labeling method (only every other bin or if few bins)
			var edge_text = str(snapped(lower_edge, 0.01))

			# Only draw every other bin edge for readability if many bins
			if i % 2 == 0 or histogram_data.bins.size() < 10:
				var text_width = font.get_string_size(edge_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
				canvas.draw_string(font, Vector2(bar_x + 5, start_y + 20), 
				edge_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, bar_text_color)

	# Draw the last upper edge (only in original mode or if it's the last bin in all-bins mode)
	if not label_all_bins or (label_all_bins and histogram_data.bins.size() < 8):
		var last_edge_text = str(snapped(histogram_data.bin_edges[histogram_data.bin_edges.size() - 1], 0.01))
		var last_x = start_x + histogram_data.bins.size() * bar_width
		canvas.draw_string(font, Vector2(last_x - 20, start_y + 20), 
					last_edge_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, bar_text_color)
	
	# Draw y-axis labels (count scale)
	for i in range(6):  # 0, 20%, 40%, 60%, 80%, 100% of max count
		var y_pos = start_y - (i / 5.0) * height
		var count_value = (i / 5.0) * max_count
		var count_text = str(int(count_value))
		
		# Draw tick
		canvas.draw_line(Vector2(start_x - 5, y_pos), Vector2(start_x, y_pos), axis_color, 1)
		
		# Draw count value
		canvas.draw_string(font, Vector2(start_x - font.get_string_size(count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x - 10, y_pos + font_size/4), 
					count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, bar_text_color)
	
	# Draw normal distribution curve based on calculated mean and std dev
	if statistics.std_dev > 0:
		var points = []
		var max_normal_val = 0.0
		
		# Calculate the normal distribution values
		for i in range(NORMAL_CURVE_POINTS):
			var x = statistics.min + (i / float(NORMAL_CURVE_POINTS - 1)) * statistics.range
			var z = (x - statistics.mean) / statistics.std_dev
			var normal_val = (1.0 / (statistics.std_dev * sqrt(2 * PI))) * exp(-0.5 * z * z)
			max_normal_val = max(max_normal_val, normal_val)
			points.append({"x": x, "y": normal_val})
		
		# Scale the normal curve to fit the graph height and match histogram area
		var hist_area = 0.0
		for count in histogram_data.counts:
			hist_area += count
		
		var bin_width = statistics.range / histogram_data.bins.size()
		var scaling_factor = (hist_area * bin_width) / (max_normal_val * statistics.range)
		
		# Draw the curve
		var prev_point = null
		for point in points:
			var x_pos = start_x + (point.x - statistics.min) / statistics.range * width
			var y_val = point.y * scaling_factor
			var y_pos = start_y - (y_val / max_count) * height
			
			if prev_point != null:
				canvas.draw_line(prev_point, Vector2(x_pos, y_pos), normal_curve_color, 2)
			
			prev_point = Vector2(x_pos, y_pos)
	
	# Draw vertical line for mean
	var mean_x = start_x + (statistics.mean - statistics.min) / statistics.range * width
	canvas.draw_line(Vector2(mean_x, start_y), Vector2(mean_x, end_y), mean_line_color, 2)
	var mean_label = "Среднее: " + str(snapped(statistics.mean, 0.01))
	canvas.draw_string(font, Vector2(mean_x - font.get_string_size(mean_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x/2, end_y - 25), 
				mean_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, mean_line_color)
	
	# Draw vertical lines for standard deviations
	var std_dev_minus_x = start_x + (statistics.mean - statistics.std_dev - statistics.min) / statistics.range * width
	var std_dev_plus_x = start_x + (statistics.mean + statistics.std_dev - statistics.min) / statistics.range * width
	
	# Only draw if in range
	if std_dev_minus_x >= start_x:
		canvas.draw_dashed_line(Vector2(std_dev_minus_x, start_y), Vector2(std_dev_minus_x, end_y), std_dev_line_color, 1, 5)
		var minus_label = "-1σ"
		canvas.draw_string(font, Vector2(std_dev_minus_x - font.get_string_size(minus_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x/2, end_y - 10), 
					minus_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, std_dev_line_color)
	
	if std_dev_plus_x <= end_x:
		canvas.draw_dashed_line(Vector2(std_dev_plus_x, start_y), Vector2(std_dev_plus_x, end_y), std_dev_line_color, 1, 5)
		var plus_label = "+1σ"
		canvas.draw_string(font, Vector2(std_dev_plus_x - font.get_string_size(plus_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x/2, end_y - 10), 
					plus_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, std_dev_line_color)

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
