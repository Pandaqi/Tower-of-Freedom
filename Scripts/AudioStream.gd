
extends StreamPlayer

var song_names = ["Alhambra.ogg", "If We Grow Old.ogg", "Salsa de Marzo.ogg", "Sullen Tower.ogg"]
var songs = [null, null, null, null]
var amount_songs = 4

func _ready():
	randomize()
	for i in range(amount_songs):
		songs[i] = load(str("res://Sound/", song_names[i]))
	set_stream(songs[round(randf()*amount_songs)-1])
	play()
	

func _on_StreamPlayer_finished():
	set_stream(songs[round(randf()*amount_songs)-1])
	play()
