extends Node

func deleteAfterUse(node : Node): node.queue_free()

func doTransform(node : Node2D, options : Dictionary):
	var spriteOGposition = node.position
	var spriteOGrotation = node.rotation_degrees
	var transformation = Tween.new()
	
	add_child(transformation)
	transformation.connect("tween_all_completed", self, "deleteAfterUse", [transformation])
	
	transformation.interpolate_property(node, "scale", null, Vector2(options.XScaleOffset, options.YScaleOffset), options.Duration, Tween.TRANS_BACK)
	transformation.interpolate_property(node, "position", null, Vector2(options.XPosOffset, options.YPosOffset), options.Duration, Tween.TRANS_BACK)
	transformation.interpolate_property(node, "rotation_degrees", null, options.Rotation, options.Duration, Tween.TRANS_BACK)
	transformation.start()
	
	if options.Reverse:
		yield(transformation, "tween_completed")
		transformation.interpolate_property(node, "scale", null, Vector2(1,1), options.Duration, Tween.TRANS_BACK)
		transformation.interpolate_property(node, "position", null, spriteOGposition, options.Duration, Tween.TRANS_BACK)
		transformation.interpolate_property(node, "rotation_degrees", null, spriteOGrotation, options.Duration, Tween.TRANS_BACK)
		transformation.start()

var shakeShaderInUse : bool = false
func doModulate(node: Node2D, options: Dictionary):
	var sprite = node.get_child(2)
	if !shakeShaderInUse:
		sprite.set_material(preload("res://Shaders/shakeShader.tres"))
		shakeShaderInUse = true
		
	var transformation = Tween.new()
	add_child(transformation)
	
	transformation.interpolate_property(sprite.get_material(), "shader_param/modulate", Color(0.5,0.5,0.5), options.SetCol, options.FadeIn)
	transformation.start()
	
	yield(transformation, "tween_completed")
	yield(get_tree().create_timer(options.Duration), "timeout")
	
	transformation.interpolate_property(sprite.get_material(), "shader_param/modulate", options.SetCol, Color(0.5,0.5,0.5), options.FadeOut)
	transformation.start()
	
	yield(transformation, "tween_completed")
	transformation.queue_free()
	shakeShaderInUse = false
	sprite.set_material(node.breathingShader)
	
func doShake(node: Node2D, options: Dictionary):
	var sprite : Sprite = node.get_child(2)
	if !shakeShaderInUse:
		sprite.set_material(preload("res://Shaders/shakeShader.tres"))
		shakeShaderInUse = true
		
	if options.ShakeY: sprite.get_material().set_shader_param("allowY", true)
	sprite.get_material().set_shader_param("speed", options.Speed)
	
	var shake = Tween.new()
	add_child(shake)
	
	shake.interpolate_property(sprite.get_material(), "shader_param/intensity", 0.0, float(options.Intensity), options.Duration/10)
	shake.start()
	
	yield(shake, "tween_completed")
	yield(get_tree().create_timer(options.Duration-2*options.Duration/10), "timeout")
	
	shake.interpolate_property(sprite.get_material(), "shader_param/intensity", float(options.Intensity), 0.0, options.Duration/10)
	shake.start()
	
	yield(shake, "tween_completed")
	shake.queue_free()
	shakeShaderInUse = false
	sprite.set_material(node.breathingShader)
	
func doParticles(playerSprite : Node2D, options: Dictionary):
	var node = CPUParticles2D.new()
	node.one_shot = true
	node.direction = Vector2(sin(deg2rad(options.Angle)), cos(deg2rad(options.Angle)))
	node.initial_velocity = options.Speed
	node.gravity = Vector2.ZERO
	node.texture = load("res://Images/particles/%s.png" % [options.Shape])
	
	var colors = Gradient.new()
	var totalTime = options.InTime + options.Duration + options.OutTime
	colors.set_color(0, Color.transparent)
	colors.remove_point(1)
	colors.add_point(options.InTime/totalTime, options.FromCol)
	colors.add_point((options.InTime + options.Duration)/totalTime, options.ToCol)
	colors.add_point(1, Color.transparent)
	node.color_ramp = colors
	
	var scaleCurve = Curve.new()
	scaleCurve.add_point(Vector2(0, options.FromScale))
	scaleCurve.add_point(Vector2(1, options.ToScale))
	node.scale_amount_curve = scaleCurve
	
	var mouthPosData = Pokemon.pkData[playerSprite.pokemon.id]["mp_back" if playerSprite.backside else "mp_front"]
	if options.PMP or options.EMP: node.position = Vector2(mouthPosData[0], mouthPosData[1])
	else: node.position = Vector2(options.XPosOffset, options.YPosOffset)
	node.z_index = 5 if options.InFrontOf else 1
	node.amount = options.Count
	node.spread = options.Spread
	node.lifetime = options.Duration
	
	add_child(node)
	node.emitting = true
	yield(get_tree().create_timer(options.InTime + options.Duration + options.OutTime), "timeout")
	node.queue_free()

signal attack_finished
func playAttacks(sprites : Array, timeline : Array):
	for mod in timeline:
		match mod.type:
			"Wait": yield(get_tree().create_timer(mod.controls.Duration), "timeout")
			"Shake": doShake(sprites[int(mod.controls.Enemy)], mod.controls)
			"Modulate": doModulate(sprites[int(mod.controls.Enemy)], mod.controls)
			"Transform": doTransform(sprites[int(mod.controls.Enemy)], mod.controls)
			"Particles": doParticles(sprites[int(mod.controls.EMP)], mod.controls)
	emit_signal("attack_finished")
