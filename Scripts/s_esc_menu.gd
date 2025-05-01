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

func _on_quit_button_pressed():
	esc_menu.visible = false
	quit_confirmation.visible = true

func _on_settings_button_pressed():
	esc_menu.visible = false
	settings_panel.visible = true

func _on_quit_yes_pressed():
	quit_confirmation.visible = false
	var current_scene_path = get_tree().current_scene.scene_file_path
	
	if current_scene_path == MAIN_MENU_PATH:
		get_tree().quit()
	else:
		get_tree().change_scene_to_packed(load(MAIN_MENU_PATH))

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
	set_color_picker_value(%spine_color, config.get_value("ishikawa", "spine_color", Color.BLACK))
	set_color_picker_value(%branch_color, config.get_value("ishikawa", "branch_color", Color.BLACK))
	set_color_picker_value(%subbranch_color, config.get_value("ishikawa", "subbranch_color", Color.BLACK))
	set_color_picker_value(%subsubbone_color, config.get_value("ishikawa", "subsubbone_color", Color.BLACK))
	set_color_picker_value(%text_color, config.get_value("ishikawa", "text_color", Color.BLACK))
	set_color_picker_value(%ui_text_color, config.get_value("ishikawa", "ui_text_color", Color.BLACK))
	
	# Pareto settings
	set_color_picker_value(%paretto_background_color, config.get_value("pareto", "paretto_background_color", Color("#FEFAE0")))
	set_color_picker_value(%axis_color, config.get_value("pareto", "axis_color", Color.WHITE))
	set_color_picker_value(%bar_text_color, config.get_value("pareto", "bar_text_color", Color.WHITE))
	set_color_picker_value(%cumulative_line_color, config.get_value("pareto", "cumulative_line_color", Color.RED))
	set_color_picker_value(%cutoff_line_color, config.get_value("pareto", "cutoff_line_color", Color.YELLOW))
	set_color_picker_value(%bar_first_color, config.get_value("pareto", "bar_first_color", Color(0.2, 0.7, 0.9)))
	set_color_picker_value(%bar_last_color, config.get_value("pareto", "bar_last_color", Color(0.8, 0.3, 0.3)))
	
	#Scatter Plot settings
	set_color_picker_value(%sp_background_color, config.get_value("scatter", "background_color", Color("#FEFAE0")))
	set_color_picker_value(%sp_axis_color, config.get_value("scatter", "axis_color", Color.WHITE))
	set_color_picker_value(%sp_label_text_color, config.get_value("scatter", "label_text_color", Color.WHITE))
	set_color_picker_value(%sp_input_text_color, config.get_value("scatter", "input_text_color", Color.WHITE))
	set_color_picker_value(%sp_point_color, config.get_value("scatter", "point_color", Color(0.2, 0.7, 0.9)))
	set_color_picker_value(%sp_regression_line_color, config.get_value("scatter", "regression_line_color", Color.RED))
	set_color_picker_value(%sp_grid_color, config.get_value("scatter", "grid_color", Color(0.3, 0.3, 0.3, 0.5)))
	
	
	 #Control Charts settings
	set_color_picker_value(%cc_background_color, config.get_value("control_charts", "background_color", Color("#FEFAE0")))
	set_color_picker_value(%cc_axis_color, config.get_value("control_charts", "axis_color", Color.BLACK))
	set_color_picker_value(%cc_label_text_color, config.get_value("control_charts", "label_text_color", Color.BLACK))
	set_color_picker_value(%cc_input_text_color, config.get_value("control_charts", "input_text_color", Color.WHITE))
	set_color_picker_value(%cc_grid_color, config.get_value("control_charts", "grid_color", Color(0.3, 0.3, 0.3)))
	set_color_picker_value(%cc_x_line_color, config.get_value("control_charts", "x_line_color", Color(0.2, 0.7, 0.9)))
	set_color_picker_value(%cc_r_line_color, config.get_value("control_charts", "r_line_color", Color(0.8, 0.3, 0.3)))
	set_color_picker_value(%cc_ucl_color, config.get_value("control_charts", "ucl_color", Color.RED))
	set_color_picker_value(%cc_lcl_color, config.get_value("control_charts", "lcl_color", Color.RED))
	set_color_picker_value(%cc_cl_color, config.get_value("control_charts", "cl_color", Color.GREEN))
	set_color_picker_value(%cc_out_of_control_color, config.get_value("control_charts", "out_of_control_color", Color.YELLOW))
	set_color_picker_value(%cc_warning_color, config.get_value("control_charts", "warning_color", Color.ORANGE))
	
	## Histogram settings
	#set_color_picker_value("Histogram/axis_color", config.get_value("histogram", "axis_color", Color.WHITE))
	#set_color_picker_value("Histogram/label_text_color", config.get_value("histogram", "label_text_color", Color.WHITE))
	#set_color_picker_value("Histogram/input_text_color", config.get_value("histogram", "input_text_color", Color.WHITE))
	#set_color_picker_value("Histogram/bar_text_color", config.get_value("histogram", "bar_text_color", Color.WHITE))
	#set_color_picker_value("Histogram/bar_first_color", config.get_value("histogram", "bar_first_color", Color(0.2, 0.7, 0.9)))
	#set_color_picker_value("Histogram/bar_last_color", config.get_value("histogram", "bar_last_color", Color(0.8, 0.3, 0.3)))
	#set_color_picker_value("Histogram/normal_curve_color", config.get_value("histogram", "normal_curve_color", Color.RED))
	#set_color_picker_value("Histogram/mean_line_color", config.get_value("histogram", "mean_line_color", Color.GREEN))
	#set_color_picker_value("Histogram/std_dev_line_color", config.get_value("histogram", "std_dev_line_color", Color.YELLOW))

# Set color picker value by path
func set_color_picker_value(path, color):
	var picker = path
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
		tool.background_color = %background_color.color
		tool.spine_color = %spine_color.color
		tool.branch_color = %branch_color.color
		tool.subbranch_color = %subbranch_color.color
		tool.subsubbone_color = %subsubbone_color.color
		tool.text_color = %text_color.color
		tool.ui_text_color = %ui_text_color.color
		tool.update_colors()
	
	# Apply Pareto settings
	for tool in pareto_tools:
		tool.background_color = %paretto_background_color.color
		tool.axis_color = %axis_color.color
		tool.bar_text_color = %bar_text_color.color
		tool.cumulative_line_color = %cumulative_line_color.color
		tool.cutoff_line_color = %cutoff_line_color.color
		tool.bar_first_color = %bar_first_color.color
		tool.bar_last_color = %bar_last_color.color
		tool.update_colors()
	
	# Apply Scatter Plot settings
	for tool in scatter_tools:
		tool.background_color = %sp_background_color.color
		tool.axis_color = %sp_axis_color.color
		tool.label_text_color = %sp_label_text_color.color
		tool.input_text_color = %sp_input_text_color.color
		tool.point_color = %sp_point_color.color
		tool.regression_line_color = %sp_regression_line_color.color
		tool.grid_color = %sp_grid_color.color
		tool.update_colors()
	
	# Apply Control Charts settings
	for tool in control_charts_tools:
		tool.background_color = %cc_background_color.color
		tool.axis_color = %cc_axis_color.color
		tool.label_text_color = %cc_label_text_color.color
		tool.input_text_color = %cc_input_text_color.color
		tool.grid_color = %cc_grid_color.color
		tool.x_line_color = %cc_x_line_color.color
		tool.r_line_color = %cc_r_line_color.color
		tool.ucl_color = %cc_ucl_color.color
		tool.lcl_color = %cc_lcl_color.color
		tool.cl_color = %cc_cl_color.color
		tool.out_of_control_color = %cc_out_of_control_color.color
		tool.warning_color = %cc_warning_color.color
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
	config.set_value("ishikawa", "background_color",%background_color.color)
	config.set_value("ishikawa", "spine_color", %spine_color.color)
	config.set_value("ishikawa", "branch_color", %branch_color.color)
	config.set_value("ishikawa", "subbranch_color", %subbranch_color.color)
	config.set_value("ishikawa", "subsubbone_color", %subsubbone_color.color)
	config.set_value("ishikawa", "text_color", %text_color.color)
	config.set_value("ishikawa", "ui_text_color", %ui_text_color.color)
	
	# Pareto settings
	config.set_value("pareto", "background_color", %paretto_background_color.color)
	config.set_value("pareto", "axis_color", %axis_color.color)
	config.set_value("pareto", "bar_text_color", %bar_text_color.color)
	config.set_value("pareto", "cumulative_line_color", %cumulative_line_color.color)
	config.set_value("pareto", "cutoff_line_color", %cutoff_line_color.color)
	config.set_value("pareto", "bar_first_color", %bar_first_color.color)
	config.set_value("pareto", "bar_last_color", %bar_last_color.color)
	
	# Scatter Plot settings
	config.set_value("scatter", "background_color",  %sp_background_color.color)
	config.set_value("scatter", "axis_color", %sp_axis_color.color)
	config.set_value("scatter", "label_text_color", %sp_label_text_color.color)
	config.set_value("scatter", "input_text_color", %sp_input_text_color.color)
	config.set_value("scatter", "point_color", %sp_point_color.color)
	config.set_value("scatter", "regression_line_color", %sp_regression_line_color.color)
	config.set_value("scatter", "grid_color", %sp_grid_color.color)

	# Control Charts settings
	config.set_value("control_charts", "background_color",  %sp_background_color.color)
	config.set_value("control_charts", "axis_color", %cc_axis_color.color)
	config.set_value("control_charts", "label_text_color", %cc_label_text_color.color)
	config.set_value("control_charts", "input_text_color", %cc_input_text_color.color)
	config.set_value("control_charts", "grid_color", %cc_grid_color.color)
	config.set_value("control_charts", "x_line_color", %cc_x_line_color.color)
	config.set_value("control_charts", "r_line_color", %cc_r_line_color.color)
	config.set_value("control_charts", "ucl_color", %cc_ucl_color.color)
	config.set_value("control_charts", "lcl_color", %cc_lcl_color.color)
	config.set_value("control_charts", "cl_color", %cc_cl_color.color)
	config.set_value("control_charts", "out_of_control_color", %cc_out_of_control_color.color)
	config.set_value("control_charts", "warning_color", %cc_warning_color.color)
	
	## Histogram settings
	#config.set_value("histogram", "axis_color", settings_tabs.get_node("Histogram/axis_color").color)
	#config.set_value("histogram", "label_text_color", settings_tabs.get_node("Histogram/label_text_color").color)
	#config.set_value("histogram", "input_text_color", settings_tabs.get_node("Histogram/input_text_color").color)
	#config.set_value("histogram", "bar_text_color", settings_tabs.get_node("Histogram/bar_text_color").color)
	#config.set_value("histogram", "bar_first_color", settings_tabs.get_node("Histogram/bar_first_color").color)
	#config.set_value("histogram", "bar_last_color", settings_tabs.get_node("Histogram/bar_last_color").color)
	#config.set_value("histogram", "normal_curve_color", settings_tabs.get_node("Histogram/normal_curve_color").color)
	#config.set_value("histogram", "mean_line_color", settings_tabs.get_node("Histogram/mean_line_color").color)
	#config.set_value("histogram", "std_dev_line_color", settings_tabs.get_node("Histogram/std_dev_line_color").color)
	
	# Save to file
	config.save(CONFIG_FILE_PATH)
