class_name RangerLook
extends RefCounted
## Recolors the ranger's art for a profile's look (hair, skin, outfit). Colors come from
## data/ranger_looks.json. A look is {"hair": "brown", "skin": "light", "outfit": "green"};
## missing parts use the default.

const LOOKS_PATH: String = "res://data/ranger_looks.json"
const PARTS: Array[String] = ["hair", "skin", "outfit"]
const SHEET: Texture2D = preload("res://assets/sprites/ranger/sprite_sheet.png")
const FACESET: Texture2D = preload("res://assets/sprites/ranger/faceset.png")

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LOOKS_PATH))
		_data = parsed if parsed is Dictionary else {}
	return _data


## The option names for a part, in order ("red", "brown", ...).
static func options(part: String) -> Array[String]:
	var names: Array[String] = []
	for name: Variant in data()["options"][part]:
		names.append(str(name))
	return names


## The look with every part filled in (unknown or missing parts use the default).
static func complete(look: Dictionary) -> Dictionary:
	var full: Dictionary = (data()["default"] as Dictionary).duplicate()
	for part: String in PARTS:
		if look.has(part) and data()["options"][part].has(str(look[part])):
			full[part] = str(look[part])
	return full


## The main color of an option, for its swatch button.
static func swatch(part: String, option: String) -> Color:
	return _color(data()["options"][part][option][0])


static func sheet(look: Dictionary) -> Texture2D:
	return recolor(SHEET, look)


static func faceset(look: Dictionary) -> Texture2D:
	return recolor(FACESET, look)


## A copy of `texture` in the look's colors (the texture itself for the default look).
static func recolor(texture: Texture2D, look: Dictionary) -> Texture2D:
	var full: Dictionary = complete(look)
	if full == data()["default"]:
		return texture
	var base: Dictionary = data()["base"]
	var swap: Dictionary = {}  # rgba32 -> Color
	for part: String in ["hair", "outfit"]:
		var from: Array = base[part]
		var to: Array = data()["options"][part][full[part]]
		for i: int in from.size():
			swap[_color(from[i]).to_rgba32()] = _color(to[i])
	var skin_to: Array = data()["options"]["skin"][full["skin"]]
	var skin: int = _color(base["skin"][0]).to_rgba32()
	var skin_shadow: int = _color(base["skin"][1]).to_rgba32()
	swap[skin] = _color(skin_to[0])
	# get_image() can hand back the texture's own cached image, so never edit it in place.
	var image: Image = texture.get_image().duplicate()
	image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	var source: Image = image.duplicate()
	for y: int in image.get_height():
		for x: int in image.get_width():
			var pixel: Color = source.get_pixel(x, y)
			if pixel.a == 0.0:
				continue
			var key: int = pixel.to_rgba32()
			if key == skin_shadow and _touches(source, x, y, skin):
				image.set_pixel(x, y, _color(skin_to[1]))
			elif swap.has(key):
				image.set_pixel(x, y, swap[key])
	return ImageTexture.create_from_image(image)


## Does a pixel next to (x, y) (left, right, up, down) have this color?
static func _touches(image: Image, x: int, y: int, rgba32: int) -> bool:
	for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var p: Vector2i = Vector2i(x, y) + step
		if p.x >= 0 and p.y >= 0 and p.x < image.get_width() and p.y < image.get_height() \
				and image.get_pixel(p.x, p.y).to_rgba32() == rgba32:
			return true
	return false


static func _color(rgb: Array) -> Color:
	return Color8(int(rgb[0]), int(rgb[1]), int(rgb[2]))
