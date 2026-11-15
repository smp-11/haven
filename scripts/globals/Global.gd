extends Node

var player_dashing = false

func player_dashing_f(val):
	player_dashing = val

var star1 = false
var star2 = false
var star3 = false
var star4 = false
var star5 = false
var star6 = false
var star7 = false
var star8 = false
var star9 = false

var level1_f = false
var level2_f = false
var level3_f = false

func collect_star(val):
	match val:
		1:
			star1 = true
		2: 
			star2 = true
		3:
			star3 = true
		4:
			star4 = true
		5:
			star5 = true
		6:
			star6 = true
func finish_level(val):
	match val:
		1:
			level1_f = true
		2:
			level2_f = true
		3:
			level3_f = true

			
