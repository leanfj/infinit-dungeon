# Implementação do Sistema de Menus - 01/12/2024 22:38

## Resumo
Implementado sistema completo de menus para o jogo "Infinit Dungeon", incluindo tela principal, seleção de quantidade de jogadores e seleção de personagens. O sistema suporta navegação via mouse, teclado e gamepad.

## Arquivos Criados

### 1. `/menus/main_menu.gd` e `/menus/main_menu.tscn`
**Propósito**: Tela inicial do jogo com título e opções principais.

**Funcionalidades**:
- Exibe título "Infinit Dungeon" (fonte 32pt)
- Botões "Start" e "Quit" (fonte 16pt/18pt)
- Navegação completa: mouse hover, teclado (setas/WASD), gamepad (D-pad)
- Transição para `player_count_menu.tscn` ao clicar em Start
- Fecha o jogo ao clicar em Quit

**Estrutura da Cena**:
```
Control (MainMenu)
├── ColorRect (fundo escuro #1A1A26)
└── VBoxContainer (centralizado)
    ├── TitleLabel ("Infinit Dungeon")
    ├── StartButton
    └── QuitButton
```

**Mecânica de Navegação**:
- Array `_buttons` armazena referências aos botões
- `_selected_index` rastreia botão focado
- Eventos `move_up`/`move_down` alternam seleção
- `primary_attack` ou Enter emite sinal `pressed` do botão
- Mouse hover atualiza `_selected_index` automaticamente

### 2. `/menus/player_count_menu.gd` e `/menus/player_count_menu.tscn`
**Propósito**: Seleção da quantidade de jogadores (1-4).

**Funcionalidades**:
- Título "Select Player Count" (fonte 28pt)
- 4 botões para selecionar 1, 2, 3 ou 4 jogadores (fonte 20pt)
- Botão "Back" para retornar ao menu principal
- Armazena seleção em `GameState.player_count`
- Transição para `character_select_menu.tscn` após seleção

**Estrutura da Cena**:
```
Control (PlayerCountMenu)
├── ColorRect (fundo escuro)
└── VBoxContainer
    ├── TitleLabel
    ├── PlayerButtons (VBoxContainer)
    │   ├── OnePlayerButton
    │   ├── TwoPlayersButton
    │   ├── ThreePlayersButton
    │   └── FourPlayersButton
    └── BackButton
```

**Lógica de Seleção**:
- `_on_player_count_selected(count: int)` armazena `count` em `GameState.player_count`
- Navegação idêntica ao main menu (mouse/teclado/gamepad)

### 3. `/menus/character_select_menu.gd` e `/menus/character_select_menu.tscn`
**Propósito**: Seleção de personagens para cada jogador.

**Funcionalidades**:
- Título "Character Selection" (fonte 28pt)
- Label de informação mostrando qual jogador deve selecionar
- Grid de personagens (atualmente apenas "Mage" disponível)
- Botões "Start Game" e "Back"
- Rastreia seleções em Dictionary `_selections` (player_index -> character_name)
- Auto-foca botão Start quando todos jogadores selecionaram

**Estrutura da Cena**:
```
Control (CharacterSelectMenu)
├── ColorRect (fundo escuro)
└── VBoxContainer
    ├── TitleLabel
    ├── InfoLabel ("Player X - Select Character")
    ├── CharacterGrid (GridContainer 2 colunas)
    │   └── (botões criados dinamicamente via código)
    ├── StartButton
    └── BackButton
```

**Mecânica de Seleção**:
- Constante `CHARACTERS` define personagens disponíveis:
  ```gdscript
  const CHARACTERS = [
      {"name": "Mage", "scene": "res://entities/player/player_character_body_2d.tscn", "description": "Master of magic"}
  ]
  ```
- `_setup_character_buttons()` cria botões dinamicamente em `_ready()`
- `_on_character_selected(character_name)` registra seleção do próximo jogador
- `_get_next_player_to_select()` identifica jogador sem personagem
- `_update_info_label()` atualiza texto indicando próximo jogador ou "All ready"
- `_on_start_pressed()` valida se todos selecionaram e inicia o jogo

**Navegação Avançada**:
- `move_left`/`move_right` navegam horizontalmente no grid
- `move_up`/`move_down` navegam verticalmente entre todos botões
- Função `_navigate_grid(direction)` limita navegação horizontal ao grid

### 4. `/mechanics/game_state.gd`
**Propósito**: Singleton (autoload) para armazenar estado global do jogo.

**Propriedades**:
- `player_count: int = 1` - Quantidade de jogadores selecionada
- `selected_characters: Array[String] = []` - Personagens escolhidos por cada jogador

**Métodos**:
- `reset()` - Reinicia estado para valores padrão
- Chamado em `_ready()` para inicialização

**Registro no Projeto**:
Adicionado em `project.godot`:
```ini
[autoload]
GameState="*res://mechanics/game_state.gd"
```

## Alterações em Arquivos Existentes

### `/project.godot`
**Mudanças**:
1. Alterado `run/main_scene` de `res://scenes/world_node_2d.tscn` para `res://menus/main_menu.tscn`
2. Adicionada seção `[autoload]` com `GameState`

**Impacto**: Jogo agora inicia no menu principal ao invés de direto na cena de jogo.

## Fluxo de Navegação

```
MainMenu (main_menu.tscn)
    ↓ Start
PlayerCountMenu (player_count_menu.tscn)
    ↓ Seleciona 1-4 jogadores
CharacterSelectMenu (character_select_menu.tscn)
    ↓ Cada jogador seleciona personagem
    ↓ Start Game
WorldNodePrimary (world_node_2d.tscn)
```

**Navegação Reversa**:
- CharacterSelectMenu → Back → PlayerCountMenu
- PlayerCountMenu → Back → MainMenu
- MainMenu → Quit → Fecha o jogo

## Padrões de Input

Todos os menus seguem padrão consistente de input:

| Ação | Teclado | Gamepad | Mouse |
|------|---------|---------|-------|
| Navegar para cima | W / ↑ | D-pad ↑ / Stick ↑ | - |
| Navegar para baixo | S / ↓ | D-pad ↓ / Stick ↓ | - |
| Navegar esquerda* | A / ← | D-pad ← / Stick ← | - |
| Navegar direita* | D / → | D-pad → / Stick → | - |
| Selecionar | Enter | Botão A | Click esquerdo |
| Hover | - | - | Mouse over |

*Navegação horizontal apenas em CharacterSelectMenu dentro do grid.

## Considerações Técnicas

### Prevenção de Input Duplicado
Cada menu chama `get_viewport().set_input_as_handled()` após processar eventos para evitar que múltiplos sistemas respondam ao mesmo input.

### Sistema de Foco
- `grab_focus()` aplicado ao botão selecionado via `_update_focus()`
- Mouse hover conectado a `_on_button_hovered(index)` para sincronizar `_selected_index`
- `release_focus()` removido (causava conflitos com cliques de mouse)

### Validação de Seleções
CharacterSelectMenu valida se todos jogadores selecionaram antes de iniciar:
```gdscript
if _selections.size() != GameState.player_count:
    _info_label.text = "Please select characters for all players!"
    return
```

### Expansibilidade
Para adicionar novos personagens, basta incluir na constante `CHARACTERS`:
```gdscript
const CHARACTERS = [
    {"name": "Mage", "scene": "res://entities/player/mage.tscn", "description": "Master of magic"},
    {"name": "Warrior", "scene": "res://entities/player/warrior.tscn", "description": "Strong fighter"},
    # ...
]
```

## Problemas Conhecidos

1. **GameState Lint Errors**: Editor mostra erro "Identifier 'GameState' not declared" até recarregar o projeto. Isso é normal com autoloads recém-criados.

2. **Personagem Único**: Atualmente apenas "Mage" está disponível. Sistema está preparado para múltiplos personagens, mas requer criação de novas cenas/scripts.

3. **Sem Persistência**: Seleções são perdidas ao fechar o jogo. Para persistir, seria necessário implementar sistema de save/load.

## Próximos Passos Sugeridos

1. **Implementar Spawning Multi-jogador**: Modificar `world_node_2d.tscn` para instanciar personagens baseado em `GameState.selected_characters`

2. **Criar Mais Personagens**: Adicionar Warrior, Archer, Rogue com sprites e stats únicos

3. **Animações de Transição**: Adicionar fade in/out entre menus

4. **Preview de Personagem**: Mostrar sprite e stats do personagem ao selecionar no CharacterSelectMenu

5. **Configuração de Controles**: Menu para mapear inputs de cada jogador

## Conclusão

Sistema de menus completo e funcional implementado com navegação robusta suportando três tipos de input. Arquitetura preparada para expansão de personagens e modos de jogo. Estado global gerenciado por singleton GameState permite comunicação entre menus e cena de jogo.
