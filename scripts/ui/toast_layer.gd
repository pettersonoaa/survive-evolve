extends CanvasLayer

@onready var _label: Label = $ToastLabel

var _time_left := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label.visible = false
	EventBus.ui_toast.connect(_on_toast)


func _process(delta: float) -> void:
	if _time_left <= 0.0:
		_label.visible = false
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_label.visible = false


func _on_toast(message: String, seconds: float) -> void:
	_label.text = message
	_label.visible = true
	_time_left = seconds
