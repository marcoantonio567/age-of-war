extends range_unit


# Called when the node enters the scene tree for the first time.
func _ready():
	health = 90
	damage = 12
	move_speed = 50
	money_die_reward = 98
	
	sprite_die_position = Vector2(44, -46)
	sprite_idle_position = Vector2(6, -51)
	sprite_idle_attack_position = Vector2(18, -52)
	sprite_melee_attack_position = Vector2(30, -65)
	sprite_walk_position = Vector2(5, -52)
	sprite_walk_attack_position = Vector2(15, -50)
	multiple_melee_attack_animations = true
	
	super()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super(delta)


func idle_attack_state():
	super()
	if consume_animation_frame_event("range_damage", 14):
		do_damage($RayCast2D_range.get_collider())
	elif consume_animation_frame_event("range_sfx", 13):
		$sfx/range_sfx.play()

func melee_attack_state():
	super()
	if consume_animation_frame_event("melee_damage", 26):
		do_damage($RayCast2D_melee.get_collider())
	elif consume_animation_frame_event("melee_sfx", 24):
		if $AnimatedSprite2D.get_animation() == "melee_attack_2":
			$sfx/stab_sfx.play()
		else:
			$sfx/melee_sfx.play()

func walk_attack_state(delta):
	super(delta)
	if consume_animation_frame_event("walk_range_damage", 19):
		do_damage($RayCast2D_range.get_collider())
	elif consume_animation_frame_event("walk_range_sfx", 17):
		$sfx/range_sfx.play()
