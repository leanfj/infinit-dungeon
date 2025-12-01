# Projeto Infinite Dungeon – Visão Geral e Guia de Implementação

Este documento resume o estado atual do projeto, sistemas implementados e sugestões de evolução. Tudo é baseado na estrutura de pastas existente e nos scripts já criados.

## Estrutura de Pastas Relevante
- `entities/player/` – Player base (`player_character_body_2d.gd/tscn`), câmera, projéteis.
- `entities/Enemies/` – Inimigos (ex.: `enemy_character_body_2d.gd/tscn`).
- `entities/Environments/` – Itens de cenário (Crate, Keys, Flasks, Door, etc).
- `mechanics/` – Componentes genéricos (HitBox, HurtBox, EnemySpawner, CharacterStats).
- `HUD/` – HUD de corações, chaves, pause e game over.
- `terrain/terrain_manager_node_2d.tscn` – Mapa com Rooms e portas entre salas.
- `scenes/world_node_2d.tscn` – Cena principal juntando player, spawners, HUDs.

## Sistemas Principais

### Combate e Colisão
- `mechanics/hit_box_area_2d.gd` (Area2D): recebe dano via `take_damage(amount, origin)` e emite sinal `hit_detected`.
- `mechanics/hurt_box_area_2d.gd` (Area2D): detecta `HitBoxArea2D`; chama `take_damage` do alvo e emite `hurt_detected`. Possui `target_groups` para filtrar quem pode ser atingido.
- Fireball (`entities/player/Mage/FireBall/fire_ball_node_2d.gd`):
  - Atinge qualquer corpo/área (aplica `take_damage` se existir).
  - Tem distância máxima (`max_distance`); ao colidir ou atingir o limite toca animação de hit e some.

### Inimigos
- Script base `enemy_character_body_2d.gd`:
  - Movimento de perseguição, animações, knockback.
  - Dano por contato usando `ContactArea2D`: registra players dentro, aplica dano com cooldown e empurra o inimigo para não “grudar”.
  - Usa opcionalmente `CharacterStats` para saúde/velocidade.
  - `exp_reward`: XP entregue ao player em `_reward_player` ao morrer.
  - Cena (`enemy_character_body_2d.tscn`) inclui `ContactArea2D` e shape específico.

### Player
- `player_character_body_2d.gd`:
  - Ataques primário (fireball) e secundário.
  - Vida em “meio-corações” (2 pontos = 1 coração). Cura (`heal`) respeita máximo do `CharacterStats`.
  - Recebe dano via HitBox.
  - `keys_changed` para HUD de chaves.
  - `gain_experience` integra com `CharacterStats` e atualiza atributos ao subir de nível; ao level up enche a vida.
  - Label de nível (`LevelLabel`) mostra “Lv X”.

### Sistema de Status (CharacterStats)
- Recurso `mechanics/character_stats.gd` (Resource):
  - level, experience, experience_to_next, max_health, current_health, move_speed, damage.
  - Métodos: `apply_damage`, `heal`, `gain_experience` (faz level up), sinal `leveled_up`.
  - Ao subir de nível: aumenta `max_health` (+2), zera XP excedente, enche `current_health`, aumenta `damage` e `move_speed`.
  - Uso:
    - Crie um `.tres` de CharacterStats no editor e atribua no export `stats` do player ou inimigo.
    - Para evoluir, chame `gain_experience(amount)` no player (ex.: ao matar inimigo).

### Itens e Drops
- Crates (`crate_node_2d.gd`): têm `drop_scenes` exportável (lista de PackedScenes). Ao quebrar, escolhe aleatoriamente uma cena; se a lista estiver vazia, não dropa nada.
- Key (`entities/Environments/Keys/key_node_2d.tscn`): ao coletar chama `player.add_key(1)` e some.
- Flask vermelho (`entities/Environments/Flasks/flask_red_node_2d.tscn`): cura 2 pontos de vida via `player.heal(2)`.

### Spawner e Progressão de Salas
- `mechanics/enemy_spawner.gd`:
  - Spawn inicial, respawns com limite (`max_total_spawns`), pontos de spawn (`SpawnPoint`).
  - Ao eliminar todos os inimigos do spawner, chama `_emit_cleared` e pode spawnar `key_scene`.
  - `spawn_point_limits` controla quantos spawn por ponto.
  - `min_spawn_spacing`/`spawn_position_jitter` evitam sobreposição.
  - Exemplo em `scenes/world_node_2d.tscn`: três spawners (Room1, Room2, Room3) com chaves dropadas ao limpar.

### Portas e Transição de Salas
- `entities/Door/door_node_2d.gd`:
  - Exporta `required_keys`, `next_spawn_path`, `activate_distance`, `teleport_player`.
  - Abre se o player tiver chave suficiente (`use_key`), toca animação e teleporta para `next_spawn_path` (ex.: `../Room2/Room2Spawn`). Se o path falhar, tenta achar “Room2Spawn” na cena.
  - Porta é “walls” para colidir com fireball.
  - Para novas salas: crie um spawn (ex.: `Room4Spawn`) e ajuste `next_spawn_path` da porta anterior.

### HUDs e Menus
- `HUD/player_hud.gd`: mostra corações (meio-coração) e ícone de chave/quantidade (configurável em `key_icon`, `heart_size`). Atualiza via sinais `health_changed`/`keys_changed`.
- `HUD/pause_menu.gd/tscn`: toggle por ESC (`ui_cancel`), com Retomar/Reiniciar/Sair, processa mesmo em pausa.
- `HUD/game_over.gd/tscn`: mostra painel ao player `died`, opções de reiniciar ou sair.
- `LevelLabel` no player mostra nível (fonte 10 px).

## Passos para Configurar / Customizar

1) Stats
   - Criar Resource: New Resource → CharacterStats → ajustar atributos → salvar como `.tres`.
   - Player: setar export `stats` no inspector para esse `.tres`.
   - Inimigo: idem, definindo health/speed/damage via stats (opcional).

2) XP e level up
   - Cada inimigo tem `exp_reward` (default 3). Ao morrer, entrega XP para o player atual.
   - Player ganha nível automaticamente ao exceder `experience_to_next`; vida enche e atributos sobem.
   - Para classes diferentes ou coop, atribua stats únicos a cada player e ajuste o ganho de XP conforme desejado.

3) Spawners e chaves
   - Em `world_node_2d.tscn`, cada spawner tem `max_total_spawns` e `key_scene`. Ao limpar, dropa chave.
   - Adicione `SpawnPoint` como filhos do spawner e ajuste `spawn_point_limits`.

4) Portas e salas
   - Cada porta tem `next_spawn_path` apontando para o spawn da próxima sala.
   - Garanta que `required_keys` esteja alinhado com o número de chaves disponíveis na sala atual.

5) Drops de crates
   - Em cada crate, configure `drop_scenes` (lista). Pode incluir chaves, flasks, ou nada (lista vazia).

6) Dano e contato
   - Inimigos têm `ContactArea2D` para causar dano contínuo ao player com cooldown.
   - Ajustar `contact_damage`, `contact_cooldown`, `contact_push` e o shape em `enemy_character_body_2d.tscn`.

7) Fireball
   - Ajustar `max_distance` no inspector. Fireball explode ao atingir qualquer coisa ou ao percorrer essa distância.

## Ações Futuras Sugeridas
- Coop e múltiplas classes: criar stats específicos por classe/player, permitir múltiplos players na cena, gerenciar câmera e HUD individuais ou compartilhados.
- Balanceamento de XP/níveis: exp_reward por tipo de inimigo, curvas de XP diferentes; talvez usar curvas customizadas ou tabelas no Resource.
- IA/Combate: ataques ativos de inimigos (projetis, hitboxes de ataque), esquiva do player e frames de invencibilidade.
- Inventário/itens: mais tipos de flasks, buffs temporários, armas secundárias.
- Progressão de salas: geração procedural de salas, portas condicionais por objetivos, spawn de mini-boss com recompensas específicas.
- Persistência: salvar stats do player (level, XP) e progresso de salas.
- Otimização: pooling de inimigos/projetis, checagem de colisão em batches.

## Exemplos Rápidos
- Dar XP ao matar outro tipo de inimigo:
  ```gdscript
  # no inimigo
  @export var exp_reward := 5
  func _reward_player():
      var player = get_tree().get_first_node_in_group("player")
      if player and player.has_method("gain_experience"):
          player.gain_experience(exp_reward)
  ```

- Criar stats para um novo player:
  1. New Resource → CharacterStats.
  2. max_health = 8, current_health = 8, move_speed = 140, damage = 2, experience_to_next = 10.
  3. Atribuir no export `stats` do novo player no editor.

- Adicionar drop custom na Crate:
  - Selecione a Crate na cena → `drop_scenes` → adicione `flask_red_node_2d.tscn` e/ou outra cena. Deixe vazio para não dropar nada.

- Configurar nova sala/porta:
  - Crie `Room4Spawn` em Room4.
  - Na porta da sala anterior, setar `next_spawn_path = "../Room4/Room4Spawn"` e `required_keys` conforme necessário.

## Checklists Rápidos
- Se inimigos não spawnam: verifique se a cena de inimigo é válida no spawner, se há SpawnPoints e se shapes em `enemy_character_body_2d.tscn` estão corretos.
- Se porta não teleporta: confirme `next_spawn_path`, nome do spawn na próxima sala, e que o player tem chaves suficientes.
- Se HUD não atualiza: sinais `health_changed`, `keys_changed`, `leveled_up` devem estar conectados via script do player; `player_hud` espera esses sinais.
