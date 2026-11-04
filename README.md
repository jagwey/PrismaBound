# PRISMBOUND — Torimon

Godot 4.7.2 / GDScript / Windows / Türkçe. Bu depo, Katana Zero tarzı tek vuruşluk oda tabanlı aksiyon oyununun geliştirme sürümüdür. Nihai 3–5 saatlik oyun olarak doğrulanmamıştır.

## Çalıştırma

- **İndir (Windows):** [Releases](https://github.com/jagwey/PrismaBound/releases/latest) sayfasından `PRISMBOUND_Windows.zip` dosyasını indir, aç ve `PRISMBOUND.exe`'yi çalıştır. Kurulum gerekmez.
- Yerel derleme: `builds/PRISMBOUND.exe` (export ile üretilir, depoya eklenmez).
- Düzenleme: Godot 4.7.2 ile `project.godot` dosyasını aç, F6 yerine F5 ile ana oyunu başlat.
- Bağımlılık: Godot dışında ek paket gerekmez; Windows çalıştırılabilir dosyası motor kurulumunu gerektirmez.

## Kontroller

A/D hareket; Space zıplama; Sol Ctrl atılma. Sol fare yansıtma (mermi yaklaşırken); sağ fare kalkan fırlatma (fare yönüne). Shift basılı tutulunca zaman yavaşlar. R odayı yeniler (öldükten sonra da R veya tık). E etkileşim. Esc duraklatır. Ayarlardan klavye ve fare atamalarını değiştirebilirsin.

Gamepad: sol analog hareket, sağ analog nişan, RB yansıtma, RT fırlatma (LB de fırlatır), LT yavaşlatma, A zıplama, B atılma, X etkileşim, Y odayı yenile, Start duraklatma. Fiziksel gamepad testi henüz yapılmadı.

## Oynanış

Tek vuruşta ölürsün; düşmanlar da öyle. Mermiyi tam zamanında yansıt, kalkanı fırlat, yakala, gerekirse zamanı yavaşlat. Her oda tek ekran: tüm düşmanları temizle, çıkışa git. Süre ve en iyi süre gösterilir. Bölüm sonunda çok vuruşlu boss var. Beş bölümün tamamı oynanabilir (Orman, Maden, Kale, Tapınak, Prizma; her biri 5 oda + boss), odalar `data/rooms.json` içinde.

## Kayıt

`user://prismbound_save.json` (şema v2: açılan bölüm, oda en iyi süreleri, toplam ölüm), yedek ve ayrı ayar dosyası. Kayıt yalnız oda/bölüm tamamlanınca yazılır. Windows'ta normal konum `%APPDATA%/Godot/app_userdata/PRISMBOUND/`. Yeni oyun mevcut ilerlemenin üzerine kaydeder. Kayıt yükleme bozuk ana dosyada yedeği dener.

## Doğrulama

Godot konsol çalıştırıcısıyla (`godot` yerine `Godot_v4.7.2-stable_win64_console.exe` olabilir):

```
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/core_test.gd
godot --headless --path . --script tests/enemy_test.gd
godot --headless --path . --script tests/save_test.gd
godot --headless --path . --script tests/room_test.gd
godot --headless --path . --script tests/integration_test.gd
godot --headless --path . --quit-after 600 -- --smoke
godot --headless --path . --export-release "Windows Desktop" builds/PRISMBOUND.exe
```

Testler mekanik/akış doğrulamasıdır; elle oynanış testi ayrıca gerekir.

## Varlıklar

Görseller oyun koduyla oluşturulan özgün geçici piksel geometridir. Sesler ve bölge/boss döngüleri `audio_manager.gd` içinde özgün dalga senteziyle üretilir; geçici besteler sayılır. Üçüncü taraf oyun görseli/sesi kullanılmaz. Son sanat üretimi, animasyon atlasları ve beste kalitesi henüz tamamlanmadı.
