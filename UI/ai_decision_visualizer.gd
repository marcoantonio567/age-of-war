extends Control

var inputs := {
	"pressure": 0.0,
	"money": 0.0,
	"xp": 0.0,
	"army": 0.0,
	"base": 0.0,
}
var outputs := {
	"advance": 0.0,
	"special": 0.0,
	"turret": 0.0,
	"tank": 0.0,
	"range": 0.0,
	"melee": 0.0,
}
var decision: String = "observando"


func _ready():
	custom_minimum_size = Vector2(328, 224)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(_delta):
	queue_redraw()


func update_state(new_inputs: Dictionary, new_outputs: Dictionary, new_decision: String):
	for key in inputs.keys():
		inputs[key] = clamp(float(new_inputs.get(key, inputs[key])), 0.0, 1.0)
	for key in outputs.keys():
		outputs[key] = clamp(float(new_outputs.get(key, outputs[key])), 0.0, 1.0)
	decision = new_decision
	queue_redraw()


func _draw():
	var font = get_theme_font("font")
	var font_size = 13
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.025, 0.035, 0.78), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.35, 0.72, 1.0, 0.85), false, 2.0)
	draw_string(font, Vector2(12, 20), "IA visual - decisao: " + decision, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.92, 0.98, 1.0))

	var input_names = inputs.keys()
	var output_names = outputs.keys()
	var input_positions := []
	var hidden_positions := []
	var output_positions := []

	for i in range(input_names.size()):
		input_positions.append(Vector2(58, 48 + i * 29))
	for i in range(4):
		hidden_positions.append(Vector2(164, 58 + i * 34))
	for i in range(output_names.size()):
		output_positions.append(Vector2(270, 42 + i * 26))

	for input_index in range(input_positions.size()):
		var input_value = inputs[input_names[input_index]]
		for hidden_index in range(hidden_positions.size()):
			var strength = clamp(input_value * (0.35 + hidden_index * 0.18), 0.08, 1.0)
			draw_line(input_positions[input_index], hidden_positions[hidden_index], Color(0.4, 0.8, 1.0, strength * 0.28), 1.0 + strength)

	for hidden_index in range(hidden_positions.size()):
		for output_index in range(output_positions.size()):
			var output_value = outputs[output_names[output_index]]
			draw_line(hidden_positions[hidden_index], output_positions[output_index], Color(1.0, 0.78, 0.28, output_value * 0.45), 1.0 + output_value * 2.0)

	for i in range(input_positions.size()):
		var value = inputs[input_names[i]]
		_draw_neuron(input_positions[i], value, Color(0.25, 0.72, 1.0))
		draw_string(font, input_positions[i] + Vector2(-48, 5), str(input_names[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.82, 0.9, 1.0))

	for i in range(hidden_positions.size()):
		var hidden_value = _get_hidden_value(i)
		_draw_neuron(hidden_positions[i], hidden_value, Color(0.58, 0.95, 0.65))

	for i in range(output_positions.size()):
		var value = outputs[output_names[i]]
		_draw_neuron(output_positions[i], value, Color(1.0, 0.68, 0.22))
		draw_string(font, output_positions[i] + Vector2(12, 5), str(output_names[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.9, 0.72))


func _draw_neuron(position: Vector2, value: float, color: Color):
	draw_circle(position, 9.0, Color(0.02, 0.03, 0.045, 1.0))
	draw_circle(position, 5.0 + value * 5.0, Color(color.r, color.g, color.b, 0.35 + value * 0.65))
	draw_arc(position, 11.0, -PI / 2.0, -PI / 2.0 + TAU * value, 20, Color(1, 1, 1, 0.72), 2.0)


func _get_hidden_value(index: int) -> float:
	var values = inputs.values()
	if values.size() == 0:
		return 0.0
	var total = 0.0
	for i in range(values.size()):
		total += float(values[i]) * (0.22 + 0.12 * ((i + index) % 4))
	return clamp(total / values.size() * 2.2, 0.0, 1.0)
