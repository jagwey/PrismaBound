# World, rooms and flow

## Odalar
`data/rooms.json`: 5 bölüm, her oda tek ekran (en çok 640x360) `id, size, spawn, exit, solids, enemies, boss`. `PrismRoom` zemini, oyuncuyu ve düşmanları kurar; tüm düşmanlar ölünce `cleared`, çıkışa 24 px yaklaşınca `exited`. `elapsed` gerçek zamanla sayılır (yavaşlatma süreyi şişirmez). Orman: forest_1..forest_5 + forest_boss.

## PrismWorld (`scripts/world.gd`)
`configure(chapter, start_room)` sonra `add_child`. Sinyaller: `room_completed(room_id, time)`, `chapter_completed(chapter)`, `story_requested(key)` (boss odasına girince `boss_N`), `player_died`. `restart_room()` odayı yeniden kurar (yeni oyuncu düğümü); `room`, `room_index`, `deaths`, `time_control`, `player`, `boss` açıktır. `_exit_tree` zaman ölçeğini 1.0'a döndürür.

## Ana akış (`scripts/main.gd`)
Yeni oyun: `intro` -> `region_0` -> bölüm 0 ... bölüm 4 boss'u -> `ending_a` -> jenerik. Devam: `unlocked_chapter`, oda 0. Ölüm: "ÖLDÜN — R / tık: tekrar", 0.3 s sonra girdi, 1.0 s'de otomatik yeniden kurulum (ağaç duraklatılmaz). Ölüm sayısı bellekte artar.

## Kayıt (`PrismSave`, şema v2)
`version, unlocked_chapter, best_times, total_deaths`. Yalnızca oda tamamlanınca (en iyi süre) ve bölüm bitince (`unlocked_chapter = max(mevcut, bölüm+1)`, en çok 4) yazılır. v1 kayıt göç edilir; bozuk dosyada yedek denenir.

## Test
`room_test.gd` (74), `save_test.gd` (31), `integration_test.gd` (girdi, yeni oyun, oda kaydı, ölüm, v1 devam, duraklatma, bitiş). Elle oynanış testi bekliyor.
