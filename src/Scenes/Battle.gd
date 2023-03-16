extends Control
signal battleEnded

const DEBUG_ENEMY_POKEMON : int = 0

var enemyPokemon : Node = Pokemon.createPokemon(DEBUG_ENEMY_POKEMON, 5)
var playerPokemon : Node = Game.PlayerPokemon[0]

var battleSprites : Array = [0,0]

var pokeBattle = preload("res://Scenes/BattlePokemon.tscn")
func drawPokemon(player : bool, pokemon : Node = Pokemon.createPokemon(DEBUG_ENEMY_POKEMON, 5)) -> void:
	for i in get_tree().get_nodes_in_group("battlePokemon"):
		if i.backside == player: i.queue_free() # pokemon with back sprite is always the player's one
	
	var pk = pokeBattle.instance()
	pk.backside = player
	pk.pokemon = pokemon
	var nodeSpec = ["Enemy", "Player"][int(player)]
	
	get_node("%sHPBar" % [nodeSpec]).setupBar(pk, !player)
	
	pk.position = get_node("Decoration/%sGround/%sPokemonHint" % [nodeSpec, nodeSpec]).global_position
	add_child(pk)
	battleSprites[int(!player)] = pk
	
	
func _ready() -> void:
	drawPokemon(true, playerPokemon)
	drawPokemon(false, enemyPokemon)
	$BattleFooter/BattleControls/FightButton.grab_focus()


signal attacked
var attack_result : Array
func doAttack(attack : Node, enemy : bool) -> void:
	$BattleFooter/FooterText.text = ""
	
	var attacker = playerPokemon if enemy else enemyPokemon 
	var defender = enemyPokemon if enemy else playerPokemon
	
	var MISS = !(randi() % 101 < attack.accuracy)
	var STAB = 1.5 if attack.type[0] in attacker.type else 1.0
	var CRIT = (2*attacker.level+5)/(attacker.level+5) if randi() % 255 < randi() % 255 else 1
	var EFFECTIVENESS = defender.attackMultiplier[attack.type[0]-1]
	
	# formula: https://wikimedia.org/api/rest_v1/media/math/render/svg/622aaeb4f4d7377ac7cd72d834de01f35ef68763
	# maybe add items
	var formula = (((2*attacker.level/5+2)*attack.power*attacker.attack/defender.defense)/50*CRIT+2)*STAB*EFFECTIVENESS
	if !MISS:
		battleSprites[int(enemy)].hurtFlash()
		modifyHP(defender, !enemy, -formula)
		yield(self, "hpBarModified")
	
	attack.pp -= 1
	emit_signal("attacked", MISS, CRIT, EFFECTIVENESS, attack)

var speed : int
func modifyHP(pk : Node, player : bool, setTo: int) -> void:
	var prevHP = pk.hp
	pk.hp += setTo
	pk.hp = clamp(pk.hp, 0, pk.maxHP)
	var bar = "PlayerHPBar" if player else "EnemyHPBar"
	
	speed = prevHP
	get_node(bar+"/anim").interpolate_property(get_node(bar+"/Controls/HPBar"), "value", prevHP, pk.hp, 0.2)
	get_node(bar+"/anim").interpolate_property(self, "speed", prevHP, pk.hp, 0.2)
	get_node(bar+"/anim").start()
	
	while get_node(bar+"/anim").is_active():
		get_node(bar+"/Controls/HPText").text = "%s/%s" % [speed, pk.maxHP]
		if speed == pk.hp: break
		
		yield(get_node(bar+"/anim"), "tween_step")
		
	emit_signal("hpBarModified")
	
	if enemyPokemon.hp <= 0: enemyDefeated()
	elif playerPokemon.hp <= 0: selfDefeated()

signal hpBarModified
signal animated
signal done
func animateText(theText) -> void:
	get_node("%FooterText").percent_visible = 0.0
	get_node("%FooterText").text = theText
	$BattleFooter/TextScroll.interpolate_property(get_node("%FooterText"), "percent_visible", 0.0, 1.0, 0.5)
	$BattleFooter/TextScroll.start()
	
	yield($BattleFooter/TextScroll, "tween_completed")
	yield(get_tree().create_timer(0.4), "timeout")
	emit_signal("animated")
	
func battleText(fighter : Node, hitResult : Array, attack_args : Array) -> void:
	animateText("%s used %s!" % [fighter.name, hitResult[3].name])
	yield(self, "animated")
	
	callv("doAttack", attack_args)
	hitResult = yield(self, "attacked")
	
	if !hitResult[0]: # miss
		if hitResult[2] == 0.5:
			animateText("It was not very effective!"); yield(self, "animated");
		elif hitResult[2] == 2:
			animateText("It was super effective!"); yield(self, "animated");
		if hitResult[1] != 1:
			animateText("Critical hit!"); yield(self, "animated");
	else:
		animateText("The attack missed!")
		yield(self, "animated")
	emit_signal("done")
	

func _on_FightButton_pressed() -> void:
	$Click.play()
	$BattleFooter/BattleControls.hide()
	var moveButtons = $BattleFooter/FightMoves.get_children()
	for i in range(len(playerPokemon.moves)):
		if moveButtons[i].is_connected("pressed", self, "performAttack"):
			moveButtons[i].disconnect("pressed", self, "performAttack")
		
		moveButtons[i].disabled = false
		moveButtons[i].text = ""
		
		var butLabel = moveButtons[i].get_children()
		var label = Label.new() if !bool(len(butLabel)) else butLabel[0]
		
		label.valign = Label.VALIGN_CENTER; label.align = Label.ALIGN_CENTER;
		label.rect_size = moveButtons[i].rect_size
		label.text = playerPokemon.moves[i].name+"\nPP: %s" % [playerPokemon.moves[i].pp]
		if !bool(len(butLabel)): moveButtons[i].add_child(label)
		
		moveButtons[i].connect("pressed", self, "performAttack", [playerPokemon.moves[i], label])
	$BattleFooter/FightMoves.show()
	$BattleFooter/FightMoves/Move1.grab_focus()
		
func performAttack(attack : Node, label : Label, skipAttack : bool = false) -> void:
	$Click.play()
	$BattleFooter/FightMoves.hide()
	$BattleFooter/BattleControls.show()
	label.set_text("%s\nPP: %s"  % [attack.name, attack.pp-1])
	
	for i in $BattleFooter/BattleControls.get_children(): i.disabled = true
	
	var first; var second;
	if playerPokemon.speed > enemyPokemon.speed or skipAttack:
		first = playerPokemon
		second = enemyPokemon
	elif playerPokemon.speed == enemyPokemon.speed:
		var rand = [playerPokemon, enemyPokemon]
		rand.shuffle()
		
		first = rand[0]
		second = rand[1]
	else:
		first = enemyPokemon
		second = playerPokemon
	
	randomize()
	
	var firstAttack = attack if first == playerPokemon else AImoveChoose(enemyPokemon, playerPokemon)
	var secondAttack = attack if first != playerPokemon else AImoveChoose(enemyPokemon, playerPokemon)
	
	if !skipAttack:
		battleText(first, [0,0,0,firstAttack], [firstAttack, first == playerPokemon])
		yield(self, "done")

	if second.hp > 0:
		battleText(second, [0,0,0,secondAttack], [secondAttack, second == playerPokemon])
		yield(self, "done")
		
		get_node("%FooterText").text = "Choose idot"
		for i in $BattleFooter/BattleControls.get_children(): i.disabled = false
	$BattleFooter/BattleControls/FightButton.grab_focus()

func _on_RunButton_pressed() -> void:
	$Click.play()
	leaveBattle()

func selfDefeated() -> void:
	battleSprites[0].defeatAnimation()
	
	animateText("You lost lmao!")
	yield(self, "animated")
	
	playerPokemon.hp = playerPokemon.maxHP
	
	leaveBattle()

func enemyDefeated() -> void:
	playerPokemon.xp += 10*enemyPokemon.level
	battleSprites[1].defeatAnimation()
	
	animateText("You won! You gained %sEXP!" % [10*enemyPokemon.level])
	yield(self, "animated")
	
	if playerPokemon.xp > playerPokemon.levelup:
		Pokemon.levelUp(playerPokemon)
		animateText("%s levelled up to level %s!" % [playerPokemon.name, playerPokemon.level])
		yield(self, "animated")
		
	leaveBattle()
	
func leaveBattle() -> void:
	$BattleFooter/TextScroll.interpolate_property($BGM, "volume_db", null, -20, 0.5)
	$BattleFooter/TextScroll.interpolate_property(self, "modulate", null, Color.black, 0.5)
	$BattleFooter/TextScroll.start()
	yield($BattleFooter/TextScroll, "tween_all_completed")
	
	$BGM.stop()
	
	$BattleFooter/TextScroll.interpolate_property(self, "modulate", null, Color(0,0,0,0), 0.1)
	$BattleFooter/TextScroll.start()
	yield($BattleFooter/TextScroll, "tween_all_completed")
	
	emit_signal("battleEnded", self)
	
func switchPokemon(pk_index : int, player : bool) -> void:
	$PokemonSwitcher.hide()
	if player: $Click.play()
	
	playerPokemon = Game.PlayerPokemon[pk_index]
	drawPokemon(player, playerPokemon)
	
	performAttack(Game.PlayerPokemon[pk_index].moves[0], Label.new(), true)

func AImoveChoose(player: Node, _enemy: Node) -> Node:
	#add ai later :)
	return player.moves[randi() % len(player.moves)]

func _on_PokemonButton_pressed() -> void:
	$Click.play()
	
	var switchButtons = $PokemonSwitcher/SwitcherBG/SwitchContainer.get_children()
	for pk in range(len(Game.PlayerPokemon)):
		var currPokemon = Game.PlayerPokemon[pk]
		
		switchButtons[pk].icon = load("res://Images/pokemon/icons/%s.png" % [currPokemon.id])
		switchButtons[pk].text = "%s Lv.%s - HP: %s" % [currPokemon.name, currPokemon.level, currPokemon.hp]
		switchButtons[pk].disabled = false
		
		if switchButtons[pk].is_connected("pressed", self, "switchPokemon"):
			switchButtons[pk].disconnect("pressed", self, "switchPokemon")
			
		switchButtons[pk].connect("pressed", self, "switchPokemon", [pk, true])
	
	$PokemonSwitcher.popup()
	
