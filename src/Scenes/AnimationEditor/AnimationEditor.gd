extends Control

var battleScene = load("res://Scenes/Battle.tscn").instance()
var dialogAddButtons : Array
var file = File.new()

func modButtons(disabled : bool):
	for but in dialogAddButtons: but.disabled = disabled
	for but in get_node("%TimelineContainer").get_children(): but.disabled = disabled

func _ready():
	dialogAddButtons = $AnimationMods.get_children()
	dialogAddButtons.resize(5)
	modButtons(true)
	
	setupBattleScene()
	
	get_node("%PlayerPokemonID").max_value = len(Pokemon.pkData)
	get_node("%EnemyPokemonID").max_value = len(Pokemon.pkData)
	
	for but in dialogAddButtons:
		but.connect("pressed", self, "_add_Animation", [but.name])
	
	set_process_input(false)
	
func openMoveSelector(isSaveAs = false):
	$Node2D/MoveSelector/Panel/HBoxContainer/VBoxContainer/MoveSelectorTitle.text = "Load"
	setupMoveSelector()
	$Node2D/MoveSelector.popup()

var bubble = preload("res://Scenes/AnimationEditor/MoveBubble.tscn")
func setupMoveSelector():
	var loadOptions = $Node2D/MoveSelector/Panel/HBoxContainer/ScrollContainer/VBoxContainer.get_children()
	if len(loadOptions) == 0:
		$PokemonSettings/Panel3/HBoxContainer/Save.disabled = true
		$Node2D/MoveSelector/Panel/HBoxContainer/VBoxContainer/Button.connect("pressed", $Node2D/MoveSelector, "hide")
	else:
		for move in loadOptions: move.queue_free()
	
	var i = 0
	for move in Pokemon.moveData:
		var inst = bubble.instance()
		inst.get_node("MoveName").text = move.name
		
		var fileExists = file.file_exists("res://Data/CustomAnimations/%sFront.dat" % [move.name])
		if fileExists: inst.get_node("Front").modulate = Color.greenyellow
		else: inst.get_node("Front").modulate = Color.crimson
		inst.get_node("Front").connect("pressed", self, "selectMove", [i, move.name, true, fileExists])
			
		fileExists = file.file_exists("res://Data/CustomAnimations/%sBack.dat" % [move.name])
		if file.file_exists("res://Data/CustomAnimations/%sBack.dat" % [move.name]): inst.get_node("Back").modulate = Color.greenyellow
		else: inst.get_node("Back").modulate = Color.crimson
		inst.get_node("Back").connect("pressed", self, "selectMove", [i, move.name, false, fileExists])
			
		$Node2D/MoveSelector/Panel/HBoxContainer/ScrollContainer/VBoxContainer.add_child(inst)
		i += 1

var loadedMove : Array
func selectMove(moveID : int, moveName : String, front : bool, fileExists : bool):
	modButtons(false)
	loadedMove = [moveID, front]
	$Node2D/MoveSelector.hide()
	loadAnimation(moveID, front, fileExists)
	$PokemonSettings/Panel3/HBoxContainer/Save.disabled = false
	$PokemonSettings/Panel3/HBoxContainer/SaveAs.disabled = false
	$moveOpen.text = "Editing: %s - %s" % [moveName, "Enemy" if front else "Player"]

func _PlayerPokemonID_change(value):
	battleScene.drawPokemon(true, Pokemon.createPokemon(value-1, 1))
	drawnPokemon = battleScene.battleSprites


func _EnemyPokemonID_change(value):
	battleScene.drawPokemon(false, Pokemon.createPokemon(value-1, 1))
	drawnPokemon = battleScene.battleSprites

var drawnPokemon : Array = []
func setupBattleScene():
	battleScene.get_node("BattleFooter").hide()
	battleScene.get_node("PlayerHPBar").hide()
	battleScene.get_node("EnemyHPBar").hide()
	
	$BattleContainer.add_child(battleScene)
	
	battleScene.drawPokemon(true)
	battleScene.drawPokemon(false)
	drawnPokemon = battleScene.battleSprites

func _add_Animation(addDialogName : String):
	modButtons(true)
	var newPopup = $PopupParent.createPopup(addDialogName)
	newPopup.connect("animation_added", self, "addToTimeline")
	newPopup.connect("animation_cancelled", self, "modButtons", [false])

var popupEditing : PopupDialog
func _edit_Animation(settingsIndex : int):
	popupEditing = $PopupParent.createPopup(Game.AnimationTimeline[settingsIndex].name+"Dialog", true, settingsIndex)
	popupEditing.connect("popup_hide", popupEditing, "queue_free")
	popupEditing.connect("animation_edited", self, "timelineButtonUpdate")
	popupEditing.connect("animation_deleted", self, "timelineButtonDelete")

func addToTimeline(settingsIndex : int):
	var popupSett = Game.AnimationTimeline[settingsIndex]
	var timelineButton = Button.new()
	timelineButton.text = popupSett.name
	timelineButton.clip_text = true
	timelineButton.rect_min_size.x = modifyTimelineButtonDuration(popupSett.controls)
	timelineButton.connect("pressed", self, "_edit_Animation", [settingsIndex])
	
	get_node("%TimelineContainer").add_child(timelineButton)
	modButtons(false)

func timelineButtonUpdate(settingsIndex : int):
	modButtons(false)
	get_node("%TimelineContainer").get_children()[settingsIndex].rect_min_size.x = modifyTimelineButtonDuration(Game.AnimationTimeline[settingsIndex].controls)

func timelineButtonDelete(settingsIndex : int):
	get_node("%TimelineContainer").get_children()[settingsIndex].queue_free()
	yield(get_tree(), "idle_frame")
	
	var i = 0
	for but in get_node("%TimelineContainer").get_children():
		but.disconnect("pressed", self, "_edit_Animation")
		but.connect("pressed", self, "_edit_Animation", [i])
		i += 1
		
	modButtons(false)
	
var TIMELINE_ZOOM = 32
func changeZoom(zoomin : bool):
	TIMELINE_ZOOM = TIMELINE_ZOOM*2 if zoomin else TIMELINE_ZOOM/2
	for i in range(len(Game.AnimationTimeline)):
		timelineButtonUpdate(i)
	

func modifyTimelineButtonDuration(settingDictControls : Dictionary):
	# TODO: count other controls with seconds input (fadein out)
	return settingDictControls.Duration*TIMELINE_ZOOM
	
func playAnimation():
	modButtons(true)
	$AnimationDrawer.playAttacks(drawnPokemon, Game.AnimationTimeline)
	modButtons(false)

func saveAsAnimation():
	openMoveSelector(true)
	
	$Node2D/MoveSelector/Panel/HBoxContainer/VBoxContainer/MoveSelectorTitle.text = "Save As"

func saveAnimation():
	var filename = "%s%s" % [Pokemon.moveData[loadedMove[0]].name, "Front" if loadedMove[1] else "Back"]
	file.open("res://Data/CustomAnimations/%s.dat" % [filename], File.WRITE)
	file.store_var(Game.AnimationTimeline, true)
	file.close()

func loadAnimation(id : int, front : bool, fileExists : bool):
	Game.AnimationTimeline = []
	if !fileExists: return
	
	file.open("res://Data/CustomAnimations/%s%s.dat" % [Pokemon.moveData[id].name, "Front" if front else "Back"], File.READ)
	Game.AnimationTimeline = file.get_var()
	for i in get_node("%TimelineContainer").get_children(): i.queue_free()
	for i in range(len(Game.AnimationTimeline)):
		addToTimeline(i)
	file.close()

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			setMouthPos(get_viewport().get_mouse_position())

var mouthPosSettings : Array
func startMouthPosCapture(player : bool):
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	set_process_input(true)
	var pokemon
	if player: pokemon = $PokemonSettings/Panel/PlayerPokemonID.value
	else: pokemon = $PokemonSettings/Panel2/EnemyPokemonID.value
	
	mouthPosSettings = [player, pokemon]
	
func setMouthPos(pos : Vector2):
	set_process_input(false)
	Input.set_default_cursor_shape()
	file.open("res://Data/Pokemon.json", File.READ_WRITE)
	var data = JSON.parse(file.get_as_text()).result
	data[mouthPosSettings[1]-1]["mp_back" if mouthPosSettings[0] else "mp_front"] = [pos.x, pos.y]
	Pokemon.pkData = data
	file.store_string(JSON.print(data))
	file.close()
