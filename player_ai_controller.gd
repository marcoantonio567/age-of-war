extends Node

@export var enabled: bool = true
@export var think_interval: float = 0.25
@export var keep_queue_size: int = 5

var think_time: float = 0.0
var menu: Control
var player_base
var enemy_base
var player_units: Node2D
var enemy_units: Node2D
var ai_visualizer: Control
var last_decision: String = "observando"
var last_outputs := {}
var genome := {}
var run_finished: bool = false
var run_time: float = 0.0


func _ready():
	GlobalVariables.ensure_ai_genome()
	genome = GlobalVariables.ai_current_genome
	menu = get_node("/root/main_game/Camera2D/in_game_menu")
	player_base = get_node("/root/main_game/player_base")
	enemy_base = get_node("/root/main_game/enemy_base")
	player_units = get_node("/root/main_game/player_units")
	enemy_units = get_node("/root/main_game/enemy_units")
	ai_visualizer = menu.get_node_or_null("ai_decision_visualizer")


func _process(delta):
	if enabled == false:
		return
	run_time += delta
	think_time += delta
	if think_time < think_interval:
		return
	think_time = 0.0
	_play_turn()


func _play_turn():
	last_outputs = _build_decision_scores()
	_update_progress()
	_try_use_special()
	_try_advance_age()
	_try_manage_turrets()
	_try_train_units()
	GlobalVariables.record_ai_decision(last_decision, _build_visual_inputs(), last_outputs)
	_publish_visual_state()


func _try_advance_age():
	while last_outputs.get("advance", 0.0) >= 0.95 and GlobalVariables.player_exp >= GlobalVariables.get_exp_to_next_age():
		last_decision = "evoluir idade"
		menu._on_advance_pressed()


func _try_train_units():
	while menu.queue.size() < keep_queue_size:
		var unit_type = _choose_unit_to_train()
		if unit_type == "":
			return
		var money_before = GlobalVariables.player_money
		last_decision = "treinar " + unit_type
		if unit_type == "super_soldier":
			menu._on_special_pressed()
		elif unit_type == "tank":
			menu._on_tank_pressed()
		elif unit_type == "range":
			menu._on_range_pressed()
		else:
			menu._on_melee_pressed()
		if GlobalVariables.player_money == money_before:
			return


func _choose_unit_to_train() -> String:
	var tank_cost = GlobalVariables.get_unit_cost("tank", GlobalVariables.current_stage)
	var range_cost = GlobalVariables.get_unit_cost("range", GlobalVariables.current_stage)
	var melee_cost = GlobalVariables.get_unit_cost("melee", GlobalVariables.current_stage)
	var money = GlobalVariables.player_money

	if GlobalVariables.current_stage == GlobalVariables.stage.future and money >= 150000 and last_outputs.get("tank", 0.0) > 0.72:
		return "super_soldier"
	if money >= tank_cost and last_outputs.get("tank", 0.0) >= last_outputs.get("range", 0.0) and last_outputs.get("tank", 0.0) >= last_outputs.get("melee", 0.0):
		return "tank"
	if money >= range_cost and last_outputs.get("range", 0.0) >= last_outputs.get("melee", 0.0):
		return "range"
	if money >= melee_cost:
		return "melee"
	if money >= range_cost:
		return "range"
	if money >= tank_cost:
		return "tank"
	return ""


func _try_use_special():
	var special_button = menu.get_node("special_button")
	if special_button.disabled == true:
		return
	if last_outputs.get("special", 0.0) < 0.58:
		return
	last_decision = "usar especial"
	special_button._pressed()
	menu._on_special_button_pressed()


func _try_manage_turrets():
	if player_base == null:
		return
	var money = GlobalVariables.player_money
	var slot_price = player_base.get_price_of_new_turret_slot()
	if last_outputs.get("turret", 0.0) > 0.52 and slot_price != INF and money >= slot_price + _unit_reserve_money():
		last_decision = "abrir slot torre"
		GlobalVariables.player_money -= slot_price
		player_base.add_turret_spot()
		return

	if last_outputs.get("turret", 0.0) > 0.62:
		for tier in range(3, 0, -1):
			var price = GlobalVariables.get_turret_price(GlobalVariables.current_stage, tier)
			if GlobalVariables.player_money >= price + _unit_reserve_money():
				if player_base.buy_player_turret(GlobalVariables.get_current_age_as_string(), tier):
					last_decision = "comprar torre " + str(tier)
					GlobalVariables.player_money -= price
				return

	if last_outputs.get("turret", 0.0) > 0.48 and GlobalVariables.player_money >= _unit_reserve_money() * 2:
		if player_base.upgrade_player_turret(GlobalVariables.get_current_age_as_string()):
			last_decision = "melhorar torre"


func _unit_reserve_money() -> int:
	return GlobalVariables.get_unit_cost("range", GlobalVariables.current_stage) * 2


func _get_enemy_pressure() -> float:
	var closest_x = INF
	for unit in enemy_units.get_children():
		if _is_living_unit(unit):
			closest_x = min(closest_x, unit.global_position.x)
	if closest_x == INF:
		return 0.0
	var distance_from_base = max(0.0, closest_x - player_base.global_position.x)
	return clamp(1.0 - distance_from_base / 1150.0, 0.0, 1.0)


func _get_army_power(container: Node) -> float:
	var total = 0.0
	for unit in container.get_children():
		if _is_living_unit(unit):
			total += float(unit.health) + float(unit.damage) * 12.0
	return total


func _count_living_units(container: Node) -> int:
	var total = 0
	for unit in container.get_children():
		if _is_living_unit(unit):
			total += 1
	return total


func _is_living_unit(unit) -> bool:
	return unit != null and unit.get("health") != null and unit.health > 0


func _build_visual_inputs() -> Dictionary:
	var player_power = _get_army_power(player_units)
	var enemy_power = _get_army_power(enemy_units)
	var army_balance = 0.5
	if player_power + enemy_power > 0.0:
		army_balance = clamp(player_power / (player_power + enemy_power), 0.0, 1.0)
	return {
		"pressure": _get_enemy_pressure(),
		"money": clamp(float(GlobalVariables.player_money) / 150000.0, 0.0, 1.0),
		"xp": clamp(float(GlobalVariables.player_exp) / max(1.0, float(GlobalVariables.get_exp_to_next_age())), 0.0, 1.0),
		"army": army_balance,
		"base": clamp(float(player_base.health) / max(1.0, float(player_base.max_health)), 0.0, 1.0),
	}


func _build_decision_scores() -> Dictionary:
	var visual_inputs = _build_visual_inputs()
	var pressure = visual_inputs["pressure"] * float(genome.get("pressure", 1.0))
	var money = visual_inputs["money"] * float(genome.get("money", 1.0))
	var xp = visual_inputs["xp"]
	var army = visual_inputs["army"] * float(genome.get("army", 1.0))
	var base_health = visual_inputs["base"] * float(genome.get("base", 1.0))
	return {
		"advance": clamp(xp * float(genome.get("advance", 1.0)), 0.0, 1.0),
		"special": clamp((pressure * 0.75 + (1.0 - base_health) * 0.25) * float(genome.get("special", 1.0)), 0.0, 1.0),
		"turret": clamp((pressure * 0.55 + money * 0.25 + (1.0 - base_health) * 0.2) * float(genome.get("turret", 1.0)), 0.0, 1.0),
		"tank": clamp((pressure * 0.35 + (1.0 - army) * 0.35 + money * 0.3) * float(genome.get("tank", 1.0)), 0.0, 1.0),
		"range": clamp(((1.0 - pressure) * 0.35 + money * 0.45 + army * 0.2) * float(genome.get("range", 1.0)), 0.0, 1.0),
		"melee": clamp(((1.0 - money) * 0.45 + (1.0 - pressure) * 0.25 + 0.2) * float(genome.get("melee", 1.0)), 0.0, 1.0),
	}


func _publish_visual_state():
	if ai_visualizer == null:
		ai_visualizer = menu.get_node_or_null("ai_decision_visualizer")
	if ai_visualizer == null:
		return
	ai_visualizer.update_state(_build_visual_inputs(), last_outputs, last_decision)


func _update_progress():
	var stage_progress = float(GlobalVariables.current_stage) / float(GlobalVariables.stage.future)
	var enemy_base_damage = 0.0
	if enemy_base != null:
		enemy_base_damage = 1.0 - clamp(float(enemy_base.health) / max(1.0, float(enemy_base.max_health)), 0.0, 1.0)
	var own_base_health = 0.0
	if player_base != null:
		own_base_health = clamp(float(player_base.health) / max(1.0, float(player_base.max_health)), 0.0, 1.0)
	var survival_bonus = clamp(run_time / 420.0, 0.0, 1.0)
	GlobalVariables.ai_current_progress = clamp(stage_progress * 0.42 + enemy_base_damage * 0.42 + own_base_health * 0.08 + survival_bonus * 0.08, 0.0, 1.0)


func finish_run(won: bool, reason: String):
	if run_finished:
		return
	run_finished = true
	_update_progress()
	if won:
		GlobalVariables.ai_current_progress = 1.0
	GlobalVariables.finish_ai_training_run(won, GlobalVariables.ai_current_progress, reason)
