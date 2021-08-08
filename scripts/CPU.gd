extends KinematicBody

# CPU main variables
var target_position = Vector3(0, 0, 0)
var player_position = Vector3(0, 0, 0)
var last_origin = Vector3(0, 0, 0)
var target_mirror = Vector3(0, 0, 0)

# RND initialization
onready var rnd = RandomNumberGenerator.new()

# CPU signals
signal start_moving()
signal move_completed(origin, target)
signal set_trap(coordinates, type)
signal cpu_collision(id)

func _ready():

	Globals.set_game_state(Globals.current_cpu_position, Globals.GameEntities.CPU)
	translate(Globals.current_cpu_position)
	rotate_y(PI)
	player_position = Globals.current_player_position
	
	pass
	
func process_cpu_move():
	
	var current_game_state = (Globals.get_game_state()).duplicate(true)
	
	if !Globals.game_over:
	
		player_position = Vector3(-transform.origin.x, transform.origin.y, -transform.origin.z)
		last_origin = transform.origin
		
		target_position.x = rnd.randf_range(-2, 2)
		target_position.z = rnd.randf_range(-2, 2)
		target_position = Globals.get_square_center(target_position)
		
		rnd.randomize()
		
		# RANDOM MOVE AND TRAP
		
		if  Globals.cpu_bomb_count < Globals.MAX_BOMB and rnd.randi_range(0, 1) == 1:
			while Vector2(target_position.x, target_position.z) == Vector2(transform.origin.x, transform.origin.z) or Vector2(target_position.x, target_position.z) == Vector2(player_position.x, player_position.z) or Globals.is_spot_used_by_object(target_position):
				target_position.x = rnd.randf_range(-2, 2)
				target_position.z = rnd.randf_range(-2, 2)
				target_position = Globals.get_square_center(target_position)
			emit_signal("set_trap", target_position, Globals.GameEntities.BOMB)
		else:
			while !Globals.is_ortoghonal(transform.origin, target_position) or Vector2(target_position.x, target_position.z) == Vector2(transform.origin.x, transform.origin.z) :
				target_position.x = rnd.randf_range(-2, 2)
				target_position.z = rnd.randf_range(-2, 2)
				target_position = Globals.get_square_center(target_position)
			Globals.is_cpu_moving = true	
			Globals.set_game_state(transform.origin, Globals.GameEntities.EMPTY)
			emit_signal("start_moving")
	
	pass
	
func _physics_process(_delta):
	
	if !Globals.game_over:
	
		if Globals.turn == 0 and Globals.is_cpu_moving and not Globals.is_cpu_mirroring:
			if target_position.distance_to(transform.origin) > 2 * Globals.HEIGHT + Globals.ERROR_MARGIN:
				move_and_slide(Globals.SPEED_FACTOR * Globals.SPEED * (target_position-transform.origin).normalized())	
			else:
				transform.origin.x = target_position.x
				transform.origin.z = target_position.z
				Globals.turn = 1
				Globals.is_cpu_moving = false
				Globals.set_game_state(transform.origin, Globals.GameEntities.CPU)
				Globals.current_cpu_position = transform.origin
				emit_signal("move_completed", last_origin, target_position)
				
		if Globals.is_cpu_mirroring:
			if target_mirror.distance_to(transform.origin) > 2 * Globals.HEIGHT + Globals.ERROR_MARGIN:
				move_and_slide(Globals.SPEED_FACTOR * Globals.SPEED * (target_mirror-transform.origin).normalized())	
			else:
				transform.origin.x = target_mirror.x
				transform.origin.z = target_mirror.z
				Globals.is_cpu_mirroring = false
				Globals.set_game_state(transform.origin, Globals.GameEntities.CPU)
				Globals.current_cpu_position = transform.origin
				process_cpu_move()
		
		for i in range (get_slide_count() - 1):
			var col = get_slide_collision(i)
			if(col.collider.name != 'Board'):
				emit_signal("cpu_collision",  col.collider)

	pass

func _on_Player_move_completed(player_last_origin : Vector3, target: Vector3):
	target_mirror = Vector3(-target.x, target.y, -target.z)
	# Globals.target_output_sample = Vector2(player_last_origin.x, player_last_origin.z) - Vector2(target.x, target.z)
	Globals.set_game_state(transform.origin, Globals.GameEntities.EMPTY)
	Globals.is_cpu_mirroring = true
	pass

func _on_MainLevel_player_trap_ready(_type):
	Globals.turn = 0
	process_cpu_move()
	pass # Replace with function body.
