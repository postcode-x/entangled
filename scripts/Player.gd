extends KinematicBody

# Player variables
var target_position = Vector3(0, 0, 0)
var cpu_position = Vector3(0, 0, 0)
var last_origin = Vector3(0, 0, 0)
var target_mirror = Vector3(0, 0, 0)

# Player states & input
var move_mode : bool = false
var mouse_coordinates = Vector2(0, 0)

# Player signals
signal start_moving()
signal move_completed(origin, target)
signal set_trap(coordinates, type)
signal player_collision(id)

onready var mode_button = get_tree().get_root().get_node("MainLevel/ModeButton/Container/CheckButton")
onready var camera = get_viewport().get_camera()
	
func _ready():
	
	Globals.set_game_state(Globals.current_player_position, Globals.GameEntities.PLAYER)	
	move_mode = mode_button.pressed
	translate(Globals.current_player_position)	
	cpu_position = Globals.current_cpu_position
	
	pass

func _input(event):
	
	if !Globals.game_over:
		
		cpu_position = Vector3(-transform.origin.x, transform.origin.y, -transform.origin.z)
		
		if event is InputEventScreenTouch:
			if event.is_pressed(): 
				# FIRST OPTION - MOVES AND INVENTORY
				if Globals.turn == 1 and not Globals.is_player_moving and not Globals.is_player_mirroring:
					mouse_coordinates = event.get_position()
					target_position = Globals.DROP_PLANE.intersects_ray(camera.project_ray_origin(mouse_coordinates),camera.project_ray_normal(mouse_coordinates))
					if  target_position.z < 2.2 and target_position.x < 2.2 and target_position.z > -2.2 and target_position.x > -2.2:
						target_position = Globals.get_square_center(target_position)
						if target_position.distance_to(transform.origin) > 0.5: # Process Player slides	
							if move_mode:
								if  Globals.is_ortoghonal(transform.origin, target_position):
										last_origin = transform.origin
										Globals.set_game_state(last_origin, Globals.GameEntities.EMPTY)
										Globals.is_player_moving = true
										emit_signal("start_moving")
							elif Globals.player_bomb_count  < Globals.MAX_BOMB:
								if !Globals.is_spot_used_by_object(target_position) and Vector2(target_position.x, target_position.z) != Vector2(transform.origin.x, transform.origin.z) and Vector2(target_position.x, target_position.z) != Vector2(cpu_position.x, cpu_position.z): 
									emit_signal("set_trap", target_position, Globals.GameEntities.BOMB)

	pass
		
func _physics_process(_delta):
	
	if !Globals.game_over:
	
		if Globals.turn == 1 and Globals.is_player_moving and not Globals.is_player_mirroring:
			if target_position.distance_to(transform.origin) > 2 * Globals.HEIGHT + Globals.ERROR_MARGIN:
				move_and_slide(Globals.SPEED_FACTOR * Globals.SPEED * (target_position-transform.origin).normalized())	
			else:
				transform.origin.x = target_position.x
				transform.origin.z = target_position.z
				Globals.turn = 0
				Globals.is_player_moving = false
				Globals.set_game_state(transform.origin, Globals.GameEntities.PLAYER)
				Globals.current_player_position = transform.origin
				emit_signal("move_completed", last_origin, target_position)
				
		if Globals.is_player_mirroring:
			if target_mirror.distance_to(transform.origin) > 2 * Globals.HEIGHT + Globals.ERROR_MARGIN:
				move_and_slide(Globals.SPEED_FACTOR * Globals.SPEED * (target_mirror-transform.origin).normalized())	
			else:
				transform.origin.x = target_mirror.x
				transform.origin.z = target_mirror.z
				Globals.set_game_state(transform.origin, Globals.GameEntities.PLAYER)
				Globals.current_player_position = transform.origin
				Globals.is_player_mirroring = false
		
		for i in range (get_slide_count() - 1):
			var col = get_slide_collision(i)
			if(col.collider.name != 'Board'):
				emit_signal("player_collision",  col.collider)

	pass
	
func _on_CPU_move_completed(cpu_last_origin: Vector3, target: Vector3):
	target_mirror = Vector3(-target.x, target.y, -target.z)
	Globals.set_game_state(transform.origin, Globals.GameEntities.EMPTY)
	Globals.is_player_mirroring = true
	pass # Replace with function body.

func _on_MainLevel_cpu_trap_ready(_type):
	Globals.turn = 1
	pass # Replace with function body.

func _on_CheckButton_pressed():
	move_mode = mode_button.pressed
	pass # Replace with function body.
