extends Node2D


func _ready():
	$AnimEditor.connect("pressed", get_tree(), "change_scene_to", [preload("res://Scenes/AnimationEditor/AnimationEditor.tscn")])
