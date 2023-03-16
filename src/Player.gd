extends KinematicBody2D
signal grassMove

const battleScene = preload("res://Scenes/Battle.tscn")
const PLAYER_SPEED = 300

var isInGrass = false
var movement = Vector2.ZERO

func _ready() -> void:
	if $GrassColission.connect("body_entered", self, "_grassStep") != OK: push_error("Collision not connected")
	if $GrassColission.connect("body_exited", self, "_grassExit") != OK: push_error("Collision not connected")
	if connect("grassMove", self, "_grassStep") != OK: push_error("Collision not connected")
	
func _process(_delta) -> void:
	movement = Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	if movement != Vector2.ZERO:
		if (isInGrass): emit_signal("grassMove", isInGrass)
	
	movement = move_and_slide(movement*PLAYER_SPEED)
	
func _grassStep(grassID) -> void: 
	if grassID.name == "Walls": return
	
	randomize()
	if randi() % 30 == 0:
		startBattle()
		
	isInGrass = grassID
func _grassExit(_grassID) -> void: isInGrass = false

func _battleExited(battle) -> void:
	set_process(true)
	get_parent().get_node("BGM").play()
	battle.queue_free()
	show()

func startBattle() -> void:
	hide()
	get_parent().get_node("BGM").stop()
	set_process(false)
	var battle = battleScene.instance()
	battle.connect("battleEnded", self, "_battleExited")
	battle.enemyPokemon = Pokemon.createPokemon(randi() % 3, randi() % 5 + 1)
	get_tree().get_root().add_child(battle)
