extends Node

enum GameState {
	NONE,
	INTRO,
	MENU,
	MAIN
}

var current_state: GameState = GameState.NONE
var current_scene: Node2D = null

func _ready():
	var root: Window = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

	if current_scene.name == "Main":
		current_state = GameState.MAIN