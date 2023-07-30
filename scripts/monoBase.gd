extends Node

const TABLE = {
	"0":0, 
	"1":1, 
	"2":2, 
	"3":3, 
	"4":4, 
	"5":5, 
	"6":6, 
	"7":7, 
	"8":8, 
	"9":9, 
	"a":10, 
	"b":11, 
	"c":12, 
	"d":13, 
	"e":14, 
	"f":15, 
	"g":16, 
	"h":17, 
	"i":18, 
	"j":19, 
	"k":20, 
	"l":21, 
	"m":22, 
	"n":23, 
	"o":24, 
	"p":25, 
	"q":26, 
	"r":27, 
	"s":28, 
	"t":29, 
	"u":30, 
	"v":31, 
	"w":32, 
	"x":33, 
	"y":34, 
	"z":35, 
	"A":36, 
	"B":37, 
	"C":38, 
	"D":39, 
	"E":40, 
	"F":41, 
	"G":42, 
	"H":43, 
	"I":44, 
	"J":45, 
	"K":46, 
	"L":47, 
	"M":48, 
	"N":49, 
	"O":50, 
	"P":51, 
	"Q":52, 
	"R":53, 
	"S":54, 
	"T":55, 
	"U":56, 
	"V":57, 
	"W":58, 
	"X":59, 
	"Y":60, 
	"Z":61, 
	"*":62, 
	"/":63, 
	"+":64, 
	"-":65, 
	"!":66, 
	"@":67, 
	"&":68, 
}

var TABLEflip = {}

func _ready():
	for k in TABLE:
		TABLEflip[TABLE[k]] = k

func toDec(enc):
	var stringSize = enc.length()
	var iter = stringSize - 1
	var sum = 0
	for c in enc:
		var num = TABLE[c]
		sum += num * (pow(69, iter))
		iter -= 1
	return int(sum)

func _cut(state, base):
	var mod = int(fmod(state, base))
	state = int(floor(state / base))
	return [state, TABLEflip[mod]]

func toHex(enc):
	var dec = toDec(enc)
	var state = dec
	var rems = ["#", "0", "0", "0", "0", "0", "0"]
	var iter = 6
	var res = _cut(state, 16)
	state = res[0]
	rems[iter] = res[1]
	iter -= 1
	while (state > 0):
		res = _cut(state, 16)
		state = res[0]
		rems[iter] = res[1]
		iter -= 1
	return PoolStringArray(rems).join("")

func fromHex(hex):
	if (hex[0] == "#"):
		hex = hex.substr(1)
	var stringSize = hex.length()
	var iter = stringSize - 1
	var sum = 0
	for c in hex:
		var num = TABLE[c]
		sum += num * (pow(16, iter))
		iter -= 1
	return fromDec(int(sum))

func fromDec(dec):
	var state = dec
	var rems = []
	var res = _cut(state, 69)
	state = res[0]
	rems.push_front(res[1])
	while (state > 0):
		res = _cut(state, 69)
		state = res[0]
		rems.push_front(res[1])
	return PoolStringArray(rems).join("")
