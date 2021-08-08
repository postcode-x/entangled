extends MarginContainer

onready var player_coin_label = get_node('Feedback/Player/Counters/CoinCounter/Background/Number')
onready var player_brain_label = get_node('Feedback/Player/Counters/BrainCounter/Background/Number')
onready var player_bomb_label = get_node('Feedback/Player/Counters/BombCounter/Background/Number')

onready var player_health_label = get_node("Feedback/Player/Bars/Bar/Count/Background/Number")
onready var player_bar = get_node("Feedback/Player/Bars/Bar/Gauge")

onready var cpu_coin_label = get_node('Feedback/CPU/Counters/CoinCounter/Background/Number')
onready var cpu_brain_label = get_node('Feedback/CPU/Counters/BrainCounter/Background/Number')
onready var cpu_bomb_label = get_node('Feedback/CPU/Counters/BombCounter/Background/Number')

onready var cpu_health_label = get_node("Feedback/CPU/Bars/Bar/Count/Background/Number")
onready var cpu_bar = get_node("Feedback/CPU/Bars/Bar/Gauge")


func _ready():

	player_bar.max_value = Globals.MAX_HEALTH
	
	player_health_label.text = str(Globals.player_health)
	player_coin_label.text = str(Globals.player_coins)
	player_brain_label.text = str(Globals.player_brains)
	player_bomb_label.text = str(Globals.MAX_BOMB)	
	
	cpu_bar.max_value = Globals.MAX_HEALTH
	
	cpu_health_label.text = str(Globals.player_health)
	cpu_coin_label.text = str(Globals.cpu_coins)
	cpu_brain_label.text = str(Globals.cpu_brains)
	cpu_bomb_label.text = str(Globals.MAX_BOMB)
	
	pass 

func _on_MainLevel_cpu_trap_ready(_type):
	cpu_bomb_label.text = str(Globals.MAX_BOMB - Globals.cpu_bomb_count)
	pass

func _on_MainLevel_player_trap_ready(_type):
	player_bomb_label.text = str(Globals.MAX_BOMB - Globals.player_bomb_count)
	pass

func _on_MainLevel_update_GUI():
	
	player_coin_label.text = str(Globals.player_coins)
	player_brain_label.text = str(Globals.player_brains)
	player_health_label.text = str(Globals.player_health) 
	player_bar.value = Globals.player_health
	
	cpu_coin_label.text = str(Globals.cpu_coins)
	cpu_brain_label.text = str(Globals.cpu_brains)
	cpu_health_label.text = str(Globals.cpu_health) 
	cpu_bar.value = Globals.cpu_health
		
	pass 
