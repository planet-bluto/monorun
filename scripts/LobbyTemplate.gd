extends Control

var lobby = null

func _process(delta):
	if (lobby != null):
		$Title.text = lobby.title
