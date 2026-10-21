extends GutTest

var catalog: AnimalCatalog


func before_all() -> void:
	catalog = AnimalCatalog.new()


func test_raccoon_loads_with_defaults_filled_in() -> void:
	assert_true(catalog.has_animal("raccoon"))
	var raccoon: Dictionary = catalog.get_animal("raccoon")
	assert_eq(raccoon["name"], "Raccoon")
	assert_true(raccoon.has("startle_radius"), "defaults merged")
	assert_eq(catalog.get_animal("unicorn"), {})


func test_every_animal_has_art_a_real_skill_and_a_habitat() -> void:
	var factory: ProblemFactory = ProblemFactory.new()
	var habitats: Array[String] = []
	for id: String in factory.skill_ids():
		habitats.append(str(factory.skill_info(id)["habitat"]))
	for id: String in catalog.ids():
		var animal: Dictionary = catalog.get_animal(id)
		assert_true(ResourceLoader.exists(str(animal["sprite"])), id + " sprite missing")
		assert_true(ResourceLoader.exists(str(animal["faceset"])), id + " faceset missing")
		assert_true(factory.has_skill(str(animal["skill"])), id + " skill unknown")
		assert_has(habitats, str(animal["habitat"]), id + " habitat unknown")
		assert_has(["common", "uncommon", "rare", "special"], str(animal["rarity"]), id + " rarity")


func test_every_critter_on_a_map_is_in_the_catalog() -> void:
	var map: MapData = MapData.load_map("res://data/maps/meadow.txt")
	for c: Variant in map.critters:
		assert_true(catalog.has_animal(str(map.critters[c])), "legend uses unknown animal " + str(map.critters[c]))
