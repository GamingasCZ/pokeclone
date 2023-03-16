shader_type canvas_item;

uniform float breathe_speed : hint_range(1.0, 10.0, 0.1);
uniform float stretch_factor : hint_range(10.0, 30.0, 0.1);
uniform float offset;

void vertex() {
	VERTEX.y /= 1.0-sin(TIME*breathe_speed+offset)/stretch_factor;
}