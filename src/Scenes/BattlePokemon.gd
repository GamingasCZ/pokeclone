extends Node2D

var pokemon : Node
var backside : bool

const scaleAm = 1.5

func _ready() -> void:
	var breathe_spd = 1 + randf()*2
	var breathe_offset = randf() * 20
	for i in range(2):
		var pokeSprite = Sprite.new()
		pokeSprite.texture = load("res://Images/pokemon/%s_%s.png" % [pokemon.id, ["front", "back"][int(backside)]])
		pokeSprite.material = ShaderMaterial.new()
		pokeSprite.material.shader = preload("res://Shaders/Breathing.gdshader")
		
		pokeSprite.material.set_shader_param("breathe_speed", breathe_spd)
		pokeSprite.material.set_shader_param("offset", breathe_offset)
		pokeSprite.material.set_shader_param("stretch_factor", 30.0)
		
		pokeSprite.offset.y = -128
		pokeSprite.z_index = 2+int(backside)
		pokeSprite.scale = Vector2(1.0+float(backside)/scaleAm, 1.0+float(backside)/scaleAm)
		if i == 1:
			pokeSprite.z_index = 1+int(backside)
			pokeSprite.position = Vector2(-40, -40)
			pokeSprite.rotation_degrees = 90
			pokeSprite.scale.x = 0.3+float(backside)/scaleAm
			pokeSprite.modulate = Color(0, 0, 0, 0.3)
			
		
		add_child(pokeSprite)

func hurtFlash() -> void:
	$Hit.play()
	for _i in range(2):
		$Hurt.interpolate_property(self, "modulate", null, Color.transparent, 0.05)
		$Hurt.start()
		yield($Hurt, "tween_completed")
		$Hurt.interpolate_property(self, "modulate", null, Color.white, 0.05)
		$Hurt.start()
		yield($Hurt, "tween_completed")

func defeatAnimation() -> void:
	$Hurt.interpolate_property(self, "position", null, position+Vector2(0, 64), 0.2)
	$Hurt.interpolate_property(self, "modulate", null, Color(0,0,0,0), 0.2)
	$Hurt.start()
