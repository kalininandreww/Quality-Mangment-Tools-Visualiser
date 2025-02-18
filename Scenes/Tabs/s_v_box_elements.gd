extends VBoxContainer

var elements_panel:Node

func _ready():
	elements_panel = %VBoxElements
	add_spine()
	setup_styles()


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
