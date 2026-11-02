extends Control
class_name CRTOverlay
## Capa decorativa de líneas de barrido y viñeteado. No captura el ratón y no
## participa en la lógica del juego.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	if not visible or size.x <= 0.0 or size.y <= 0.0:
		return

	# Líneas de barrido.
	for y in range(0, int(size.y), 4):
		draw_rect(Rect2(0.0, float(y), size.x, 1.0), Color(0.0, 0.0, 0.0, 0.11))

	# Viñeteado sutil para reforzar la sensación de tubo antiguo.
	for i in 20:
		var margen := float(i) * 2.0
		var rect := Rect2(margen, margen, size.x - margen * 2.0, size.y - margen * 2.0)
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			break
		draw_rect(rect, Color(0.0, 0.0, 0.0, 0.012), false, 2.0)
