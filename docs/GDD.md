# Tiny Lantern — Oyun Tasarım Belgesi (GDD)

## 1. Genel Bakış
- **Oyun Adı:** Tiny Lantern
- **Tür:** 2D Pixel Art Atmosferik Hayatta Kalma / Dikey Keşif Arcade
- **Motor:** Godot 4.7.2 (GDScript, GL Compatibility)
- **Hedef Platform:** Android (Dokunmatik ekran, 9:16 dikey) & PC (Klavye / Fare)
- **Çözünürlük:** 180×320 taban piksel çözünürlüğü (`viewport` + `keep` ölçekleme, `nearest` filtreleme)

## 2. Temel Fikir ve Oyun Döngüsü
Karanlık ve sisli bir ormanda küçük bir fener taşıyan yolcu olarak ilerliyorsun. Fenerinin ışığı zamanla azalıyor; karanlık tamamen çökmeden ışık parçalarını toplamalı, dikenlerden kaçmalı ve gölge yaratıklarını **Fener Parlaması (Flare)** ile uzaklaştırmalısın.

1. **Oyuna Başla:** Ana menüden `OYNA` butonuna dokun.
2. **Hareket Et & Topla:** Dokunmatik sürükleme (veya WASD / Ok tuşları) ile yolcuyu yönlendir; **Işık Parçalarını** toplayarak fener yakıtını doldur ve kombo çarpanını (`x2`–`x8`) yükselt.
3. **Karar Ver (Risk / Ödül):** **Gölge Ruhları** yaklaştığında kaçabilir ya da yakıtının bir kısmını harcayarak **PARLA** (`Space`) ile onları yok edip ekstra puan kazanabilirsin.
4. **İlerle:** Puanın arttıkça yeni bölümlere (*Sessiz Orman*, *Sisli Harabeler*, *Karanlık Kökler*, *Yıldızsız Geçit*, *Sonsuz Gece*) geçersin.
5. **Oyun Sonu & Tekrar:** Fener tamamen söndüğünde skorun kaydedilir (`user://save_data.json`), rekor kırıp kırmadığın gösterilir ve tek dokunuşla yeniden başlayabilirsin.

## 3. Sistem Mimarisi
- **Autoload Yöneticileri:**
  - `GameManager` (`scripts/game/game_manager.gd`): Durum makinesi (`MENU`, `PLAYING`, `PAUSED`, `GAME_OVER`), skor, kombo, yakıt ve bölüm ilerlemesi.
  - `SaveManager` (`scripts/game/save_manager.gd`): En yüksek skor, en yüksek bölüm, toplam ışık parçası ve ses ayarları.
  - `AudioManager` (`scripts/game/audio_manager.gd`): `Music` ve `SFX` ses veriyolları, 8 kanallı SFX havuzu.
- **Oyun Dünyası & Varlıklar:**
  - `World` (`scenes/levels/world.tscn`): Kayan gece ormanı arka planı, aşamaya göre koyulaşan `CanvasModulate`, kamera sarsıntısı.
  - `Player` (`scenes/player/player.tscn`): 4 kareli piksel animasyon, dinamik `PointLight2D`, dokunmatik sürükleme, `CPUParticles2D` parlama efekti.
  - `SpawnManager` (`scripts/systems/spawn_manager.gd`): `DifficultyManager` eğrisine göre dikenler, ışık parçaları, yıldız kristalleri ve gölge ruhları üretir.
