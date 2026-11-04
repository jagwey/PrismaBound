# Enemies and bosses

`scripts/enemy.gd` (`PrismEnemy`): `configure(type, region, is_boss, start_phase)` sonra `add_child`. Tüm saldırılar görünür bir hazırlık (telegraph) ile başlar: normal 0.65 s, boss 0.8 s.

## Normal düşmanlar (tek vuruş)
Türler `TYPE_IDS`: `shooter` (düz atış), `feint` (gecikmeli aldatma), `spread` (açılı yelpaze), `armored` (zırhlı: önden gelen yansıyan mermiyi geri çevirir; arkadan yansıma veya fırlatılan kalkan öldürür), `beam` (tekrarlı ışın), `melee` (yakın dövüş). Yansıyan mermi veya fırlatılan kalkan (`hit_by`) öldürür. Oyuncudan 740 px uzakta uyur.

## Boss'lar
`PrismEnemy.BOSS_HITS[region]` = [3, 4, 4, 5, 5]. Her `hit_by` 1 vuruş sayar (yansıyan mermi veya fırlatılan kalkan); art arda sayılmaması için 0.25 s `BOSS_HIT_GUARD`. Faz artınca 0.8 s sersemler. `hits_left`, `phase`, `display_name` HUD için açıktır. Faz sınırları `phase_for_hits`; faz değişince `phase_changed(phase)`, oda bunu `boss_phase_reached` ile iletir ve ölümden sonra o fazdan devam eder.

## Durum makinesi
IDLE, PATROL, DETECT, TELEGRAPH, ATTACK, RECOVER, STUNNED, DEAD. `defeated(enemy)` bir kez yayılır; 0.55 s parça animasyonundan sonra düğüm silinir.

## Test
`godot --headless --path . --script tests/enemy_test.gd` (178 kontrol): yapılandırma, telegraph süreleri, tür davranışları, boss vuruş sayıları ve fazlar, temizlik. Sabit zamanlama düzenekleridir; denge veya insan testi kanıtı değildir.
