@tool
extends Node2D

@export_file_path("*.xml") var xml_path
@export_tool_button("Import Animations") var import_anim = import_all_anims

@onready var sprite := $Sprite2D
@onready var anim_player := $AnimationPlayer

func import_all_anims():
	var anims := parse_anim_xml(xml_path)
	
	var anim_lib = anim_player.get_animation_library("")
	
	for anim_data in anims:
		var tex_path = texture_path_from_anim_name(xml_path, anim_data.name)
		print("Cargando:", tex_path)

		var texture := load(tex_path)
		if texture == null:
			push_error("No se encontró la textura: " + tex_path)
			continue
		setup_sprite(sprite, anim_data, texture)
		build_animation(anim_player, anim_lib, sprite, anim_data, texture)

func parse_anim_xml(path: String) -> Array:
	var parser := XMLParser.new()
	parser.open(path)

	var anims := []
	var current := {}
	var durations := []

	while parser.read() == OK:
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				match parser.get_node_name():
					"Anim":
						current = {
							"name": "",
							"frame_width": 0,
							"frame_height": 0,
							"durations": [],
							"hit_frame": -1,
							"return_frame": -1
						}
						durations = []

					"Name":
						parser.read()
						current.name = parser.get_node_data()

					"FrameWidth":
						parser.read()
						current.frame_width = int(parser.get_node_data())

					"FrameHeight":
						parser.read()
						current.frame_height = int(parser.get_node_data())

					"HitFrame":
						parser.read()
						current.hit_frame = int(parser.get_node_data())

					"ReturnFrame":
						parser.read()
						current.return_frame = int(parser.get_node_data())

					"Duration":
						parser.read()
						durations.append(int(parser.get_node_data()))

			XMLParser.NODE_ELEMENT_END:
				if parser.get_node_name() == "Anim":
					current.durations = durations.duplicate()
					anims.append(current)

	return anims

func texture_path_from_anim_name(xml_path: String, anim_name: String) -> String:
	var dir := xml_path.get_base_dir()
	return "%s/%s-Anim.png" % [dir, anim_name]

func build_animation(
	player: AnimationPlayer, anim_lib : AnimationLibrary,
	sprite: Sprite2D,
	anim_data: Dictionary,
	texture: Texture2D
) -> void:

	var anim := Animation.new()
	anim.loop_mode = Animation.LOOP_LINEAR

	var tex_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tex_track, "%s:texture" % sprite.get_path())
	anim.track_insert_key(tex_track, 0.0, texture)

	var cols = texture.get_width() / anim_data.frame_width
	var rows = texture.get_height() / anim_data.frame_height

	var hframes_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(hframes_track, "%s:hframes" % sprite.get_path())
	anim.track_insert_key(hframes_track, 0.0, cols)

	var vframes_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(vframes_track, "%s:vframes" % sprite.get_path())
	anim.track_insert_key(vframes_track, 0.0, rows)

	var frame_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(frame_track, "%s:frame" % sprite.get_path())

	var time := 0.0
	for i in anim_data.durations.size():
		anim.track_insert_key(frame_track, time, i)
		time += anim_data.durations[i] / 60.0

	anim.length = time
	anim_lib.add_animation(anim_data.name, anim)


func time_at_frame(anim_data: Dictionary, frame: int) -> float:
	var t := 0.0
	for i in range(frame):
		t += anim_data.durations[i] / 60.0
	return t

func setup_sprite(sprite: Sprite2D, anim_data: Dictionary, texture: Texture2D):
	sprite.texture = texture
	sprite.hframes = anim_data.durations.size()
	sprite.vframes = 1
	sprite.frame = 0
