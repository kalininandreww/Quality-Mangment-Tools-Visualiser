extends VBoxContainer

var elements_panel

func _ready():
	elements_panel = %VBoxElements
	add_spine()


func add_spine():
	var spine_container = VBoxContainer.new()
	
	var spine_label = Label.new()
	spine_label.text = "Хребет"
	
	var add_branch_button = Button.new()
	add_branch_button.text = "+"
	add_branch_button.connect("pressed", self.add_branch.bind(spine_container))
	
	spine_container.add_child(spine_label)
	spine_container.add_child(add_branch_button)
	elements_panel.add_child(spine_container)


func add_branch(parent_container):
	var branch_container = VBoxContainer.new()
	var branch_header = HBoxContainer.new()
	
	var branch_label = Label.new()
	branch_label.text = "Кость"
	
	var rename_button = Button.new()
	rename_button.text = "✎"
	rename_button.connect("pressed", self.rename_element.bind(branch_label))
	
	var add_subbranch_button = Button.new()
	add_subbranch_button.text = "+"
	add_subbranch_button.connect("pressed", self.add_subbranch.bind(branch_container))
	
	branch_header.add_child(branch_label)
	branch_header.add_child(rename_button)
	branch_header.add_child(add_subbranch_button)
	branch_container.add_child(branch_header)
	parent_container.add_child(branch_container)


func add_subbranch(parent_container):
	var subbranch_container = HBoxContainer.new()
	
	var subbranch_label = Label.new()
	subbranch_label.text = "Подкость"
	
	var rename_button = Button.new()
	rename_button.text = "✎"
	rename_button.connect("pressed", self.rename_element.bind(subbranch_label))
	
	subbranch_container.add_child(subbranch_label)
	subbranch_container.add_child(rename_button)
	parent_container.add_child(subbranch_container)


func rename_element(label):
	var line_edit = LineEdit.new()
	line_edit.text = label.text
	line_edit.connect("text_entered", self.on_rename_complete.bind(label, line_edit))
	line_edit.connect("focus_exited", self.on_rename_complete.bind(label, line_edit))
	label.replace_by(line_edit)
	line_edit.grab_focus()


func on_rename_complete(new_text, label, line_edit):
	label.text = new_text
	line_edit.queue_free()
	label.get_parent().add_child(label)
	label.show()
