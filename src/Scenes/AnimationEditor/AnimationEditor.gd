extends Control

var battleScene = load("res://Scenes/Battle.tscn").instance()
var dialogAddButtons : Array

func modButtons(disabled : bool):
	for but in dialogAddButtons: but.disabled = disabled
	for but in get_node("%TimelineContainer").get_children(): but.disabled = disabled

func _ready():
	dialogAddButtons = $AnimationMods.get_children()
	dialogAddButtons.resize(5)
	
	setupBattleScene()
	
	get_node("%PlayerPokemonID").max_value = len(Pokemon.pkData)
	get_node("%EnemyPokemonID").max_value = len(Pokemon.pkData)
	
	for but in dialogAddButtons:
		but.connect("pressed", self, "_add_Animation", [but.name])


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
	for mod in Game.AnimationTimeline:
		match mod.type:
			"Wait": yield(get_tree().create_timer(mod.controls.Duration), "timeout")
			"Shake": $AnimationDrawer.doShake(drawnPokemon[int(mod.controls.Enemy)], mod.controls)
			"Modulate": $AnimationDrawer.doModulate(drawnPokemon[int(mod.controls.Enemy)], mod.controls)
			"Transform":
				$AnimationDrawer.doTransform(drawnPokemon[int(mod.controls.Enemy)], mod.controls)
			"Particles": $AnimationDrawer.doParticles($CPUParticles2D, mod.controls)
	modButtons(false)

func saveAnimation():
	var file = File.new()
	file.open("res://Data/CustomAnimations/Animation.json", File.WRITE)
	file.store_var(Game.AnimationTimeline, true)
	file.close()

func loadAnimation():
	var file = File.new()
	file.open("res://Data/CustomAnimations/Animation.json", File.READ)
	Game.AnimationTimeline = file.get_var()
	for i in get_node("%TimelineContainer").get_children(): i.queue_free()
	for i in range(len(Game.AnimationTimeline)):
		addToTimeline(i)
	file.close()
