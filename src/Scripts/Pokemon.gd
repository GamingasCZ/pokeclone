extends Node

var pkData
var moveData
var effectivenessData
func _init() -> void:
	var file = File.new()
	if file.open("res://Data/Pokemon.json", File.READ) == OK:
		pkData = JSON.parse(file.get_as_text()).result
		file.close()
		
	if file.open("res://Data/Moves.json", File.READ) == OK:
		moveData = JSON.parse(file.get_as_text()).result
		file.close()
		
	if file.open("res://Data/Types.json", File.READ) == OK:
		effectivenessData = JSON.parse(file.get_as_text()).result
		file.close()

func createPokemon(pk_id : int, level : int) -> Node:
	var pkScene = preload("res://Scenes/Pokemon.tscn")
	var pokemon = pkScene.instance()
	
	# todo: CHANGE THIS
	for i in pkData[pk_id]["availableMoves"]:
		pokemon.moves.append(createMove(i))
	
	pokemon.level = level
	
	# values can be found in res://Scripts/pkScene.gd
	pokemon.name = pkData[pk_id]["name"]
	pokemon.hp = floor(0.01 * (2 * pkData[pk_id]["hp"] + 1 + floor(0.25 * 1)) * pokemon.level) + pokemon.level + 10
	pokemon.maxHP = pokemon.hp
	pokemon.attack = floor(0.01 * (2 * pkData[pk_id]["attack"] + 1 + floor(0.25 * 1)) * pokemon.level) + 5
	pokemon.defense = floor(0.01 * (2 * pkData[pk_id]["defense"] + 1 + floor(0.25 * 1)) * pokemon.level) + 5
	pokemon.speed = floor(0.01 * (2 * pkData[pk_id]["speed"] + 1 + floor(0.25 * 1)) * pokemon.level) + 5
	pokemon.id = pkData[pk_id]["id"]
	pokemon.type = pkData[pk_id]["type"]
	pokemon.xp = 15*level
	pokemon.levelup += 15*(level+1)
	

	pokemon.defendMultiplier = effectivenessData["%s" % pokemon.type[0]]["offense"]
	pokemon.attackMultiplier = effectivenessData["%s" % pokemon.type[0]]["defense"]
	if len(pokemon.type) > 1:
		for i in range(len(pokemon.defendMultiplier)):
			pokemon.defendMultiplier[i] *= effectivenessData["%s" % pokemon.type[1]]["offense"][i]
			pokemon.attackMultiplier[i] *= effectivenessData["%s" % pokemon.type[1]]["defense"][i]
	
	return pokemon

func createMove(m_id) -> Node:
	var moveScene = preload("res://Scenes/Move.tscn")
	var move = moveScene.instance()
	
	move.name = moveData[m_id]["name"]
	move.power = moveData[m_id]["power"]
	move.accuracy = moveData[m_id]["accuracy"]
	move.type = moveData[m_id]["type"]
	move.pp = moveData[m_id]["pp"]
	
	return move

func levelUp(pokemon) -> void:
	pokemon.level += 1
	
	var newMAXhp = floor(0.01 * (2 * pkData[pokemon.id]["hp"] + 1 + floor(0.25 * 1)) * pokemon.level) + pokemon.level + 10
	pokemon.hp += newMAXhp-pokemon.maxHP
	pokemon.maxHP = newMAXhp
	pokemon.attack = floor(0.01 * (2 * pkData[pokemon.id]["attack"] + 1 + floor(0.25 * 1)) * pokemon.level) + 5
	pokemon.defense = floor(0.01 * (2 * pkData[pokemon.id]["defense"] + 1 + floor(0.25 * 1)) * pokemon.level) + 5
	pokemon.speed = floor(0.01 * (2 * pkData[pokemon.id]["speed"] + 1 + floor(0.25 * 1)) * pokemon.level) + 5
	pokemon.levelup += 15*(pokemon.level-1)
