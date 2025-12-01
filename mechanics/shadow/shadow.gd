extends MeshInstance2D
class_name Shadow

## Configurações da sombra
@export var auto_resize: bool = true
@export var width_scale: float = 2  ## Multiplicador da largura do sprite
@export var height_scale: float = 0.4  ## Multiplicador da altura (geralmente menor para parecer no chão)
@export var vertical_offset: float = 0.0  ## Offset vertical adicional

## Referência ao sprite pai (detectado automaticamente)
var _parent_sprite: Node2D = null
var _last_texture_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	if auto_resize:
		_find_parent_sprite()
		_update_shadow_size()

func _process(_delta: float) -> void:
	if auto_resize and _parent_sprite:
		_update_shadow_size()

func _find_parent_sprite() -> void:
	var parent = get_parent()
	if not parent:
		return
	
	# Procura por AnimatedSprite2D
	for child in parent.get_children():
		if child is AnimatedSprite2D:
			_parent_sprite = child
			return
	
	# Procura por Sprite2D
	for child in parent.get_children():
		if child is Sprite2D:
			_parent_sprite = child
			return

func _update_shadow_size() -> void:
	if not _parent_sprite:
		return
	
	var sprite_size: Vector2 = _get_sprite_size()
	
	# Só atualiza se o tamanho mudou
	if sprite_size == _last_texture_size and sprite_size != Vector2.ZERO:
		return
	
	_last_texture_size = sprite_size
	
	if sprite_size == Vector2.ZERO:
		return
	
	# Calcula novo tamanho da sombra
	var shadow_width: float = sprite_size.x * width_scale
	var shadow_height: float = sprite_size.x * height_scale  # Usa X para manter proporção circular
	
	# Atualiza o mesh
	if mesh is QuadMesh:
		(mesh as QuadMesh).size = Vector2(shadow_width, shadow_height)
	
	# Ajusta posição vertical baseado no tamanho do sprite
	position.y = (sprite_size.y / 2.0) + vertical_offset

func _get_sprite_size() -> Vector2:
	if _parent_sprite is AnimatedSprite2D:
		var anim_sprite := _parent_sprite as AnimatedSprite2D
		if anim_sprite.sprite_frames == null:
			return Vector2.ZERO
		
		var current_animation := anim_sprite.animation
		var current_frame := anim_sprite.frame
		
		if not anim_sprite.sprite_frames.has_animation(current_animation):
			return Vector2.ZERO
		
		var frame_count := anim_sprite.sprite_frames.get_frame_count(current_animation)
		if frame_count == 0:
			return Vector2.ZERO
		
		var frame_texture := anim_sprite.sprite_frames.get_frame_texture(current_animation, current_frame)
		if frame_texture:
			return frame_texture.get_size()
	
	elif _parent_sprite is Sprite2D:
		var sprite := _parent_sprite as Sprite2D
		if sprite.texture:
			return sprite.texture.get_size()
	
	return Vector2.ZERO

## Função para ajustar manualmente os parâmetros do shader
func set_shadow_parameters(color: Color = Color(0, 0, 0, 0.4), softness: float = 0.4) -> void:
	if material and material is ShaderMaterial:
		var shader_mat := material as ShaderMaterial
		shader_mat.set_shader_parameter("shadow_color", color)
		shader_mat.set_shader_parameter("shadow_softness", softness)
