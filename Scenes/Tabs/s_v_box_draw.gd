extends Control

@export var spine_position = Vector2(50, 540)
var branch_positions = []
var subbranch_positions = []

func _draw():
	draw_line(spine_position, spine_position + Vector2(400, 0), Color(0, 0, 0), 2)

	for branch in branch_positions:
		draw_line(branch.start, branch.end, Color(0, 0, 0), 2)

	for subbranch in subbranch_positions:
		draw_line(subbranch.start, subbranch.end, Color(0, 0, 0), 2)

func update_diagram():
	queue_redraw()
