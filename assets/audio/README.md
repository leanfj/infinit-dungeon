# Instruções para Adicionar Áudio aos Menus

## Sistema de Áudio Implementado

O sistema de áudio para os menus foi implementado através do singleton `MenuAudio` que gerencia:
- Música de fundo contínua em todos os menus
- Efeitos sonoros ao navegar pelos botões
- Efeitos sonoros ao clicar nos botões

## Arquivos de Áudio Necessários

Coloque os seguintes arquivos de áudio na pasta `assets/audio/`:

### 1. Música de Fundo do Menu
**Arquivo**: `menu_music.ogg`
- **Formato**: OGG Vorbis (recomendado para loops)
- **Tipo**: Música ambiente/tema do menu
- **Loop**: Deve ter loop ativado no Godot
- **Duração**: 1-3 minutos (vai repetir automaticamente)

### 2. Som de Hover (Passar o mouse/navegar)
**Arquivo**: `button_hover.ogg`
- **Formato**: OGG Vorbis ou WAV
- **Tipo**: Som sutil de feedback
- **Duração**: Muito curto (0.1-0.2 segundos)
- **Exemplo**: Som de "tick" suave, beep baixo

### 3. Som de Click (Selecionar)
**Arquivo**: `button_click.ogg`
- **Formato**: OGG Vorbis ou WAV
- **Tipo**: Som de confirmação
- **Duração**: Curto (0.2-0.4 segundos)
- **Exemplo**: Som de "click", "confirm", ou tom mais forte que o hover

## Configuração no Godot

### 1. Importar os Arquivos
Depois de adicionar os arquivos na pasta `assets/audio/`, o Godot irá importá-los automaticamente.

### 2. Configurar Loop da Música
1. Selecione `menu_music.ogg` no FileSystem
2. Vá para a aba Import
3. Ative a opção **Loop**
4. Clique em **Reimport**

### 3. Ajustar Volumes (Opcional)
Você pode ajustar os volumes no script `menu_audio_manager.gd`:

```gdscript
@export var music_volume_db: float = -10.0  # Ajuste conforme necessário
@export var sfx_volume_db: float = -5.0     # Ajuste conforme necessário
```

Ou diretamente no autoload depois de abrir o projeto:
1. Vá em Project > Project Settings > Autoload
2. Clique no ícone de editar ao lado de MenuAudio
3. Ajuste os valores exportados no Inspector

## Como Trocar os Arquivos de Áudio

### Via Código
Você pode mudar os caminhos dos arquivos editando `menu_audio_manager.gd`:

```gdscript
@export var menu_music_path: String = "res://assets/audio/SUA_MUSICA.ogg"
@export var button_hover_sound_path: String = "res://assets/audio/SEU_HOVER.ogg"
@export var button_click_sound_path: String = "res://assets/audio/SEU_CLICK.ogg"
```

### Dinamicamente (Em Runtime)
```gdscript
# Para trocar a música durante o jogo
MenuAudio.change_menu_music("res://assets/audio/outra_musica.ogg")

# Para ajustar volumes
MenuAudio.set_music_volume(-15.0)
MenuAudio.set_sfx_volume(-8.0)
```

## Recursos Gratuitos para Áudio

### Música
- **OpenGameArt.org**: https://opengameart.org/
- **Incompetech**: https://incompetech.com/music/royalty-free/
- **FreePD**: https://freepd.com/

### Efeitos Sonoros
- **Freesound**: https://freesound.org/
- **Kenney**: https://kenney.nl/assets (seção de UI Audio)
- **Zapsplat**: https://www.zapsplat.com/

## Comportamento Atual

- **Main Menu**: Inicia a música ao abrir o jogo
- **Player Count Menu**: Mantém a música tocando
- **Character Select Menu**: Mantém a música tocando
- **Ao iniciar o jogo**: Para a música do menu automaticamente

## Testando Sem Áudio

O sistema está preparado para funcionar mesmo sem os arquivos de áudio. Se os arquivos não existirem, o jogo continuará funcionando normalmente, apenas sem som.

Para testar com áudio temporário, você pode usar qualquer arquivo OGG ou WAV e renomeá-lo para os nomes esperados.
