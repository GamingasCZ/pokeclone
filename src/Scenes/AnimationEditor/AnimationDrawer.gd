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
		
func doModulate(node: Node2D, options: Dictionary):
	var sprite = node.get_child(2)
	var prevMaterial = sprite.material
	sprite.set_material(preload("res://Shaders/modulationShader.tres"))
	var transformation = Tween.new()
	add_child(transformation)
	
	transformation.interpolate_property(sprite.get_material(), "shader_param/modulate", null, options.SetCol, options.FadeIn)
	transformation.start()
	
	yield(transformation, "tween_completed")
	yield(get_tree().create_timer(options.Duration), "timeout")
	
	transformation.interpolate_property(sprite.get_material(), "shader_param/modulate", null, Color(0.5,0.5,0.5), options.FadeOut)
	transformation.start()
	
	yield(transformation, "tween_completed")
	transformation.queue_free()
	sprite.material = prevMaterial
	
func doShake(node: Node2D, options: Dictionary):
	var spriteOGPos = node.position
	var shake = Tween.new()
	add_child(shake)
	
	var speed = 0.2/options.Speed
	var intensity = options.Intensity
	shake.interpolate_property(node, "position", null, spriteOGPos+Vector2(intensity/2,0), speed/2)
	shake.start()
	yield(shake, "tween_completed")
	
	print(floor(options.Duration-speed-2*speed)) # FIX!!
	for i in range(ceil(options.Duration-speed-2*speed)):
		shake.interpolate_property(node, "position", spriteOGPos+Vector2(intensity/2,0), node.position-Vector2(intensity, 0), speed)
		shake.start()
		yield(shake, "tween_completed")
		
		shake.interpolate_property(node, "position", null, node.position+Vector2(intensity, 0), speed)
		shake.start()
		yield(shake, "tween_completed")
		
	shake.interpolate_property(node, "position", null, spriteOGPos, speed/2)
	shake.start()
	yield(shake, "tween_completed")
		
	shake.queue_free()

	
func doParticles(node: CPUParticles2D, options: Dictionary):
	node.one_shot = true
	node.linear_accel
	
	node.position = Vector2(options.XPos, options.YPos)
	node.amount = options.Count
	node.spread = options.Spread
