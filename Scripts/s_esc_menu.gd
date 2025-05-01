extends CanvasLayer

# Paths
const MAIN_MENU_PATH = "res://Scenes/Tabs/SC_main_screen.tscn"
const CONFIG_FILE_PATH = "user://ui_settings.cfg"

# References to the UI elements
@onready var esc_menu = %EscMenu
@onready var quit_confirmation = %QuitConfirmation
@onready var settings_panel = %SettingsPanel
@onready var settings_tabs = %TabContainer

# Reference to the current active scene/tool
var current_scene: String = ""
var config = ConfigFile.new()

# Text for quit button
var main_menu_text : String = "Выйти"
var not_main_menu_text : String = "Вернуться в главное меню"

func _ready():
	# Initially hide all menus
	esc_menu.visible = false
	quit_confirmation.visible = false
	settings_panel.visible = false
	
	# Load saved settings
	load_settings()
	
	# Connect signals for the ESC menu buttons
	%QuitButton.pressed.connect(_on_quit_button_pressed)
	%SettingsButton.pressed.connect(_on_settings_button_pressed)
	
	# Connect signals for the quit confirmation dialog
	%YesButton.pressed.connect(_on_quit_yes_pressed)
	%NoButton.pressed.connect(_on_quit_no_pressed)
	
	# Connect signal for the settings Apply button
	%ApplySettingsButton.pressed.connect(_on_apply_settings_pressed)
	%QuitSettingButton.pressed.connect(_on_close_settings_pressed)

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		if settings_panel.visible:
			settings_panel.visible = false
			return
			
		if quit_confirmation.visible:
			quit_confirmation.visible = false
			return
			
		# Toggle the ESC menu
		esc_menu.visible = !esc_menu.visible

func set_current_scene(scene_path):
	current_scene = scene_path
	if scene_path == MAIN_MENU_PATH:
		%QuitButton.text = main_menu_text
	else:
		%QuitButton.text = not_main_menu_text

func _on_quit_button_pressed():
	esc_menu.visible = false
	quit_confirmation.visible = true

func _on_settings_button_pressed():
	esc_menu.visible = false
	settings_panel.visible = true

func _on_quit_yes_pressed():
	quit_confirmation.visible = false
	
	# Check if we're in the main menu or a tool
	if current_scene == MAIN_MENU_PATH or current_scene == "":
		get_tree().quit()
	else:
		# Return to main menu
		get_tree().change_scene_to_file(MAIN_MENU_PATH)

func _on_quit_no_pressed():
	quit_confirmation.visible = false
	esc_menu.visible = true

func _on_apply_settings_pressed():
	apply_settings()
	save_settings()
	settings_panel.visible = false

func _on_close_settings_pressed():
	settings_panel.visible = false

# Load color settings from the config file
func load_settings():
	var err = config.load(CONFIG_FILE_PATH)
	if err != OK:
		print("No config file found. Using default settings.")
		return
		
	# Apply the loaded settings to the color pickers
	# Ishikawa settings
	set_color_picker_value("Ishikawa/spine_color", config.get_value("ishikawa", "spine_color", Color.BLACK))
	set_color_picker_value("Ishikawa/branch_color", config.get_value("ishikawa", "branch_color", Color.BLACK))
	set_color_picker_value("Ishikawa/subbranch_color", config.get_value("ishikawa", "subbranch_color", Color.BLACK))
	set_color_picker_value("Ishikawa/subsubbone_color", config.get_value("ishikawa", "subsubbone_color", Color.BLACK))
	set_color_picker_value("Ishikawa/text_color", config.get_value("ishikawa", "text_color", Color.BLACK))
	set_color_picker_value("Ishikawa/ui_text_color", config.get_value("ishikawa", "ui_text_color", Color.BLACK))
	
	# Pareto settings
	set_color_picker_value("Pareto/axis_color", config.get_value("pareto", "axis_color", Color.WHITE))
	set_color_picker_value("Pareto/bar_text_color", config.get_value("pareto", "bar_text_color", Color.WHITE))
	set_color_picker_value("Pareto/cumulative_line_color", config.get_value("pareto", "cumulative_line_color", Color.RED))
	set_color_picker_value("Pareto/cutoff_line_color", config.get_value("pareto", "cutoff_line_color", Color.YELLOW))
	set_color_picker_value("Pareto/bar_first_color", config.get_value("pareto", "bar_first_color", Color(0.2, 0.7, 0.9)))
	set_color_picker_value("Pareto/bar_last_color", config.get_value("pareto", "bar_last_color", Color(0.8, 0.3, 0.3)))
	
	# Scatter Plot settings
	set_color_picker_value("ScatterPlot/axis_color", config.get_value("scatter", "axis_color", Color.WHITE))
	set_color_picker_value("ScatterPlot/label_text_color", config.get_value("scatter", "label_text_color", Color.WHITE))
	set_color_picker_value("ScatterPlot/input_text_color", config.get_value("scatter", "input_text_color", Color.WHITE))
	set_color_picker_value("ScatterPlot/point_color", config.get_value("scatter", "point_color", Color(0.2, 0.7, 0.9)))
	set_color_picker_value("ScatterPlot/regression_line_color", config.get_value("scatter", "regression_line_color", Color.RED))
	set_color_picker_value("ScatterPlot/grid_color", config.get_value("scatter", "grid_color", Color(0.3, 0.3, 0.3, 0.5)))
	
	# Control Charts settings
	set_color_picker_value("ControlCharts/axis_color", config.get_value("control_charts", "axis_color", Color.WHITE))
	set_color_picker_value("ControlCharts/label_text_color", config.get_value("control_charts", "label_text_color", Color.WHITE))
	set_color_picker_value("ControlCharts/input_text_color", config.get_value("control_charts", "input_text_color", Color.WHITE))
	set_color_picker_value("ControlCharts/grid_color", config.get_value("control_charts", "grid_color", Color(0.3, 0.3, 0.3)))
	set_color_picker_value("ControlCharts/x_line_color", config.get_value("control_charts", "x_line_color", Color(0.2, 0.7, 0.9)))
	set_color_picker_value("ControlCharts/r_line_color", config.get_value("control_charts", "r_line_color", Color(0.8, 0.3, 0.3)))
	set_color_picker_value("ControlCharts/ucl_color", config.get_value("control_charts", "ucl_color", Color.RED))
	set_color_picker_value("ControlCharts/lcl_color", config.get_value("control_charts", "lcl_color", Color.RED))
	set_color_picker_value("ControlCharts/cl_color", config.get_value("control_charts", "cl_color", Color.GREEN))
	set_color_picker_value("ControlCharts/out_of_control_color", config.get_value("control_charts", "out_of_control_color", Color.YELLOW))
	set_color_picker_value("ControlCharts/warning_color", config.get_value("control_charts", "warning_color", Color.ORANGE))
	
	# Histogram settings
	set_color_picker_value("Histogram/axis_color", config.get_value("histogram", "axis_color", Color.WHITE))
	set_color_picker_value("Histogram/label_text_color", config.get_value("histogram", "label_text_color", Color.WHITE))
	set_color_picker_value("Histogram/input_text_color", config.get_value("histogram", "input_text_color", Color.WHITE))
	set_color_picker_value("Histogram/bar_text_color", config.get_value("histogram", "bar_text_color", Color.WHITE))
	set_color_picker_value("Histogram/bar_first_color", config.get_value("histogram", "bar_first_color", Color(0.2, 0.7, 0.9)))
	set_color_picker_value("Histogram/bar_last_color", config.get_value("histogram", "bar_last_color", Color(0.8, 0.3, 0.3)))
	set_color_picker_value("Histogram/normal_curve_color", config.get_value("histogram", "normal_curve_color", Color.RED))
	set_color_picker_value("Histogram/mean_line_color", config.get_value("histogram", "mean_line_color", Color.GREEN))
	set_color_picker_value("Histogram/std_dev_line_color", config.get_value("histogram", "std_dev_line_color", Color.YELLOW))

# Set color picker value by path
func set_color_picker_value(path, color):
	var picker = settings_tabs.get_node(path)
	if picker:
		picker.color = color

# Apply the settings to the actual tool scripts
func apply_settings():
	# Get references to all tool scripts that need color updates
	var ishikawa_tools = get_tree().get_nodes_in_group("ishikawa_tool")
	var pareto_tools = get_tree().get_nodes_in_group("pareto_tool")
	var scatter_tools = get_tree().get_nodes_in_group("scatter_tool")
	var control_charts_tools = get_tree().get_nodes_in_group("control_charts_tool")
	var histogram_tools = get_tree().get_nodes_in_group("histogram_tool")
	
	# Apply Ishikawa settings
	for tool in ishikawa_tools:
		tool.spine_color = settings_tabs.get_node("Ishikawa/spine_color").color
		tool.branch_color = settings_tabs.get_node("Ishikawa/branch_color").color
		tool.subbranch_color = settings_tabs.get_node("Ishikawa/subbranch_color").color
		tool.subsubbone_color = settings_tabs.get_node("Ishikawa/subsubbone_color").color
		tool.text_color = settings_tabs.get_node("Ishikawa/text_color").color
		tool.ui_text_color = settings_tabs.get_node("Ishikawa/ui_text_color").color
		tool.update_colors()
	
	# Apply Pareto settings
	for tool in pareto_tools:
		tool.axis_color = settings_tabs.get_node("Pareto/axis_color").color
		tool.bar_text_color = settings_tabs.get_node("Pareto/bar_text_color").color
		tool.cumulative_line_color = settings_tabs.get_node("Pareto/cumulative_line_color").color
		tool.cutoff_line_color = settings_tabs.get_node("Pareto/cutoff_line_color").color
		tool.bar_first_color = settings_tabs.get_node("Pareto/bar_first_color").color
		tool.bar_last_color = settings_tabs.get_node("Pareto/bar_last_color").color
		tool.update_colors()
	
	# Apply Scatter Plot settings
	for tool in scatter_tools:
		tool.axis_color = settings_tabs.get_node("ScatterPlot/axis_color").color
		tool.label_text_color = settings_tabs.get_node("ScatterPlot/label_text_color").color
		tool.input_text_color = settings_tabs.get_node("ScatterPlot/input_text_color").color
		tool.point_color = settings_tabs.get_node("ScatterPlot/point_color").color
		tool.regression_line_color = settings_tabs.get_node("ScatterPlot/regression_line_color").color
		tool.grid_color = settings_tabs.get_node("ScatterPlot/grid_color").color
		tool.update_colors()
	
	# Apply Control Charts settings
	for tool in control_charts_tools:
		tool.axis_color = settings_tabs.get_node("ControlCharts/axis_color").color
		tool.label_text_color = settings_tabs.get_node("ControlCharts/label_text_color").color
		tool.input_text_color = settings_tabs.get_node("ControlCharts/input_text_color").color
		tool.grid_color = settings_tabs.get_node("ControlCharts/grid_color").color
		tool.x_line_color = settings_tabs.get_node("ControlCharts/x_line_color").color
		tool.r_line_color = settings_tabs.get_node("ControlCharts/r_line_color").color
		tool.ucl_color = settings_tabs.get_node("ControlCharts/ucl_color").color
		tool.lcl_color = settings_tabs.get_node("ControlCharts/lcl_color").color
		tool.cl_color = settings_tabs.get_node("ControlCharts/cl_color").color
		tool.out_of_control_color = settings_tabs.get_node("ControlCharts/out_of_control_color").color
		tool.warning_color = settings_tabs.get_node("ControlCharts/warning_color").color
		tool.update_colors()
	
	# Apply Histogram settings
	for tool in histogram_tools:
		tool.axis_color = settings_tabs.get_node("Histogram/axis_color").color
		tool.label_text_color = settings_tabs.get_node("Histogram/label_text_color").color
		tool.input_text_color = settings_tabs.get_node("Histogram/input_text_color").color
		tool.bar_text_color = settings_tabs.get_node("Histogram/bar_text_color").color
		tool.bar_first_color = settings_tabs.get_node("Histogram/bar_first_color").color
		tool.bar_last_color = settings_tabs.get_node("Histogram/bar_last_color").color
		tool.normal_curve_color = settings_tabs.get_node("Histogram/normal_curve_color").color
		tool.mean_line_color = settings_tabs.get_node("Histogram/mean_line_color").color
		tool.std_dev_line_color = settings_tabs.get_node("Histogram/std_dev_line_color").color
		tool.update_colors()

# Save settings to the config file
func save_settings():
	# Ishikawa settings
	config.set_value("ishikawa", "spine_color", settings_tabs.get_node("Ishikawa/spine_color").color)
	config.set_value("ishikawa", "branch_color", settings_tabs.get_node("Ishikawa/branch_color").color)
	config.set_value("ishikawa", "subbranch_color", settings_tabs.get_node("Ishikawa/subbranch_color").color)
	config.set_value("ishikawa", "subsubbone_color", settings_tabs.get_node("Ishikawa/subsubbone_color").color)
	config.set_value("ishikawa", "text_color", settings_tabs.get_node("Ishikawa/text_color").color)
	config.set_value("ishikawa", "ui_text_color", settings_tabs.get_node("Ishikawa/ui_text_color").color)
	
	# Pareto settings
	config.set_value("pareto", "axis_color", settings_tabs.get_node("Pareto/axis_color").color)
	config.set_value("pareto", "bar_text_color", settings_tabs.get_node("Pareto/bar_text_color").color)
	config.set_value("pareto", "cumulative_line_color", settings_tabs.get_node("Pareto/cumulative_line_color").color)
	config.set_value("pareto", "cutoff_line_color", settings_tabs.get_node("Pareto/cutoff_line_color").color)
	config.set_value("pareto", "bar_first_color", settings_tabs.get_node("Pareto/bar_first_color").color)
	config.set_value("pareto", "bar_last_color", settings_tabs.get_node("Pareto/bar_last_color").color)
	
	# Scatter Plot settings
	config.set_value("scatter", "axis_color", settings_tabs.get_node("ScatterPlot/axis_color").color)
	config.set_value("scatter", "label_text_color", settings_tabs.get_node("ScatterPlot/label_text_color").color)
	config.set_value("scatter", "input_text_color", settings_tabs.get_node("ScatterPlot/input_text_color").color)
	config.set_value("scatter", "point_color", settings_tabs.get_node("ScatterPlot/point_color").color)
	config.set_value("scatter", "regression_line_color", settings_tabs.get_node("ScatterPlot/regression_line_color").color)
	config.set_value("scatter", "grid_color", settings_tabs.get_node("ScatterPlot/grid_color").color)
	
	# Control Charts settings
	config.set_value("control_charts", "axis_color", settings_tabs.get_node("ControlCharts/axis_color").color)
	config.set_value("control_charts", "label_text_color", settings_tabs.get_node("ControlCharts/label_text_color").color)
	config.set_value("control_charts", "input_text_color", settings_tabs.get_node("ControlCharts/input_text_color").color)
	config.set_value("control_charts", "grid_color", settings_tabs.get_node("ControlCharts/grid_color").color)
	config.set_value("control_charts", "x_line_color", settings_tabs.get_node("ControlCharts/x_line_color").color)
	config.set_value("control_charts", "r_line_color", settings_tabs.get_node("ControlCharts/r_line_color").color)
	config.set_value("control_charts", "ucl_color", settings_tabs.get_node("ControlCharts/ucl_color").color)
	config.set_value("control_charts", "lcl_color", settings_tabs.get_node("ControlCharts/lcl_color").color)
	config.set_value("control_charts", "cl_color", settings_tabs.get_node("ControlCharts/cl_color").color)
	config.set_value("control_charts", "out_of_control_color", settings_tabs.get_node("ControlCharts/out_of_control_color").color)
	config.set_value("control_charts", "warning_color", settings_tabs.get_node("ControlCharts/warning_color").color)
	
	# Histogram settings
	config.set_value("histogram", "axis_color", settings_tabs.get_node("Histogram/axis_color").color)
	config.set_value("histogram", "label_text_color", settings_tabs.get_node("Histogram/label_text_color").color)
	config.set_value("histogram", "input_text_color", settings_tabs.get_node("Histogram/input_text_color").color)
	config.set_value("histogram", "bar_text_color", settings_tabs.get_node("Histogram/bar_text_color").color)
	config.set_value("histogram", "bar_first_color", settings_tabs.get_node("Histogram/bar_first_color").color)
	config.set_value("histogram", "bar_last_color", settings_tabs.get_node("Histogram/bar_last_color").color)
	config.set_value("histogram", "normal_curve_color", settings_tabs.get_node("Histogram/normal_curve_color").color)
	config.set_value("histogram", "mean_line_color", settings_tabs.get_node("Histogram/mean_line_color").color)
	config.set_value("histogram", "std_dev_line_color", settings_tabs.get_node("Histogram/std_dev_line_color").color)
	
	# Save to file
	config.save(CONFIG_FILE_PATH)
