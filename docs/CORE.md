# Core gameplay (Katana Zero pivot)

`PrismPlayer`, `PrismProjectile`, `PrismThrownShield`, `PrismTimeControl`, pure `PrismCombat` helpers. Programmatic placeholder art, no external packages.

## Player
- Tek vuruş: herhangi bir hasar oyuncuyu öldürür (`died`). Can, direnç, enerji, mod, yükseltme yok.
- Hareket: koşu 155 px/s, zıplama, coyote 0.10 s, zıplama tamponu 0.13 s, `dash` (i-frame'li).
- Yansıtma (`reflect`, sol fare): pencere 0.20 s, bekleme 0.30 s. Yansıyan hız = clamp(gelen * 1.2, 180, 650). Yansıyan mermi sahip/takım değiştirir; düşmanı öldürür, boss'a 1 vuruş sayılır.
- Kalkan fırlatma (`throw`, sağ fare): hız 420 px/s, en çok 3 sekme, 1.2 s dışarıda, sonra 520 px/s ile döner; 16 px içinde yakalanır. Fırlatılmışken yansıtma kapalı. Düşmana değince `hit_by` ile vurur.
- Zaman yavaşlatma (`slow`): `Engine.time_scale = 0.3`, ölçer 3.0 s, 1.5 s sonra dolmaya başlar, 2.0 s'de tamamen dolar (gerçek zaman). `PrismTimeControl.reset()` duraklatma, menü ve dünya çıkışında zorunlu.
- Nişan: fare, sağ çubuk (`aim_*`) veya 8 yön (`snap_aim`). `effects_intensity` 0..1 görsel efektleri kısar.

## Girdi ve olaylar
Eylemler: move_left move_right jump dash reflect throw slow restart interact pause aim_left aim_right aim_up aim_down. `combat_event(kind, position)` türleri: jump dash reflect throw catch death. Her odada yeni oyuncu düğümü kurulur; kancalar her kuruluşta yeniden bağlanır (`main.hook_player`).

## Test
`godot --headless --path . --script tests/core_test.gd` (79 kontrol): oyuncu, mermi, fırlatılan kalkan ve zaman kontrolü mekanikleri. İnsan oynanış testi değildir.
