# PROGRESS

## Katana Zero tarzı pivot (2026-11-04)
- [x] Tasarım kararları alındı (tam pivot; yansıtma + kalkan fırlatma; zaman yavaşlatma; skor; diyalog; çok vuruşlu boss)
- [x] Spec: `docs/superpowers/specs/2026-11-04-katana-pivot-design.md`
- [x] Spec kullanıcı onayı
- [x] Uygulama planı: `docs/superpowers/plans/2026-11-04-katana-pivot.md` (8 görev) — onay bekliyor
- [x] 1. Çekirdek: player/projectile sadeleştirme, tek vuruş, yansıtma (core_test 52/0; enemy_test eski mekanikler yüzünden 1 fail, Görev 4 yeniden yazar)
- [ ] 2. Kalkan fırlatma + zaman yavaşlatma (slow meter ✓, fırlatılan kalkan `scripts/thrown_shield.gd` ✓ core_test 79/0)
- [ ] 3. Düşman sadeleştirme
- [ ] 4. Oda sistemi + Orman bölümü
- [x] 5. HUD/skor/kayıt/diyalog (Görev 7: main.gd yeniden yazıldı; integration_test 62/0; core 79/0 enemy 178/0 save 31/0 room 74/0; smoke temiz; elle F5 oynanış testi (Orman 1-5 + boss) KULLANICIDA BEKLİYOR; kayıt v2 + göç `save_manager.gd` ✓ save_test 23/0; main.gd minimal .get uyumu, Görev 7 yeniden yazar)
- [x] 8. Kalan bölümler (Maden/Kale/Tapınak/Prizma: 5 oda + boss) + diyalog metinleri yeni kontrollere uyarlandı; core 79/0 enemy 178/0 save 31/0 room 172/0 integration 62/0
- [ ] Export: `builds/PRISMBOUND.exe` YENİLENEMEDİ (Godot 4.7.2 Windows export şablonları yok: `export_templates/4.7.2.stable/windows_release_x86_64.exe`); builds/ içindeki exe eski sürüm
- [ ] Manuel oynanış testi bekliyor (F5: tüm bölümler + boss)

## Not
- Çalışma ağacında pivot öncesinden kalan commit'lenmemiş değişiklikler var (main.gd, audio_manager.gd, save_manager.gd, integration_test.gd vb.).
