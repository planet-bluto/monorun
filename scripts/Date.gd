extends Node

func now():
	return Time.get_unix_time_from_system() * 1000

func nowMono():
	return MonoBase.fromDec(now())
