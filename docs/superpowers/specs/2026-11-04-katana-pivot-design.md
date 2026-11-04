# PRISMBOUND — Katana Zero tarzı pivot (tasarım)

Tarih: 2026-11-04 · Durum: kullanıcı incelemesinde

## Amaç

PRISMBOUND'u metroidvania-lite yapıdan, Katana Zero benzeri **tek vuruşta ölümlü, kısa odalı, hızlı yeniden denemeli** bir aksiyon oyununa çevirmek. Kılıç yerine kalkan: düşman ya **kendi yansıyan mermisiyle** ya da **fırlatılan, sekip dönen kalkanla** ölür.

Başarı ölçütü: Orman bölümü (4–6 oda + boss) baştan sona oynanabilir; ölüm → oda yeniden başlama 0.5 sn altında; tüm yeni mekanikler headless testlerle doğrulanmış.

## Kullanıcı kararları

- Derinlik: tam pivot.
- Öldürme: yansıtma + kalkan fırlatma (sekme). Kalkan darbesi/itme ve çevresel öldürme yok.
- Ek özellikler: zaman yavaşlatma, oda süresi/skor, bölümler arası diyalog.
- Replay ilk sürümde yok.
- Boss: çok vuruşlu, fazlı; oyuncu tek can, ölünce faz başından.

## Kaldırılan sistemler

HP/stamina/enerji, guard (basılı savunma) ve guard break, 6 kalkan modu (Q), element durumları (yanma/yavaşlama/zehir), absorb/release (R/C), parça ve yükseltmeler, sunak/checkpoint, düşme hasarı, çoklu son seçimi (`show_altar`, `show_final_choice`). İlgili testler silinir.

## Çekirdek döngü

1. Bölüm = 5 bölgeden biri (Orman, Maden, Kale, Tapınak, Prizma); her bölüm 4–6 oda + boss odası.
2. Oda tek ekran ya da en fazla ~2 ekran genişliği (640×360 iç çözünürlük).
3. Oyuncu veya düşman tek vuruşta ölür. Oyuncu ölünce "ÖLDÜN — tekrar için R / tık" ve 0.3 sn sonra oda baştan kurulur (otomatik de başlar 1.0 sn sonra).
4. Odadaki tüm düşmanlar ölünce çıkış kapısı açılır; kapıya girince sonraki oda.
5. Bölüm sonunda boss. Boss 3–5 yansıtılmış vuruşla ölür (faz başına 1–2 vuruş). Oyuncu ölünce boss mevcut fazın başından yeniden başlar.
6. Bölüm bitince diyalog sahnesi, ardından sonraki bölüm.

## Oyuncu fiilleri

| Fiil | Girdi (klavye/fare) | Gamepad | Kural |
|---|---|---|---|
| Hareket | A/D | Sol analog | Mevcut ivme, coyote 0.10 s, jump buffer 0.13 s korunur |
| Zıplama | Space | A | Değişmez |
| Atılma | Ctrl (sol) | B | Kısa dokunulmazlık; mevcut cooldown |
| Nişan | Fare | Sağ analog | Kalkan nişan yönünde durur |
| Yansıtma | Sol tık | RB | 0.20 s pencere, 0.30 s cooldown. Pencere içinde önden gelen mermi nişan yönüne yansır, sahibi oyuncu olur. Yansıyan mermi düşmanı tek vuruşta öldürür (boss hariç: 1 hasar). Arkadan gelen mermi öldürür |
| Kalkan fırlatma | Sağ tık | RT | Kalkan nişan yönünde 420 px/s ile uçar, duvar/zeminden **en fazla 3 kez** seker (yansıma vektörü), değdiği düşmanı öldürür ve uçmaya devam eder. 3. sekmeden sonra ya da 1.2 s sonra oyuncuya döner; tekrar sağ tık ile erken çağırılır. **Kalkan havadayken yansıtma yapılamaz** |
| Zaman yavaşlatma | Shift (basılı) | LT | Oyun hızı %30. Bar 3.0 s; kullanılmazken 1.5 s gecikmeden sonra 2 s'de dolar. Oyuncu hareketi de yavaşlar (Katana Zero gibi) |
| Oda yeniden başlat | R | Y | Elle reset |
| Duraklat | Esc | Start | |

Tuşlar mevcut ayarlar ekranından değiştirilebilir kalır.

## Düşmanlar

Hepsi tek vuruşta ölür. Mevcut durum makinesi (idle/patrol/detect/telegraph/attack/recover/dead) korunur; HP, element ve stun dalları kaldırılır.

- **Atıcı** — düz tek mermi; temel öğretici.
- **Aldatıcı** — sahte hamle sonra atış; zamanlama sınar.
- **Yelpaze** — 3'lü açılı atış; açı seçimi sınar.
- **Zırhlı** — önden zırhlı: yansıyan mermi önden onu öldürmez, arkadan ya da kalkan fırlatma sekmesiyle ölür.
- **Işıncı** — ardışık ışın parçaları; yavaşlatma kullanımını öğretir.
- **Yakın dövüşçü** — mermisi yok, oyuncuya koşup vurur. Yalnız fırlatılan kalkanla ya da başka düşmanın yansıyan mermisiyle ölür.

Hayalet/görünmezlik (Tapınak) ve element tipleri kaldırılır. Boss'lar mevcut desenlerini korur ama hasar = "vuruş sayısı" (3–5), faz geçişleri vuruşa bağlanır; elementsiz.

## Oda verisi

`data/rooms.json`: bölüm → oda listesi. Her oda:

```json
{ "id": "forest_1", "size": [640, 360], "spawn": [40, 300], "exit": [600, 300],
  "solids": [[0, 320, 640, 40], [260, 240, 120, 16]], "enemies": [{"type": "shooter", "pos": [400, 300], "facing": -1}], "dialogue": null }
```

Boss odası `"boss": "forest"` alanı taşır. `data/regions.json` yalnız palet/parallax/isim için kalır.

## Skor ve kayıt

- HUD: oda süresi (sn.ss), bölüm ölüm sayısı, zaman yavaşlatma barı.
- Oda bitince küçük özet: süre, en iyi süre.
- Kayıt (`save_manager.gd`, mevcut yedekli yazım korunur): `unlocked_chapter`, `best_times{room_id: float}`, `total_deaths`. Eski kayıt biçimi okunursa sessizce yeni biçime çevrilir (yalnız açılan bölge → `unlocked_chapter`).
- Kayıt yalnız oda/bölüm bitiminde yazılır.

## Hikaye

`dialogues_tr.json` mevcut anahtarları (`intro`, `region_N`, `victory_N`) bölüm başı/sonu sahnesi olarak kullanılır. Seçim (`choice`) ve çoklu son kaldırılır; tek son.

## Mimari

| Dosya | Sorumluluk |
|---|---|
| `scripts/player.gd` | Hareket, yansıtma, kalkan fırlatma başlatma, ölüm sinyali. ~250 satır hedef |
| `scripts/thrown_shield.gd` (yeni) | Uçan kalkan: sekme, düşman öldürme, geri dönüş |
| `scripts/time_control.gd` (yeni) | Yavaşlatma barı ve `Engine.time_scale`; saf mantık test edilebilir |
| `scripts/projectile.gd` | Element/patlama/absorb kaldırılır; sahiplik + yansıma kalır |
| `scripts/enemy.gd` | Tek vuruş, zırh yönü, yakın dövüşçü; boss vuruş sayacı |
| `scripts/room.gd` (yeni) | `rooms.json`'dan oda kurar, düşman sayar, çıkışı açar, reset |
| `scripts/world.gd` | Bölüm akışı: oda sırası, boss, diyalog tetikleme (sadeleşir) |
| `scripts/main.gd` | Menü, HUD, duraklatma, ayarlar, diyalog; sunak/son seçimi silinir |
| `scripts/save_manager.gd` | Yeni kayıt şeması + eski biçim göçü |

Reset tasarımı: oda düğümü `queue_free` edilip aynı veriden yeniden kurulur (durum taşınmaz → deterministik ve hatasız reset).

## Hata durumları

- `rooms.json` okunamazsa: menüde hata mesajı, oyun çökmez.
- Kalkan oda dışına çıkarsa / sıkışırsa: 1.2 s zamanlayıcı onu oyuncuya zorla döndürür.
- Zaman yavaşlatma aktifken duraklatma/ölüm: `time_scale` 1.0'a döner.

## Test planı (headless)

- `core_test.gd` (yeniden yazılır): tek vuruş ölüm; önden yansıtma yön ve sahiplik; arkadan ölüm; kalkan havadayken yansıtma yok; kalkan 3 sekme + geri dönüş; erken çağırma; zaman barı tükenme/dolma; ölümde `time_scale` sıfırlama.
- `enemy_test.gd`: her tipin tek vuruşla ölmesi; zırhlı önden yansıtmaya dayanıklı, kalkana değil; yakın dövüşçü yansıtmaya dayanıklı değil ama yalnız kalkan/dost ateşiyle ölür; boss vuruş sayacı ve faz reset.
- `world_test.gd` → oda testleri: `rooms.json` şema doğrulama; düşmanlar ölünce çıkış açılır; ölüm sonrası reset temiz (düşman sayısı ve mermiler sıfır); oda sırası ilerler.
- `integration_test.gd`: menü → bölüm 1 → oda temizle → kayıt yazılır → eski kayıt göçü.

## Kapsam ve sıra

1. Çekirdek: player + projectile sadeleştirme, tek vuruş, yansıtma (testlerle).
2. Kalkan fırlatma + zaman yavaşlatma.
3. Düşman sadeleştirme + yakın dövüşçü/zırhlı.
4. Oda sistemi + Orman bölümü 5 oda + boss.
5. HUD/skor/kayıt/diyalog.
6. Kalan 4 bölüm odaları (her biri 4–6 oda), export.

Replay, kalkan darbesi, çevresel öldürme, yeni sanat bu spec'in dışındadır.
