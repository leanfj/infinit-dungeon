# Sistema de Mira Automática (Gamepad)

Data: 01/12/2025

## Resumo
Adicionado sistema de mira automática quando há um gamepad conectado. O player destaca o inimigo mais próximo e rotaciona a arma para mirar nele automaticamente.

## Arquivos
- `mechanics/aim/auto_aim.gd`: utilitário para localizar o inimigo mais próximo e aplicar destaque.
- `entities/player/player_character_body_2d.gd`: integração do auto-aim, detecção de gamepad e rotação da arma.

## Funcionamento
- Se houver qualquer gamepad conectado (`Input.get_connected_joypads()`), o sistema procura o inimigo mais próximo dentro de `auto_aim_radius`.
- O alvo atual é destacado (preferindo `set_highlighted(true)` no inimigo; senão, usando `modulate`).
- A arma (`_weapon_node`) rotaciona automaticamente para o alvo.

## Configurações (no Player)
- `auto_aim_enabled`: habilita/desabilita o sistema (default: true)
- `auto_aim_radius`: distância máxima para aquisição de alvo (default: 256)

## Requisitos nos Inimigos
- Adicionar os nós de inimigos ao grupo `enemies`.
- Opcional: implementar método `set_highlighted(is_on: bool)` para controle de efeito de destaque.
  - Caso não implementado, o fallback usa ajuste de `modulate` (amarelado leve).

## Como usar
- Garanta que seus inimigos estão no grupo `enemies`.
- Execute com um gamepad conectado; o player mirará e destacará o alvo mais próximo automaticamente.

## Próximos passos (opcional)
- Adicionar filtro de linha de visão e prioridade por ângulo.
- Implementar outline shader dedicado para destaque mais elegante.
- Trocar alvo apenas quando novo alvo for significativamente melhor para evitar flicker.
