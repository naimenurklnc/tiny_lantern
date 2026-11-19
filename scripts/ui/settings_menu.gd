extends Control
## Ayarlar menüsü: Müzik, SFX ve Sessize alma kontrolleri.

signal closed

@onready var music_slider: HSlider = $Panel/VBox/MusicSlider
@onready var sfx_slider: HSlider = $Panel/VBox/SfxSlider
@onready var mute_check: CheckButton = $Panel/VBox/MuteCheck
@onready var back_button: Button = $Panel/VBox/BackButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_slider.value_changed.connect(_on_audio_changed)
	sfx_slider.value_changed.connect(_on_audio_changed)
	mute_check.toggled.connect(_on_mute_toggled)
	back_button.pressed.connect(_on_back_pressed)
	sync_from_save()


func sync_from_save() -> void:
	music_slider.set_value_no_signal(float(SaveManager.data.get("music_volume", 0.8)))
	sfx_slider.set_value_no_signal(float(SaveManager.data.get("sfx_volume", 0.9)))
	mute_check.set_pressed_no_signal(bool(SaveManager.data.get("muted", false)))


func _on_audio_changed(_val: float) -> void:
	SaveManager.set_audio_settings(music_slider.value, sfx_slider.value, mute_check.button_pressed)
	AudioManager.apply_settings()


func _on_mute_toggled(_pressed: bool) -> void:
	AudioManager.play_sfx("button", 0.02)
	SaveManager.set_audio_settings(music_slider.value, sfx_slider.value, mute_check.button_pressed)
	AudioManager.apply_settings()


func _on_back_pressed() -> void:
	AudioManager.play_sfx("button", 0.02)
	visible = false
	closed.emit()
