extends Panel

func setupBar(player : Node, hideXPBar : bool = false) -> void:
	$Controls/XPBar.max_value = abs(player.pokemon.levelup - player.pokemon.level*15)
	$Controls/XPBar.value = abs(player.pokemon.xp - player.pokemon.level*15)
	if hideXPBar:
		$Controls/XPBar.hide()
		$PokeballContainer.hide()
	else:
		
		var pokeBalls = $PokeballContainer.get_children()
		pokeBalls.invert()
		for i in range(6-len(Game.PlayerPokemon)):
			pokeBalls[i].hide()
			
	
	$Controls/HPBar.max_value = player.pokemon.maxHP
	$Controls/HPBar.value = player.pokemon.hp
	
	$Controls/HPText.text = "%s/%s" % [player.pokemon.hp, player.pokemon.maxHP]
	$Controls/Titles/PokemonName.text = player.pokemon.name
	$Controls/Titles/PokemonLevel.text = "Lv. %s" % [player.pokemon.level]
