# PRISMBOUND — Torimon

Godot 4.7.2 / GDScript / Windows / Türkçe. Bu depo, beş bölümlü oynanabilir ilk geliştirme sürümüdür. Nihai 3–5 saatlik oyun olarak doğrulanmamıştır.

## Çalıştırma

- Windows: `builds/PRISMBOUND.exe` dosyasını aç.
- Düzenleme: Godot 4.7.2 ile `project.godot` dosyasını aç, F6 yerine F5 ile ana oyunu başlat.
- Bağımlılık: Godot dışında ek paket gerekmez; Windows çalıştırılabilir dosyası motor kurulumunu gerektirmez.

## Kontroller

A/D hareket; Space zıplama; Shift atılma. Fare kalkanı yönlendirir. Sağ fare savunma, sol fare zamanlamalı yansıtma; F kalkan itişi. Q ayna değiştirir. R basılıyken savunarak enerji depola; C ile bırak. E sunak/çıkış/etkileşim. Esc duraklatır. Ayarlardan klavye ve fare atamalarını değiştirebilirsin.

Gamepad: sol analog hareket, sağ analog kalkan, RT savunma, RB yansıtma, A zıplama, B atılma, Y ayna değiştirme, X etkileşim, LB itiş, LT depolama, yukarı yön enerji bırakma. Fiziksel gamepad testi henüz yapılmadı.

## Oynanış

Kalkanı gelen mermiye çevir; mermi yaklaşırken yansıt. Arkadan gelen saldırı engellenmez. Başarılı yansıtma düşmanı kendi saldırısıyla vurur. Altı kalkan modu ilerledikçe açılır. Sunaklar canı yeniler ve ilerlemeyi kaydeder. Parçalarla direnç geliştir. Bölge bulmacasını çöz, boss'u yen, çıkışta E'ye bas.

## Kayıt

`user://prismbound_save.json`, doğrulanan önceki kayda ait yedek ve ayrı ayar dosyası. Windows'ta normal konum `%APPDATA%/Godot/app_userdata/PRISMBOUND/`. Yeni oyun mevcut ilerlemenin üzerine kaydeder. Kayıt yükleme bozuk ana dosyada yedeği dener.

## Doğrulama

Godot konsol çalıştırıcısıyla:

```
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/core_test.gd
godot --headless --path . --script tests/enemy_test.gd
godot --headless --path . --script tests/world_test.gd
godot --headless --path . --script tests/integration_test.gd
godot --headless --path . --export-release "Windows Desktop" builds/PRISMBOUND.exe
```

Yerel çalıştırılabilir dosyanın adı `Godot_v4.7.2-stable_win64_console.exe` olabilir. Test sonuçları ve kalan kapsam `docs/STATUS.md` içinde tutulur.

## Varlıklar

Görseller oyun koduyla oluşturulan özgün geçici piksel geometridir. Sesler ve bölge/boss döngüleri `audio_manager.gd` içinde özgün dalga senteziyle üretilir; geçici besteler sayılır. Üçüncü taraf oyun görseli/sesi kullanılmaz. Son sanat üretimi, animasyon atlasları ve beste kalitesi henüz tamamlanmadı.
