extends Node2D

var config := ConfigFile.new()
var default_window_size = DisplayServer.window_get_size()
var queue_move_to_center: bool = false
var move_to_center_delay_time: float = 0.0

var player_money
var player_exp
var game_speed: float = 1.0

enum stage {cave, knight, medival, miltary, future}
var current_stage

enum difficulty {normal, hard, impossible}
var current_difficulty

var ai_training_enabled: bool = true
var ai_generation: int = 1
var ai_current_progress: float = 0.0
var ai_decision_log: Array = []
var ai_last_run_decisions: Array = []
var ai_best_run: Dictionary = {}
var ai_current_genome: Dictionary = {}
var ai_best_genome: Dictionary = {}
var default_ai_genome := {
	"advance": 1.0,
	"special": 1.0,
	"turret": 1.0,
	"tank": 1.0,
	"range": 1.0,
	"melee": 1.0,
	"pressure": 1.0,
	"money": 1.0,
	"army": 1.0,
	"base": 1.0,
}

func _ready():
	load_config()
	ensure_ai_genome()
	reset_run_state()

func reset_run_state():
	player_money = 175
	player_exp = 0
	current_stage = stage.cave
	ai_current_progress = 0.0

func start_ai_training_run():
	current_difficulty = difficulty.impossible
	ai_last_run_decisions = []
	reset_run_state()
	ensure_ai_genome()

func ensure_ai_genome():
	if ai_current_genome.is_empty():
		ai_current_genome = default_ai_genome.duplicate(true)

func record_ai_decision(decision: String, inputs: Dictionary, outputs: Dictionary):
	var entry = {
		"generation": ai_generation,
		"time": Time.get_ticks_msec(),
		"decision": decision,
		"progress": ai_current_progress,
		"stage": get_current_age_as_string(),
		"money": player_money,
		"xp": player_exp,
		"inputs": inputs.duplicate(true),
		"outputs": outputs.duplicate(true),
		"genome": ai_current_genome.duplicate(true),
	}
	ai_last_run_decisions.append(entry)
	ai_decision_log.append(entry)
	if ai_decision_log.size() > 1200:
		ai_decision_log.pop_front()

func finish_ai_training_run(won: bool, progress: float, reason: String):
	var summary = {
		"generation": ai_generation,
		"won": won,
		"progress": progress,
		"reason": reason,
		"decisions": ai_last_run_decisions.duplicate(true),
		"genome": ai_current_genome.duplicate(true),
	}
	if won or ai_best_run.is_empty() or progress > float(ai_best_run.get("progress", 0.0)):
		ai_best_run = summary
		ai_best_genome = ai_current_genome.duplicate(true)
	if won == false:
		ai_current_genome = mutate_ai_genome(ai_best_genome if ai_best_genome.is_empty() == false else ai_current_genome)
		ai_generation += 1
	ai_last_run_decisions = []
	current_difficulty = difficulty.impossible
	reset_run_state()

func mutate_ai_genome(source_genome: Dictionary) -> Dictionary:
	var next_genome = source_genome.duplicate(true)
	for key in default_ai_genome.keys():
		var value = float(next_genome.get(key, default_ai_genome[key]))
		next_genome[key] = clamp(value + randf_range(-0.16, 0.16), 0.35, 2.25)
	return next_genome

func _process(delta: float) -> void:
	if queue_move_to_center:
		move_to_center_delay_time += delta
		if move_to_center_delay_time > 0.1: # Slight delay is required to let the OS resize the window
			move_to_center_delay_time = 0.0
			queue_move_to_center = false
			get_viewport().move_to_center()

func load_config() -> void:
	var config = config
	config.load("user://options.cfg")

	var value = config.get_value("Audio", "music", 1)
	var bus_index = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

	value = config.get_value("Audio", "sfx", 1)
	bus_index = AudioServer.get_bus_index("sfx")
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

	value = config.get_value("Video", "fullscreen", false)
	if value:
		get_window().mode = Window.MODE_FULLSCREEN
	else:
		get_window().mode = Window.MODE_WINDOWED

func update_fullscreen(toggled_on: bool) -> void:
	if toggled_on:
		get_window().mode = Window.MODE_FULLSCREEN
	else:
		get_window().mode = Window.MODE_WINDOWED
		DisplayServer.window_set_size(default_window_size)
		queue_move_to_center = true

func get_current_age_as_string():
	if current_stage == stage.cave:
		return "cave"
	elif current_stage == stage.knight:
		return "knight"
	elif current_stage == stage.medival:
		return "medival"
	elif current_stage == stage.miltary:
		return "miltary"
	elif current_stage == stage.future:
		return "future"

func _unhandled_key_input(event):
	if event.is_action_pressed("pause") and get_node("/root/main_game") != null and get_node("/root/main_game").process_mode == ProcessMode.PROCESS_MODE_INHERIT:
		get_node("/root/main_game").process_mode = ProcessMode.PROCESS_MODE_DISABLED
		get_node("/root/main_game/Camera2D/Label").show()
		get_node("/root/main_game/Camera2D/BtnReturn").show()
	elif event.is_action_pressed("pause") and get_node("/root/main_game") != null and get_node("/root/main_game").process_mode == ProcessMode.PROCESS_MODE_DISABLED:
		get_node("/root/main_game").process_mode = ProcessMode.PROCESS_MODE_INHERIT
		get_node("/root/main_game/Camera2D/Label").hide()
		get_node("/root/main_game/Camera2D/BtnReturn").hide()

func get_unit_name(unit_type: String, input_stage):
	if input_stage == "cave":
		if unit_type == "melee":
			return "Club Man"
		elif unit_type == "range":
			return "Slingshot Man"
		elif unit_type == "tank":
			return "Dino Rider"
	elif input_stage == "knight":
		if unit_type == "melee":
			return "Sword Man"
		elif unit_type == "range":
			return "Archer"
		elif unit_type == "tank":
			return "Knight"
	elif input_stage == "medival":
		if unit_type == "melee":
			return "Dueler"
		elif unit_type == "range":
			return "Musketeer"
		elif unit_type == "tank":
			return "Cannoneer"
	elif input_stage == "miltary":
		if unit_type == "melee":
			return "Melee Infantry"
		elif unit_type == "range":
			return "Infantry"
		elif unit_type == "tank":
			return "Tank"
	elif input_stage == "future":
		if unit_type == "melee":
			return "God's Blade"
		elif unit_type == "range":
			return "Blaster"
		elif unit_type == "tank":
			return "War Machine"
		elif unit_type == "super_soldier":
			return "super soldier"

func get_unit_cost(unit_type: String, input_stage):
	if input_stage == stage.cave:
		if unit_type == "melee":
			return 15
		elif unit_type == "range":
			return 25
		elif unit_type == "tank":
			return 100
	elif input_stage == stage.knight:
		if unit_type == "melee":
			return 50
		elif unit_type == "range":
			return 75
		elif unit_type == "tank":
			return 500
	elif input_stage == stage.medival:
		if unit_type == "melee":
			return 200
		elif unit_type == "range":
			return 400
		elif unit_type == "tank":
			return 1000
	elif input_stage == stage.miltary:
		if unit_type == "melee":
			return 1500
		elif unit_type == "range":
			return 2000
		elif unit_type == "tank":
			return 7000
	elif input_stage == stage.future:
		if unit_type == "melee":
			return 5000
		elif unit_type == "range":
			return 6000
		elif unit_type == "tank":
			return 20000


func get_turret_name(query_stage, turret_number: int):
	if query_stage == stage.cave:
		if turret_number == 1:
			return "Rock Slingshot"
		elif turret_number == 2:
			return "Egg Automatic"
		elif turret_number == 3:
			return "Primitive Catapult"
	elif query_stage == stage.knight:
		if turret_number == 1:
			return "Catapult"
		elif turret_number == 2:
			return "Fire Catapult"
		elif turret_number == 3:
			return "Oil"
	elif query_stage == stage.medival:
		if turret_number == 1:
			return "Small Cannon"
		elif turret_number == 2:
			return "Large Cannon"
		elif turret_number == 3:
			return "Explosive Cannon"
	elif query_stage == stage.miltary:
		if turret_number == 1:
			return "Single Turret"
		elif turret_number == 2:
			return "Rocket Launcher"
		elif turret_number == 3:
			return "Double Turret"
	elif query_stage == stage.future:
		if turret_number == 1:
			return "Titanium Shooter"
		elif turret_number == 2:
			return "Laser Cannon"
		elif turret_number == 3:
			return "Ion Cannon"


func get_stage_from_string(string: String):
	if string == "cave":
		return stage.cave
	elif string == "knight":
		return stage.knight
	elif string == "medival":
		return stage.medival
	elif string == "miltary":
		return stage.miltary
	elif string == "future":
		return stage.future

func get_turret_price(query_stage, turret_number: int):
	if query_stage == stage.cave:
		if turret_number == 1:
			return 100
		elif turret_number == 2:
			return 200
		elif turret_number == 3:
			return 500
	elif query_stage == stage.knight:
		if turret_number == 1:
			return 500
		elif turret_number == 2:
			return 750
		elif turret_number == 3:
			return 1000
	elif query_stage == stage.medival:
		if turret_number == 1:
			return 1500
		elif turret_number == 2:
			return 3000
		elif turret_number == 3:
			return 6000
	elif query_stage == stage.miltary:
		if turret_number == 1:
			return 7500
		elif turret_number == 2:
			return 9000
		elif turret_number == 3:
			return 14000
	elif query_stage == stage.future:
		if turret_number == 1:
			return 24000
		elif turret_number == 2:
			return 40000
		elif turret_number == 3:
			return 100000
	
	
func get_exp_to_next_age():
	if current_stage == stage.cave:
		return 4000
	elif current_stage == stage.knight:
		return 14000
	elif current_stage == stage.medival:
		return 45000
	elif current_stage == stage.miltary:
		return 200000
	elif current_stage == stage.future:
		return INF
