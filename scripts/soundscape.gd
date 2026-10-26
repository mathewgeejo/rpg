extends Node

var enabled = true
var ambience: AudioStreamPlayer
var interval = 0.0
var step = 0
var voices: Array = []
const SCALE = [130.81,196.0,261.63,293.66,329.63,392.0,523.25,392.0]

func _ready() -> void:
	# Quiet, synthesized original ambient score. No external audio service.
	for i in 8:
		var voice = AudioStreamPlayer.new()
		voice.volume_db = -16
		add_child(voice)
		voices.append(voice)

func _process(delta: float) -> void:
	if not enabled: return
	interval -= delta
	if interval <= 0:
		interval = 1.6
		note(SCALE[step%SCALE.size()],2.3,.045)
		step += 1

func note(frequency: float, duration: float = .2, volume: float = .1) -> void:
	if not enabled or voices.is_empty(): return
	var voice: AudioStreamPlayer = voices[step%voices.size()]
	for available in voices:
		if not available.playing:
			voice = available
			break
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var bytes = PackedByteArray()
	var count = int(22050*duration)
	bytes.resize(count*2)
	for i in count:
		var t = i/22050.0
		var envelope = minf(t*12,1.0)*pow(1.0-i/float(count),2.0)
		var wave = sin(TAU*frequency*t)*.7+sin(TAU*frequency*2*t)*.2+sin(TAU*frequency*.5*t)*.1
		bytes.encode_s16(i*2,int(wave*envelope*volume*32760))
	stream.data = bytes
	voice.stream = stream
	voice.play()
