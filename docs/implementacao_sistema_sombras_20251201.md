# Implementação do Sistema de Sombras

**Data:** 01/12/2025  
**Tipo:** Nova Feature  
**Módulos Afetados:** `/mechanics/shadow`, `/entities/player`

## Resumo

Foi implementado um sistema de sombras reutilizável usando shaders do Godot 4, permitindo adicionar sombras suaves e configuráveis abaixo de personagens (player e inimigos).

## Arquivos Criados

### 1. `/mechanics/shadow/shadow.gdshader`
Shader personalizado que cria uma sombra elíptica suave usando distância radial e smoothstep.

**Parâmetros configuráveis:**
- `shadow_color`: Cor da sombra (padrão: preto com alpha 0.5)
- `shadow_width`: Largura da sombra (0.1 a 2.0, padrão: 1.0)
- `shadow_height`: Altura da sombra (0.1 a 2.0, padrão: 0.5)
- `shadow_softness`: Suavidade das bordas (0.0 a 1.0, padrão: 0.3)
- `shadow_offset`: Deslocamento da sombra em relação ao centro (padrão: Vector2(0, 0))

**Funcionamento:**
1. Centraliza as coordenadas UV
2. Aplica proporção da elipse baseado em width e height
3. Calcula distância do centro
4. Cria gradiente suave usando smoothstep
5. Aplica cor com alpha baseado na intensidade

### 2. `/mechanics/shadow/shadow_material.tres`
Material que utiliza o shader criado com valores padrão apropriados para sombras de personagens.

### 3. `/mechanics/shadow/shadow.tscn`
Cena reutilizável contendo:
- `ColorRect` com tamanho 32x16 pixels
- Material de sombra aplicado
- `Marker2D` (ShadowPosition) para referência de posicionamento

## Integração

### Player
A sombra foi integrada na cena base `/entities/player/player_character_body_2d.tscn`:

```gdscript
[node name="Shadow" parent="." instance=ExtResource("3_shadow")]
z_index = -1
offset_left = -16.0
offset_top = 6.0
offset_right = 16.0
offset_bottom = 22.0
```

**Posicionamento:**
- `z_index = -1`: Garante que a sombra apareça atrás do sprite
- Posicionada aos pés do personagem (offset_top: 6.0)
- Centralizada horizontalmente

## Como Usar em Inimigos

Para adicionar a sombra em qualquer inimigo:

1. Abra a cena do inimigo no Godot
2. Adicione a cena `res://mechanics/shadow/shadow.tscn` como filho do nó raiz
3. Configure o `z_index = -1` para ficar atrás
4. Ajuste a posição usando os offsets
5. (Opcional) Ajuste os parâmetros do shader no Inspector:
   - Tamanho: modifique `shadow_width` e `shadow_height`
   - Transparência: ajuste `shadow_color` alpha
   - Suavidade: modifique `shadow_softness`

## Exemplo de Código

Para instanciar programaticamente:

```gdscript
var shadow_scene = preload("res://mechanics/shadow/shadow.tscn")
var shadow_instance = shadow_scene.instantiate()
shadow_instance.z_index = -1
shadow_instance.offset_left = -16.0
shadow_instance.offset_top = 6.0
shadow_instance.offset_right = 16.0
shadow_instance.offset_bottom = 22.0
add_child(shadow_instance)
```

## Vantagens da Implementação

1. **Reutilizável**: Basta instanciar a cena em qualquer entidade
2. **Configurável**: Todos os parâmetros podem ser ajustados no Inspector
3. **Performance**: Shader executado na GPU, muito eficiente
4. **Visual Suave**: Usa smoothstep para bordas suaves e naturais
5. **Fácil Manutenção**: Centralizado em um único local

## Observações Técnicas

- O shader usa `shader_type canvas_item` para integração com 2D
- A sombra é renderizada como elipse para parecer mais natural
- O parâmetro `shadow_softness` controla o gradiente nas bordas
- ColorRect é usado em vez de Sprite2D para não precisar de textura

## Próximos Passos (Opcional)

- Adicionar animação de pulsação para sombra (breathing effect)
- Implementar variação de tamanho baseado em altura do personagem
- Adicionar suporte a sombras coloridas para efeitos especiais
- Criar variantes (sombra quadrada, triangular, etc.)
