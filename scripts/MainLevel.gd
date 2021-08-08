extends Spatial

onready var player_bomb = preload("res://assets/models/Bomb.tscn")
onready var cpu_bomb = preload("res://assets/models/Bomb.tscn")

onready var brain = preload("res://assets/models/Brain.tscn")
onready var heart = preload("res://assets/models/Heart.tscn")
onready var star = preload("res://assets/models/Star.tscn")
onready var coin = preload("res://assets/models/Coin.tscn")
onready var coinstack = preload("res://assets/models/CoinStack.tscn")

onready var timebomb = preload("res://assets/models/Timebomb.tscn")
onready var explosion_particle = preload("res://assets/models/ExplosionParticle.tscn")

onready var collision_sounds : Array = [$Sounds/Collision1, $Sounds/Collision2]
onready var rnd = RandomNumberGenerator.new()

const TOTAL_PARTICLES : int = 100
const TOTAL_GROUPS : int = 5 # MAKE SURE THIS IS DIVIDES TOTAL_PARTICLES PERFECTLY
const PARTICLE_GROUPS : int = TOTAL_PARTICLES / TOTAL_GROUPS 
const MAX_PARTICLE_SOUND : int = 10

var particle_x = 0
var particle_y = 0
var particle_z = 0

var current_max_spawn : int = 0
var current_spawn_counter : int = 0
var current_spawn_id : int = 0

var is_instance_being_loaded = false
var spawn_instance

onready var spawn_instance_timer = get_node("SpawnInstance")
onready var kill_instance_timer = get_node("KillInstance")
onready var immunity_timer = get_node("Immunity")

signal player_trap_ready(type)
signal cpu_trap_ready(type)
signal update_GUI()

func _ready():
	
	rnd.randomize()
	if Globals.music_enabled:
		$Song.play()
	
	immunity_timer.set_wait_time(Globals.STAR_IMMUNITY_DURATION)
	spawn_instance_timer.set_wait_time(rnd.randi_range(Globals.MIN_SPAWN_DELAY, Globals.MAX_SPAWN_DELAY))
	spawn_instance_timer.start()
	
	pass
	
func spawn_entity():
	
	is_instance_being_loaded = true
	
	var random_entity_index = rnd.randi_range(Globals.GameEntities.COIN, Globals.GameEntities.STAR)
	current_spawn_id = random_entity_index
	
	if random_entity_index ==  Globals.GameEntities.COIN:
		spawn_instance = coin.instance()
		Globals.coin_spawn_counter += 1
		current_spawn_counter = Globals.coin_spawn_counter
		current_max_spawn = Globals.MAX_COIN_SPAWN
	elif random_entity_index ==  Globals.GameEntities.COINSTACK:
		spawn_instance = coinstack.instance()
		Globals.coinstack_spawn_counter += 1
		current_spawn_counter = Globals.coinstack_spawn_counter
		current_max_spawn = Globals.MAX_COINSTACK_SPAWN
	elif random_entity_index ==  Globals.GameEntities.HEART:
		spawn_instance = heart.instance()
		Globals.heart_spawn_counter += 1
		current_spawn_counter = Globals.heart_spawn_counter
		current_max_spawn = Globals.MAX_HEART_SPAWN
	elif random_entity_index ==  Globals.GameEntities.BRAIN:
		spawn_instance = brain.instance()
		Globals.brain_spawn_counter += 1
		current_spawn_counter = Globals.brain_spawn_counter
		current_max_spawn = Globals.MAX_BRAIN_SPAWN
	elif random_entity_index ==  Globals.GameEntities.STAR:
		spawn_instance = star.instance()
		Globals.star_spawn_counter += 1
		current_spawn_counter = Globals.star_spawn_counter
		current_max_spawn = Globals.MAX_STAR_SPAWN
	elif random_entity_index ==  Globals.GameEntities.TIMEBOMB:
		spawn_instance = timebomb.instance()
		Globals.timebomb_spawn_counter += 1
		current_spawn_counter = Globals.timebomb_spawn_counter
		current_max_spawn = Globals.MAX_TIMEBOMB_SPAWN

	if current_spawn_counter <= current_max_spawn:
		var spawn_target_position = Vector3(0, 0, 0)
		spawn_target_position.x = rnd.randf_range(-2, 2)
		spawn_target_position.z = rnd.randf_range(-2, 2)
		spawn_target_position = Globals.get_square_center(spawn_target_position)
		while Vector2(spawn_target_position.x, spawn_target_position.z) == Vector2(Globals.current_player_position.x, Globals.current_player_position.z) or Vector2(spawn_target_position.x, spawn_target_position.z) == Vector2(Globals.current_cpu_position.x, Globals.current_cpu_position.z) or Globals.is_spot_used_by_object(spawn_target_position):
			spawn_target_position.x = rnd.randf_range(-2, 2)
			spawn_target_position.z = rnd.randf_range(-2, 2)
			spawn_target_position = Globals.get_square_center(spawn_target_position)
		spawn_target_position.y = 0.21
		spawn_instance.transform.origin = spawn_target_position
		Globals.current_entity_position = spawn_target_position
		Globals.set_game_state(Globals.current_entity_position, random_entity_index)
		add_child(spawn_instance)
		if random_entity_index == Globals.GameEntities.TIMEBOMB:
			kill_instance_timer.set_wait_time(Globals.TIMEBOMB_DURATION)
		else:
			kill_instance_timer.set_wait_time(Globals.GENERIC_INSTANCE_DURATION)
		kill_instance_timer.start()
	else:
		spawn_instance.queue_free()
		is_instance_being_loaded = false
		spawn_instance_timer.set_wait_time(rnd.randi_range(Globals.MIN_SPAWN_DELAY, Globals.MAX_SPAWN_DELAY))
		spawn_instance_timer.start()
	
	pass	

func _physics_process(delta):
	
	if !Globals.game_over:
			
		if Globals.explosions_enabled:
		
			for i in range(len(Globals.explosion_particle_instance)):
				if Globals.explosion_particle_instance[i].is_inside_tree():
					particle_x = Globals.explosion_particle_instance[i].transform.origin.x
					particle_y = Globals.explosion_particle_instance[i].transform.origin.y
					particle_z = Globals.explosion_particle_instance[i].transform.origin.z
					if particle_x > 5 or particle_z > 5 or particle_x < -5 or particle_z < -5 or particle_y < -5:
						Globals.explosion_particle_instance[i].set_sleeping(true) 
						Globals.explosion_particle_instance[i].transform.origin.y = 10


		if Globals.is_player_bomb_moving and len(Globals.player_bomb_instance) > 0:
				var i = len(Globals.player_bomb_instance) - 1
				if Globals.player_bomb_target_position.distance_to(Globals.player_bomb_instance[i].transform.origin) > 0.45:
					Globals.player_bomb_instance[i].move_and_slide(Globals.SPEED_FACTOR * Globals.SPEED * (Globals.player_bomb_target_position-Globals.player_bomb_instance[i].transform.origin).normalized())	
				else:
					Globals.player_bomb_instance[i].transform.origin.x = Globals.player_bomb_target_position.x
					Globals.player_bomb_instance[i].transform.origin.y = 0.21
					Globals.player_bomb_instance[i].transform.origin.z = Globals.player_bomb_target_position.z
					Globals.player_bomb_count += 1	
					Globals.is_player_bomb_moving = false
					Globals.set_game_state(Globals.player_bomb_instance[i].transform.origin, Globals.GameEntities.BOMB)
					emit_signal("player_trap_ready", Globals.GameEntities.BOMB)
					
		if Globals.is_cpu_bomb_moving and len(Globals.cpu_bomb_instance) > 0:
				var i = len(Globals.cpu_bomb_instance) - 1
				if Globals.cpu_bomb_target_position.distance_to(Globals.cpu_bomb_instance[i].transform.origin) > 0.45:
					Globals.cpu_bomb_instance[i].move_and_slide(Globals.SPEED_FACTOR * Globals.SPEED * (Globals.cpu_bomb_target_position-Globals.cpu_bomb_instance[i].transform.origin).normalized())	
				else:
					Globals.cpu_bomb_instance[i].transform.origin.x = Globals.cpu_bomb_target_position.x
					Globals.cpu_bomb_instance[i].transform.origin.y = 0.21
					Globals.cpu_bomb_instance[i].transform.origin.z = Globals.cpu_bomb_target_position.z
					Globals.cpu_bomb_count += 1
					Globals.is_cpu_bomb_moving = false
					Globals.set_game_state(Globals.cpu_bomb_instance[i].transform.origin, Globals.GameEntities.BOMB)
					emit_signal("cpu_trap_ready", Globals.GameEntities.BOMB)
				
	if Globals.instance_rotation_enabled:
		
		for k in range(len(Globals.player_bomb_instance)):
			if is_instance_valid(Globals.player_bomb_instance[k]):
				if Globals.player_bomb_instance[k].transform.origin.y <  2.5:
					Globals.player_bomb_instance[k].rotate_y(delta)
				
		for k in range(len(Globals.cpu_bomb_instance)):
			if is_instance_valid(Globals.cpu_bomb_instance[k]):
				if Globals.cpu_bomb_instance[k].transform.origin.y < 2.5:
					Globals.cpu_bomb_instance[k].rotate_y(delta)
					
		if is_instance_valid(spawn_instance):
			spawn_instance.rotate_y(delta)
			
	pass
		
func _on_Player_set_trap(coordinates, type):
	Globals.turn = 2
	Globals.player_bomb_target_position = coordinates
	match (type):
		Globals.GameEntities.BOMB:
			Globals.player_bomb_instance.append(player_bomb.instance())
			Globals.player_bomb_instance[len(Globals.player_bomb_instance) - 1].transform.origin = Vector3(coordinates.x, 2.0, coordinates.z)
			self.add_child(Globals.player_bomb_instance[len(Globals.player_bomb_instance) - 1])
			Globals.is_player_bomb_moving = true
	pass 

func _on_CPU_set_trap(coordinates, type):
	Globals.turn = 2
	Globals.cpu_bomb_target_position = coordinates
	match (type):
		Globals.GameEntities.BOMB:
			Globals.cpu_bomb_instance.append(cpu_bomb.instance())
			Globals.cpu_bomb_instance[len(Globals.cpu_bomb_instance) - 1].transform.origin = Vector3(coordinates.x, 2.0, coordinates.z)
			self.add_child(Globals.cpu_bomb_instance[len(Globals.cpu_bomb_instance) - 1])
			Globals.is_cpu_bomb_moving = true
	pass 


func _on_Player_player_collision(id):
	process_collision('player', id)
	pass 

func _on_CPU_cpu_collision(id):
	process_collision('cpu', id)
	pass 

func process_collision(controller, collider_id):
	
	var collider_filename = collider_id.filename
	var explosion_origin = collider_id.transform.origin
	
	if collider_id == spawn_instance and collider_filename != timebomb.get_path() and !Globals.collider_id_duplicate_filter.has(collider_id):
		
		Globals.collider_id_duplicate_filter.append(collider_id)
		
		if controller == 'player':
			if collider_filename == coin.get_path():
				Globals.player_coins += Globals.COIN_INCREASE
			elif collider_filename == coinstack.get_path():
				Globals.player_coins += Globals.COIN_STACK_INCREASE
			elif collider_filename == brain.get_path():
				Globals.player_brains += Globals.BRAIN_INCREASE
			elif collider_filename == heart.get_path():
				if Globals.player_health < Globals.MAX_HEALTH:
					Globals.player_health += Globals.HEART_INCREASE
			elif collider_filename == star.get_path():
				Globals.is_player_immune = true
				immunity_timer.start()
		elif controller == 'cpu':
			if collider_filename == coin.get_path():
				Globals.cpu_coins += Globals.COIN_INCREASE
			elif collider_filename == coinstack.get_path():
				Globals.cpu_coins += Globals.COIN_STACK_INCREASE
			elif collider_filename == brain.get_path():
				Globals.cpu_brains += Globals.BRAIN_INCREASE
			elif collider_filename == heart.get_path():
				if Globals.cpu_health < Globals.MAX_HEALTH:
					Globals.cpu_health += Globals.HEART_INCREASE
			elif collider_filename == star.get_path():
				Globals.is_cpu_immune = true
				immunity_timer.start()		
				
		kill_spawned_instances_reset_timers()
		emit_signal("update_GUI")
		
		Globals.collider_id_duplicate_filter.pop_back()
					
	elif collider_filename == timebomb.get_path() and !Globals.collider_id_duplicate_filter.has(collider_id):
		
		Globals.collider_id_duplicate_filter.append(collider_id)
		
		spawn_instance.transform.origin = Vector3(0, -99, 0)
		spawn_instance.transform.origin = Globals.DISCARDED_TRAP_VECTOR
		Globals.set_game_state(explosion_origin, Globals.GameEntities.EMPTY)
		process_explosion(explosion_origin, collider_filename, controller)		
		kill_spawned_instances_reset_timers()
		
		Globals.collider_id_duplicate_filter.pop_back()
	
	else:
			
		if Globals.cpu_bomb_instance.has(collider_id) and !Globals.collider_id_duplicate_filter.has(collider_id):
			var index = Globals.cpu_bomb_instance.find(collider_id)
			if index != -1:
				Globals.collider_id_duplicate_filter.append(collider_id)
				Globals.cpu_bomb_instance[index].queue_free()
				Globals.cpu_bomb_instance.remove(index)
				Globals.collider_id_duplicate_filter.pop_back()
					
				var bomb_position = collider_id.transform.origin
				Globals.set_game_state(bomb_position, Globals.GameEntities.EMPTY)
				process_explosion(bomb_position, collider_id.filename, controller)
					
		elif Globals.player_bomb_instance.has(collider_id) and !Globals.collider_id_duplicate_filter.has(collider_id):
			var index = Globals.player_bomb_instance.find(collider_id)
			if index != -1:
				Globals.collider_id_duplicate_filter.append(collider_id)
				Globals.player_bomb_instance[index].queue_free()
				Globals.player_bomb_instance.remove(index)
				Globals.collider_id_duplicate_filter.pop_back()
					
				var bomb_position = collider_id.transform.origin
				Globals.set_game_state(bomb_position, Globals.GameEntities.EMPTY)
				process_explosion(bomb_position, collider_id.filename, controller)
	
	pass

func process_explosion(explosion_origin : Vector3, collider_filename : String, controller : String):
	
	#print('direct collision with: ', collider_filename)
	
	rnd.randomize()
		
	if Globals.sound_enabled:
		collision_sounds[rnd.randi_range(0, len(collision_sounds) - 1)].play()
		
	if Globals.explosions_enabled:
		
		if len(Globals.explosion_particle_instance) < TOTAL_PARTICLES:
			for _i in range(PARTICLE_GROUPS):
				Globals.explosion_particle_instance.append(explosion_particle.instance())
			
		for i in range(Globals.explosion_counter * PARTICLE_GROUPS, (Globals.explosion_counter + 1) * PARTICLE_GROUPS):
			Globals.explosion_particle_instance[i].transform.origin = explosion_origin + Vector3(rnd.randf_range(-0.5, 0.5), rnd.randf_range(0, 2), rnd.randf_range(-0.5, 0.5))
			Globals.explosion_particle_instance[i].add_force(Vector3(rnd.randf_range(-100, 100), rnd.randf_range(200, 800), rnd.randf_range(-100, 100)), Vector3(0, 0, 0))
			Globals.explosion_particle_instance[i].add_torque(Vector3(1, 2, 2))
			if !Globals.explosion_particle_instance[i].is_inside_tree():
				add_child(Globals.explosion_particle_instance[i])
				
		if Globals.explosion_counter < TOTAL_GROUPS - 1: 
			Globals.explosion_counter += 1
		else:
			Globals.explosion_counter = 0

	var damage_factor = 1.0
	
	if collider_filename == timebomb.get_path():
		damage_factor *= 2.0
	
	if controller == 'player' and !Globals.is_player_immune:
		Globals.player_health -= 10 * damage_factor
	elif controller == 'cpu' and !Globals.is_cpu_immune:
		Globals.cpu_health -= 10 * damage_factor
		
	if Globals.player_health <= 0 or Globals.cpu_health <= 0 or (Globals.MAX_BOMB - Globals.player_bomb_count == 0 and Globals.MAX_BOMB - Globals.cpu_bomb_count == 0):
	
		if (Globals.MAX_BOMB - Globals.player_bomb_count == 0 and Globals.MAX_BOMB - Globals.cpu_bomb_count == 0):
			print('no more bombs left. Game over')
		
		if Globals.player_health <= 0:
			Globals.player_health = 0
			print('player health depleted. Game ended.')
		elif Globals.cpu_health <= 0:
			Globals.cpu_health = 0
			print('cpu health depleted. Game ended.')
		
		set_game_over()
		
	emit_signal("update_GUI")
				
	pass
	
func set_game_over():
	
	emit_signal("update_GUI")
	Globals.game_over = true
	if is_instance_valid(spawn_instance):
		spawn_instance.queue_free()
	kill_instance_timer.stop()
	spawn_instance_timer.stop()
	Globals.new_game()
	get_tree().change_scene("res://MainLevel.tscn")
	
	pass
	
func timebomb_explosion():
	
	var explosion_origin = Globals.current_entity_position
	
	rnd.randomize()
		
	if Globals.sound_enabled:
		collision_sounds[rnd.randi_range(0, len(collision_sounds) - 1)].play()
		
	if Globals.explosions_enabled:
		
		if len(Globals.explosion_particle_instance) < TOTAL_PARTICLES:
			for _i in range(PARTICLE_GROUPS):
				Globals.explosion_particle_instance.append(explosion_particle.instance())
			
		for i in range(Globals.explosion_counter * PARTICLE_GROUPS, (Globals.explosion_counter + 1) * PARTICLE_GROUPS):
			Globals.explosion_particle_instance[i].transform.origin = explosion_origin + Vector3(rnd.randf_range(-0.5, 0.5), rnd.randf_range(0, 2), rnd.randf_range(-0.5, 0.5))
			Globals.explosion_particle_instance[i].add_force(Vector3(rnd.randf_range(-100, 100), rnd.randf_range(200, 800), rnd.randf_range(-100, 100)), Vector3(0, 0, 0))
			Globals.explosion_particle_instance[i].add_torque(Vector3(1, 2, 2))
			if !Globals.explosion_particle_instance[i].is_inside_tree():
				add_child(Globals.explosion_particle_instance[i])
				
		if Globals.explosion_counter < TOTAL_GROUPS - 1: 
			Globals.explosion_counter += 1
		else:
			Globals.explosion_counter = 0

	if !Globals.is_player_immune and Vector2(Globals.current_player_position.x, Globals.current_player_position.z).distance_to(Vector2(explosion_origin.x, explosion_origin.z)) < 1.5:
		Globals.player_health -= 20
	if !Globals.is_cpu_immune and Vector2(Globals.current_cpu_position.x, Globals.current_cpu_position.z).distance_to(Vector2(explosion_origin.x, explosion_origin.z)) < 1.5:
		Globals.cpu_health -= 20
	
	if Globals.player_health <= 0 or Globals.cpu_health <= 0 or (Globals.MAX_BOMB - Globals.player_bomb_count == 0 and Globals.MAX_BOMB - Globals.cpu_bomb_count == 0):
	
		if (Globals.MAX_BOMB - Globals.player_bomb_count == 0 and Globals.MAX_BOMB - Globals.cpu_bomb_count == 0):
			print('no more bombs left. Game over')
		
		if Globals.player_health <= 0:
			Globals.player_health = 0
			print('player health depleted. Game ended.')
		elif Globals.cpu_health <= 0:
			Globals.cpu_health = 0
			print('cpu health depleted. Game ended.')
	
		set_game_over()
		
	emit_signal("update_GUI")
	
	pass

func _on_Player_start_moving():
	play_move_sound()
	pass


func _on_CPU_start_moving():
	play_move_sound()
	pass 

func play_move_sound():
	if Globals.sound_enabled:
		$Sounds/SlideMove.play()


func _on_SpawnInstance_timeout():
	if !is_instance_being_loaded and !Globals.is_cpu_moving and !Globals.is_player_moving and !Globals.is_player_mirroring and !Globals.is_cpu_mirroring and !Globals.is_player_bomb_moving and !Globals.is_cpu_bomb_moving:
			spawn_instance_timer.stop()
			spawn_entity()
	else:
		is_instance_being_loaded = false
		spawn_instance_timer.set_wait_time(Globals.ONE_SECOND_DELAY) # Wait 1 second & try again
		spawn_instance_timer.start()
	pass 


func _on_KillInstance_timeout():
	
	if current_spawn_id == Globals.GameEntities.TIMEBOMB:
		timebomb_explosion()
	kill_spawned_instances_reset_timers()
	
	pass 
	
func kill_spawned_instances_reset_timers():
	
	if is_instance_valid(spawn_instance):
		spawn_instance.queue_free()
		Globals.set_game_state(Globals.current_entity_position, Globals.GameEntities.EMPTY)			
	
	kill_instance_timer.stop()
	is_instance_being_loaded = false
	spawn_instance_timer.set_wait_time(rnd.randi_range(Globals.MIN_SPAWN_DELAY, Globals.MAX_SPAWN_DELAY))
	spawn_instance_timer.start()
	
	pass


func _on_Immunity_timeout():
	if Globals.is_player_immune:
		Globals.is_player_immune = false
	elif Globals.is_cpu_immune:
		Globals.is_cpu_immune = false
	immunity_timer.stop()
	pass 
