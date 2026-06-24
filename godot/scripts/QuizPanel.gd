extends PanelContainer
class_name QuizPanel

signal closed

const VOCABULARY_PATH := "res://data/vocabulary.json"

var items: Array = []
var current_item: Dictionary = {}
var current_answers: Array[String] = []
var score := 0
var streak := 0
var round_number := 0

var title_label: Label
var stat_label: Label
var prompt_mode_label: Label
var question_label: Label
var feedback_label: Label
var answer_input: LineEdit
var audio_button: Button
var audio_player: AudioStreamPlayer

func _ready() -> void:
    _load_vocabulary()
    _build_ui()
    visible = false


func start(character_name: String) -> void:
    title_label.text = "%s Practice" % character_name
    visible = true
    _next_prompt()
    answer_input.grab_focus()


func _load_vocabulary() -> void:
    if not FileAccess.file_exists(VOCABULARY_PATH):
        push_warning("Missing vocabulary file: %s" % VOCABULARY_PATH)
        return

    var text := FileAccess.get_file_as_string(VOCABULARY_PATH)
    var parsed = JSON.parse_string(text)
    if typeof(parsed) == TYPE_DICTIONARY and parsed.has("items"):
        items = parsed["items"]


func _build_ui() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    custom_minimum_size = Vector2(344, 430)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 16)
    margin.add_theme_constant_override("margin_right", 16)
    margin.add_theme_constant_override("margin_top", 16)
    margin.add_theme_constant_override("margin_bottom", 16)
    add_child(margin)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    margin.add_child(box)

    var header := HBoxContainer.new()
    box.add_child(header)

    title_label = Label.new()
    title_label.text = "Scholar Practice"
    title_label.add_theme_font_size_override("font_size", 24)
    header.add_child(title_label)

    var header_spacer := Control.new()
    header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(header_spacer)

    var close_button := Button.new()
    close_button.text = "Close"
    close_button.pressed.connect(_close)
    header.add_child(close_button)

    stat_label = Label.new()
    stat_label.text = "Score 0  |  Streak 0  |  Round 0"
    box.add_child(stat_label)

    prompt_mode_label = Label.new()
    prompt_mode_label.text = "Spanish to English"
    prompt_mode_label.add_theme_color_override("font_color", Color(0.16, 0.50, 0.66))
    box.add_child(prompt_mode_label)

    question_label = Label.new()
    question_label.text = "hola"
    question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    question_label.add_theme_font_size_override("font_size", 30)
    box.add_child(question_label)

    audio_button = Button.new()
    audio_button.text = "Play Audio"
    audio_button.pressed.connect(_play_audio)
    box.add_child(audio_button)

    answer_input = LineEdit.new()
    answer_input.placeholder_text = "Type your answer"
    answer_input.text_submitted.connect(func(_text: String): _submit_answer())
    box.add_child(answer_input)

    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation", 10)
    box.add_child(actions)

    var check_button := Button.new()
    check_button.text = "Check"
    check_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    check_button.pressed.connect(_submit_answer)
    actions.add_child(check_button)

    var skip_button := Button.new()
    skip_button.text = "Skip"
    skip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    skip_button.pressed.connect(_next_prompt)
    actions.add_child(skip_button)

    feedback_label = Label.new()
    feedback_label.text = "Answer the scholar's prompt. No battle, just practice."
    feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    box.add_child(feedback_label)

    audio_player = AudioStreamPlayer.new()
    add_child(audio_player)


func _next_prompt() -> void:
    if items.is_empty():
        question_label.text = "No vocabulary found."
        audio_button.visible = false
        return

    round_number += 1
    current_item = items.pick_random()
    var modes: Array[String] = ["spanish_to_english", "english_to_spanish"]
    if current_item.has("audio"):
        modes.append("audio_to_spanish")

    var mode: String = modes.pick_random()
    current_answers.clear()

    match mode:
        "spanish_to_english":
            prompt_mode_label.text = "Spanish to English"
            question_label.text = str(current_item.get("spanish", ""))
            for answer in current_item.get("english", []):
                current_answers.append(str(answer))
            audio_button.visible = false
        "english_to_spanish":
            prompt_mode_label.text = "English to Spanish"
            question_label.text = str(current_item.get("english", [""])[0])
            current_answers.append(str(current_item.get("spanish", "")))
            audio_button.visible = false
        "audio_to_spanish":
            prompt_mode_label.text = "Audio to Spanish"
            question_label.text = "Listen and type the Spanish."
            current_answers.append(str(current_item.get("spanish", "")))
            audio_button.visible = true
            _play_audio()

    answer_input.text = ""
    feedback_label.text = "Try the next Spanish prompt."
    _update_stats()


func _submit_answer() -> void:
    var value := answer_input.text.strip_edges()
    if value.is_empty():
        return

    var normalized := _normalize(value)
    var accepted := false
    for answer in current_answers:
        if normalized == _normalize(answer):
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


func _play_audio() -> void:
    if not current_item.has("audio"):
        return

    var audio_path := "res://data/%s" % str(current_item["audio"])
    var stream := load(audio_path)
    if stream != null:
        audio_player.stream = stream
        audio_player.play()


func _update_stats() -> void:
    stat_label.text = "Score %d  |  Streak %d  |  Round %d" % [score, streak, round_number]


func _normalize(value: String) -> String:
    return value.to_lower().strip_edges()


func _close() -> void:
    visible = false
    closed.emit()
