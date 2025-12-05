# Implementação: Inimigo sem dano após morte (2025-12-05)

## Objetivo
Garantir que inimigos não causem **qualquer** dano após morrer, mesmo durante o curto período de animação/efeitos antes de serem removidos da cena.

## Arquivos alterados
- `entities/Enemies/enemy_character_body_2d.gd`

## Mudanças principais
 - Ao morrer:
   - Desabilita `monitoring` e `monitorable` de `ContactArea2D` e `HitBoxArea2D` via `set_deferred`.
   - Desconecta sinais `body_entered` e `body_exited` da `ContactArea2D` para evitar callbacks enfileirados.
   - Zera `collision_layer` e `collision_mask` do `CharacterBody2D` para evitar overlaps físicos.
   - Chama `set_physics_process(false)` para parar `_physics_process` e a lógica de contato.
   - Limpa `_contact_targets.clear()` para remover alvos enfileirados.
   - Reduz a janela de remoção para `0.6s` antes de `queue_free()`.

## Trecho relevante
```
_is_dead = true
if _contact_area:
  _contact_area.set_deferred("monitoring", false)
  _contact_area.set_deferred("monitorable", false)
  if _contact_area.body_entered.is_connected(_on_contact_body_entered):
    _contact_area.body_entered.disconnect(_on_contact_body_entered)
  if _contact_area.body_exited.is_connected(_on_contact_body_exited):
    _contact_area.body_exited.disconnect(_on_contact_body_exited)
if _hit_box:
  _hit_box.set_deferred("monitoring", false)
  _hit_box.set_deferred("monitorable", false)
collision_layer = 0
collision_mask = 0
set_physics_process(false)
_contact_targets.clear()
```

## Racional
Mesmo com `monitoring` desabilitado, eventos já enfileirados em frames anteriores podem disparar. Desativar camadas de colisão e processamento físico, além de limpar a lista de contatos, garante a interrupção completa de qualquer interação danosa pós-morte.

## Validação
- Matar um inimigo e confirmar que nenhum dano é aplicado ao jogador após a morte.
- Verificar que sfx/animações de morte continuam funcionando até `queue_free()`.

## Próximos passos
- Opcional: padronizar este fluxo para todas as variantes de inimigos.
- Adicionar testes manuais/automáticos para cobrir interações de contato durante animações de morte.
