extends PanelContainer
class_name NumberLessonPanel

signal closed
signal back_requested

const NUMBERS_PATH := "res://data/courses/numbers.json"
const DATA_ROOT := "res://data"

var items: Array = []
var lessons: Array = []
var item_by_id := {}
var current_item: Dictionary = {}
var current_answers: Array[String] = []
var current_mode := ""
var score := 0
var streak := 0
var round_number := 0

var title_label: Label
var body_box: VBoxContainer
var stat_label: Label
var prompt_mode_label: Label
var question_label: Label
var answer_input: LineEdit
var audio_button: Button
var feedback_label: Label
var audio_player: AudioStreamPlayer


func _ready() -> void:
	_load_numbers()
	_build_ui()
	visible = false


func open_menu() -> void:
	visible = true
	_show_menu()


func _load_numbers() -> void:
	if not FileAccess.file_exists(NUMBERS_PATH):
		push_warning("Missing numbers course file: %s" % NUMBERS_PATH)
		return

	var text := FileAccess.get_file_as_string(NUMBERS_PATH)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Invalid numbers course file: %s" % NUMBERS_PATH)
		return

	items = parsed.get("items", [])
	lessons = parsed.get("lessons", [])
	item_by_id.clear()
	for item in items:
		if typeof(item) == TYPE_DICTIONARY and item.has("id"):
			item_by_id[str(item["id"])] = item


func _build_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(540, 600)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)

	title_label = Label.new()
	title_label.text = "Number Course / Curso de números"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)

	var close_button := Button.new()
	close_button.text = "Close / Cerrar"
	close_button.pressed.connect(_close)
	header.add_child(close_button)

	body_box = VBoxContainer.new()
	body_box.add_theme_constant_override("separation", 12)
	body_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body_box)

	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)


func _show_menu() -> void:
	_clear_body()
	title_label.text = "Number Course / Curso de números"

	var intro := Label.new()
	intro.text = "Number Course\nCurso de números"
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_font_size_override("font_size", 22)
	body_box.add_child(intro)

	var lesson_button := Button.new()
	lesson_button.text = "1. Number Rules / Reglas de números"
	lesson_button.custom_minimum_size = Vector2(0, 54)
	lesson_button.pressed.connect(Callable(self, "_show_lesson"))
	body_box.add_child(lesson_button)

	var practice_button := Button.new()
	practice_button.text = "2. Number Practice / Práctica de números"
	practice_button.custom_minimum_size = Vector2(0, 54)
	practice_button.pressed.connect(Callable(self, "_show_practice"))
	body_box.add_child(practice_button)

	var back_button := Button.new()
	back_button.text = "Back / Volver"
	back_button.custom_minimum_size = Vector2(0, 48)
	back_button.pressed.connect(Callable(self, "_request_back"))
	body_box.add_child(back_button)


func _show_lesson() -> void:
	_clear_body()
	title_label.text = "Number Rules / Reglas de números"

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_box.add_child(scroll)

	var lesson_box := VBoxContainer.new()
	lesson_box.add_theme_constant_override("separation", 12)
	lesson_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(lesson_box)

	for lesson in lessons:
		if typeof(lesson) != TYPE_DICTIONARY:
			continue

		var item := _lesson_item(lesson)
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		lesson_box.add_child(row)

		var title := Label.new()
		title.text = str(lesson.get("title", "Number rule"))
		title.add_theme_font_size_override("font_size", 18)
		row.add_child(title)

		var example := HBoxContainer.new()
		example.add_theme_constant_override("separation", 10)
		row.add_child(example)

		var digits := Label.new()
		digits.text = str(item.get("digits", ""))
		digits.custom_minimum_size = Vector2(96, 0)
		digits.add_theme_font_size_override("font_size", 24)
		example.add_child(digits)

		var spanish := Label.new()
		spanish.text = str(item.get("spanish", ""))
		spanish.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		spanish.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spanish.add_theme_font_size_override("font_size", 20)
		example.add_child(spanish)

		var audio := Button.new()
		audio.text = "Audio / Audio"
		audio.disabled = not _has_audio_file(item)
		audio.pressed.connect(func(): _play_item_audio(item))
		example.add_child(audio)

		var explanation := Label.new()
		explanation.text = str(lesson.get("explanation", ""))
		explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(explanation)

		var separator := HSeparator.new()
		lesson_box.add_child(separator)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	body_box.add_child(actions)

	var practice_button := Button.new()
	practice_button.text = "Start Practice / Empezar práctica"
	practice_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	practice_button.pressed.connect(_show_practice)
	actions.add_child(practice_button)

	var back_button := Button.new()
	back_button.text = "Back / Volver"
	back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_button.pressed.connect(_show_menu)
	actions.add_child(back_button)


func _show_practice() -> void:
	_clear_body()
	title_label.text = "Number Practice / Práctica de números"
	score = 0
	streak = 0
	round_number = 0

	stat_label = Label.new()
	stat_label.text = "Score 0  |  Streak 0  |  Round 0"
	body_box.add_child(stat_label)

	prompt_mode_label = Label.new()
	prompt_mode_label.text = "Number Practice"
	prompt_mode_label.add_theme_color_override("font_color", Color(0.16, 0.50, 0.66))
	body_box.add_child(prompt_mode_label)

	question_label = Label.new()
	question_label.text = ""
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.add_theme_font_size_override("font_size", 30)
	question_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_box.add_child(question_label)

	audio_button = Button.new()
	audio_button.text = "Play Audio / Reproducir audio"
	audio_button.pressed.connect(func(): _play_item_audio(current_item))
	body_box.add_child(audio_button)

	answer_input = LineEdit.new()
	answer_input.placeholder_text = "Type your answer / Escribe tu respuesta"
	answer_input.text_submitted.connect(func(_text: String): _submit_answer())
	body_box.add_child(answer_input)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	body_box.add_child(actions)

	var check_button := Button.new()
	check_button.text = "Check / Revisar"
	check_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	check_button.pressed.connect(_submit_answer)
	actions.add_child(check_button)

	var skip_button := Button.new()
	skip_button.text = "Skip / Saltar"
	skip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skip_button.pressed.connect(_next_prompt)
	actions.add_child(skip_button)

	var back_button := Button.new()
	back_button.text = "Back / Volver"
	back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_button.pressed.connect(_show_menu)
	actions.add_child(back_button)

	feedback_label = Label.new()
	feedback_label.text = ""
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_box.add_child(feedback_label)

	_next_prompt()
	answer_input.grab_focus()


func _next_prompt() -> void:
	if items.is_empty():
		question_label.text = "No number data found."
		audio_button.visible = false
		return

	round_number += 1
	current_item = items.pick_random()
	var modes: Array[String] = ["text_to_digits", "digits_to_text"]
	if _has_audio_file(current_item):
		modes.append("audio_to_digits")

	current_mode = modes.pick_random()
	current_answers.clear()

	match current_mode:
		"text_to_digits":
			prompt_mode_label.text = "Spanish text to digits"
			question_label.text = str(current_item.get("spanish", ""))
			current_answers.append(str(current_item.get("digits", "")))
			audio_button.visible = false
		"digits_to_text":
			prompt_mode_label.text = "Digits to Spanish text"
			question_label.text = str(current_item.get("digits", ""))
			_add_spanish_answers(current_item)
			audio_button.visible = false
		"audio_to_digits":
			prompt_mode_label.text = "Audio to digits"
			question_label.text = "Listen and type the number."
			current_answers.append(str(current_item.get("digits", "")))
			audio_button.visible = true
			_play_item_audio(current_item)

	answer_input.text = ""
	feedback_label.text = "Try the next number prompt."
	_update_stats()


func _submit_answer() -> void:
	var value := answer_input.text.strip_edges()
	if value.is_empty():
		return

	var accepted := false
	if current_mode == "digits_to_text":
		var normalized := _normalize_spanish(value)
		for answer in current_answers:
			if normalized == _normalize_spanish(answer):
				accepted = true
				break
	else:
		var normalized_digits := _normalize_digits(value)
		for answer in current_answers:
			if normalized_digits == _normalize_digits(answer):
				accepted = true
				break

	if accepted:
		score += 1
		streak += 1
		feedback_label.text = "Correct. %s" % " / ".join(current_answers)
	else:
		streak = 0
		feedback_label.text = "Not quite. Answer: %s" % " / ".join(current_answers)

	answer_input.text = ""
	_update_stats()


func _add_spanish_answers(item: Dictionary) -> void:
	current_answers.append(str(item.get("spanish", "")))
	for answer in item.get("accepted_spanish", []):
		var text := str(answer)
		if not current_answers.has(text):
			current_answers.append(text)


func _lesson_item(lesson: Dictionary) -> Dictionary:
	var item_id := str(lesson.get("item_id", ""))
	return item_by_id.get(item_id, {})


func _play_item_audio(item: Dictionary) -> void:
	var path := _audio_path(item)
	if path.is_empty():
		return

	var stream := _load_audio_stream(path)
	if stream != null:
		audio_player.stream = stream
		audio_player.play()


func _load_audio_stream(path: String) -> AudioStream:
	var stream := load(path)
	if stream != null:
		return stream

	if path.get_extension().to_lower() == "mp3" and FileAccess.file_exists(path):
		var mp3 := AudioStreamMP3.new()
		mp3.data = FileAccess.get_file_as_bytes(path)
		return mp3

	return null


func _has_audio_file(item: Dictionary) -> bool:
	var path := _audio_path(item)
	return not path.is_empty() and (FileAccess.file_exists(path) or ResourceLoader.exists(path))


func _audio_path(item: Dictionary) -> String:
	if item.is_empty() or not item.has("audio"):
		return ""
	var audio := str(item["audio"])
	if audio.is_empty():
		return ""
	if audio.begins_with("res://"):
		return audio
	return "%s/%s" % [DATA_ROOT, audio]


func _update_stats() -> void:
	stat_label.text = "Score %d  |  Streak %d  |  Round %d" % [score, streak, round_number]


func _normalize_spanish(value: String) -> String:
	var normalized := value.to_lower().strip_edges()
	normalized = normalized.replace("á", "a")
	normalized = normalized.replace("é", "e")
	normalized = normalized.replace("í", "i")
	normalized = normalized.replace("ó", "o")
	normalized = normalized.replace("ú", "u")
	normalized = normalized.replace("ü", "u")
	normalized = normalized.replace("ñ", "n")
	for mark in [".", ",", "!", "?", "¡", "¿", ";", ":", "-", "_"]:
		normalized = normalized.replace(mark, " ")
	while normalized.contains("  "):
		normalized = normalized.replace("  ", " ")
	return normalized.strip_edges()


func _normalize_digits(value: String) -> String:
	var cleaned := ""
	for index in value.length():
		var ch := value.substr(index, 1)
		if "0123456789".contains(ch):
			cleaned += ch
	while cleaned.length() > 1 and cleaned.begins_with("0"):
		cleaned = cleaned.substr(1)
	return cleaned


func _clear_body() -> void:
	for child in body_box.get_children():
		body_box.remove_child(child)
		child.queue_free()


func _request_back() -> void:
	visible = false
	audio_player.stop()
	back_requested.emit()


func _close() -> void:
	visible = false
	audio_player.stop()
	closed.emit()
