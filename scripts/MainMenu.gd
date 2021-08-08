extends MarginContainer

func _ready():
	pass

func _on_NewGame_button_down():
	Globals.new_game()
	get_tree().change_scene("res://MainLevel.tscn")
	pass # LOAD NEW GAME

func _on_Continue_button_down():
	Globals.restore_game()
	get_tree().change_scene("res://MainLevel.tscn")
	pass # CONTINUE LAST GAME

func _on_Options_button_down():
	pass # SHOW OPTIONS
