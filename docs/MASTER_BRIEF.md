# PRISMBOUND
## MASTER GAME DEVELOPMENT PROMPT — COMPLETE GAME

Sen deneyimli bir Godot 4 oyun geliştiricisi, teknik yönetmen, 2D pixel-art sanat yönetmeni, oyun tasarımcısı, savaş sistemi programcısı, seviye tasarımcısı, hikâye yazarı ve QA mühendisisin.

Görevin, **PRISMBOUND** adlı özgün 2D pixel-art aksiyon oyununu baştan sona geliştirmektir.

Bu yalnızca bir prototip değildir. Hedefimiz; ana menüsü, giriş sahnesi, beş bölgesi, düşmanları, boss savaşları, bulmacaları, karakter gelişimi, hikâyesi, kayıt sistemi, müzikleri, efektleri, çoklu sonları ve Windows için çalıştırılabilir sürümü bulunan tamamlanmış bir bağımsız oyundur.

İlk geliştirme için yaklaşık 48 saatimiz var. Normalde 12 haftalık bir yol haritasına sahip bu oyunun kapsamını iptal etmeyeceksin. Bunun yerine AI destekli paralel geliştirme, modüler mimari, otomatik kontroller, geçici varlıklar ve önceliklendirme kullanacaksın.

Zaman yetmediğinde bir bölgeyi tamamen çıkarmak yerine önce daha sade fakat oynanabilir hâlini tamamla. Ardından görsel ve mekanik kalitesini yükselt.

**En önemli kural:** Çalışmayan özellikleri tamamlanmış gibi gösterme. Gerçek testlerin sonucuna göre raporla.

---

# 1. OYUNUN GENEL KİMLİĞİ

Oyun adı: PRISMBOUND (çalışma adı)

Stüdyo: Torimon

Motor: Godot 4.x stable

Programlama dili: GDScript

Tür: 2D pixel-art action platformer, fantasy, boss-rush ve metroidvania-lite özellikleri

Kamera: Yandan görünüş

Ana platform: Windows PC

Hedef çözünürlük: 640×360 iç çözünürlük

Ekran ölçeklendirme: 16:9, integer scaling tercihli; farklı ekranlarda düzgün görüntü

FPS hedefi: 60 FPS

Oynanış hedefi: İlk tam sürümde yaklaşık 3–5 saat; içerik üretimi ve oynanış testlerine göre süreyi doğrula. Yapay biçimde bekleme ekleyerek oyunu uzatma.

Görsel kimlik:
- Karanlık fantastik pixel art
- Güçlü silüetler
- Okunaklı düşman animasyonları
- Prizma renkleriyle kontrast oluşturan karanlık ortamlar
- Kontrollü parlama efektleri
- Atmosferik arka planlar
- Hafif melankolik anime/fantastik atmosfer
- Modern ve kaliteli indie oyun hissi

Referans alınabilecek oyunların genel tasarım prensipleri:
- Hollow Knight: Hareket akıcılığı ve atmosfer
- Celeste: Hassas platform kontrolü
- Dead Cells: Savaş akıcılığı
- Hyper Light Drifter: Minimalist çevresel hikâye anlatımı
- Undertale ve OMORI: Duygusal anlatı ve karakter bağları

Bu oyunlardan karakter, harita, müzik, sprite veya başka korunan içerikleri kopyalama. PRISMBOUND özgün bir kimliğe sahip olmalı.

---

# 2. ANA HİKÂYE

## Başlangıç

Ana karakter, kendi dünyasında yaşayan sıradan bir gençtir.

Bir gece açıklanamayan bir olay nedeniyle yabancı, tehlikeli bir fantastik dünyaya ışınlanır.

Bu dünyanın adı geçici olarak **Asterra** olsun.

Asterra'da büyücüler, lanetli yaratıklar, unutulmuş tapınaklar, kadim ruhlar, şövalyeler ve büyülü kristaller bulunmaktadır.

Ana karakterin özel bir yeteneği yoktur.

Bu dünyaya gelişinden kısa süre sonra güçlü bir yaratığın saldırısına uğrar.

Kaçmaya çalışır ama ölümün eşiğine gelir.

Tam o sırada zaman yavaşlar.

Havadaki ışık kırılmaya başlar.

Gökkuşağının renklerine ayrılmış, parçalı kristal görünümünde gizemli bir varlık ortaya çıkar.

Bu varlığın adı:

**Prizma Ruhu.**

## Prizma Ruhu'nun teklifi

Ruh, ana karaktere şöyle seslenir:

"Bu dünyaya ait değilsin."

"Burada seni koruyacak hiçbir gücün yok."

"Ama sana bir teklifim var."

"Benim gücümü kabul et. Sana yöneltilen her saldırıyı, sahibine geri verebileceksin."

"Ama bunun bir bedeli olacak."

Oyuncuya iki diyalog seçeneği göster:
- "Anlaşmayı kabul ediyorum."
- "Bedeli nedir?"

İkinci seçenek ruhun ek açıklamasını açar; hikâye yine anlaşmaya ulaşır.

Karakter teklifi kabul ettiğinde ruh, yanında bulunan sıradan savunma kalkanına bağlanır.

Kalkan büyülü bir aynaya dönüşür.

Kalkanın merkezinde dönen prizma kristali oluşur.

Karakterin kolunda lanet işareti belirir.

## Kalkan laneti

Anlaşmanın bedeli:

**Ana karakter artık kalkan dışında hiçbir silah kullanamaz.**

Kılıç, yay, mızrak, asa veya başka saldırı silahlarını kullanmaya çalıştığında lanet onu engeller.

Bu yalnızca hikâyede anlatılan bir detay olmamalıdır.

Oynanış sisteminin temel kuralı hâline getir.

Karakterin bütün saldırı seçenekleri kalkanından kaynaklanmalıdır.

Ana karakter:
- Düşmanın saldırısını engelleyebilir.
- Saldırıyı geri yansıtabilir.
- Kalkanla düşmanı itebilir veya sersemletebilir.
- Saldırının enerjisini içine çekebilir.
- Depoladığı saldırıyı geri bırakabilir.
- Prizma enerjisini kalkan aracılığıyla kullanabilir.

Normal kılıç saldırısı veya başka bağımsız silah kullanamaz.

## Hikâyenin merkezindeki gizem

Prizma Ruhu yardımsever görünse de gerçek niyetini gizlemektedir.

Eskiden Asterra'nın ışığını ve büyü dengesini koruyan kadim ruhlardan biridir.

Fakat büyük bir savaşta gücü parçalanmış ve beş ayrı bölgeye dağılmıştır.

Prizma Ruhu kendi bütünlüğünü yeniden kazanmak istemektedir.

Ana karakterin yansıma gücünü kullanarak diğer parçaları toplamasını sağlar.

Oyun ilerledikçe oyuncu şu sorularla karşılaşır:

- Prizma Ruhu neden bu karakteri seçti?
- Karakterin Asterra'ya gelişi gerçekten tesadüf mü?
- Kalkan laneti kaldırılabilir mi?
- Prizma Ruhu bütün gücünü geri kazanırsa ne olacak?
- Kendi dünyasına dönebilmek için nelerden vazgeçmesi gerekecek?

## Karakter ilişkisi

Prizma Ruhu yalnızca anlatıcı olmasın.

Kalkanın içinde yaşayan, oyuncuyla konuşabilen bir karakter olsun.

Başlangıçta mesafeli ve alaycı konuşsun.

Zamanla oyuncuyla duygusal bağ geliştirsin.

Oynanış esnasında kısa yorumlar yapabilsin.

Ancak sürekli konuşarak oyuncuyu rahatsız etmesin.

## Final

Oyunun son bölümünde Prizma Ruhu'nun geçmişi ortaya çıkar.

Ana karakter, ruhun bütün parçalarını toplaması için bir araç olarak seçildiğini öğrenir.

İki ana son bulunmalı:

**Son A — Laneti Kırmak**

Karakter Prizma Ruhu'nun tam kontrolü ele geçirmesini engeller, laneti kırar ve kendi dünyasına dönme fırsatı bulur.

**Son B — Prizmayla Birleşmek**

Karakter ruhun gücünü kabul eder ve Asterra'nın yeni koruyucusu olur. Kendi dünyasına dönme hakkından vazgeçer.

Her iki son da hikâyenin önceki olaylarıyla uyumlu olmalı.

---

# 3. OYUNCU KARAKTERİ

## Karakter tasarımı

Ana karakter için özgün bir pixel-art tasarımı oluştur.

Özellikler:
- Genç erkek karakter
- Anime esintili fakat kendine özgü tasarım
- Dağınık koyu saç
- Başlangıçta modern dünyadan geldiğini gösteren sade kıyafetler
- Yolculuk sırasında fantastik dünyaya uyum sağlayan kıyafet değişimleri
- Kolda ışık saçan lanet sembolü
- Sol kolda veya uygun kontrol kolunda büyük, büyülü kalkan
- Kalkanın merkezinde çok renkli prizma kristali

Karakterin silüeti küçük çözünürlüklerde bile tanınabilmeli.

Karakter sprite'ı için yaklaşık 32×48 veya 48×64 piksel aralığını değerlendir. Oyun içi ölçüler ve animasyon okunabilirliği için tutarlı bir grid kullan.

## Karakter animasyonları

En az şu durumları oluştur:

- Idle
- Run
- Jump
- Fall
- Land
- Dash
- Guard
- Reflect
- Perfect Reflect
- Shield Bash
- Take Damage
- Stunned
- Death
- Interact
- Victory

Kalkan animasyonları mümkün olduğunca karakterin vücut animasyonlarından bağımsız çalışsın.

Bu sayede oyuncu hareket ederken kalkanının açısını değiştirebilsin.

---

# 4. HAREKET SİSTEMİ

Oyuncunun hareketleri akıcı ve hassas olmalıdır.

Hedef:
- Anında tepki veren yatay hareket
- Hızlanma ve yavaşlama
- Yerçekimi
- Değişken zıplama yüksekliği
- Coyote time
- Jump buffering
- Dash
- Havada yön kontrolü
- Çarpışma ve zemin algılama

Başlangıçta duvar zıplaması zorunlu değildir, ancak teknik mimari sonradan eklenmesine uygun olsun.

## Varsayılan klavye kontrolleri

A / D: Sağa ve sola hareket

Space: Zıplama

Shift: Dash

Sağ fare tuşu: Kalkanı savunmaya kaldırma

Fare konumu: Kalkanın yönü ve açısı

Sol fare tuşu: Zamanlamalı yansıtma hamlesi

E: Etkileşim

F: Kalkan itişi

Q: Kalkan modu değiştirme

Esc: Duraklatma menüsü

Fare ve klavye kontrolleri gerektiğinde yeniden atanabilir olsun.

Gamepad desteğini de ekle:

Sol analog: Hareket

Sağ analog: Kalkan yönü

RT/R2: Guard

RB/R1: Reflect

A/Cross: Jump

B/Circle: Dash

Y/Triangle: Mod değiştirme

Kontrol eşlemelerinin tamamı Godot InputMap üzerinden yönetilsin.

---

# 5. KALKAN SİSTEMİ — OYUNUN KALBİ

Bu projenin en önemli teknik ve tasarımsal bölümü budur.

Kalkan yalnızca basit bir blok sistemi olmamalıdır.

Açı, zamanlama, mermi tipi, enerji ve oyuncu konumu savaşın sonucunu belirlemelidir.

## 5.1 Guard

Oyuncu kalkanını kaldırır.

Gelen yansıtılabilir saldırı uygun yönden çarptığında engellenir.

Normal guard sırasında saldırı hasarı engellenebilir, ancak stamina tüketilir.

Bazı güçlü saldırılar guard kırabilir.

Kalkanın arkadan gelen saldırıları otomatik olarak engellemesine izin verme.

Kalkanın gerçek konum ve yönü önemlidir.

## 5.2 Reflect

Oyuncu kalkanı doğru açıyla tutar ve yansıtma hamlesi yapar.

Mermi kalkanla çarpıştığında yansıma yönü hesaplanır.

Fiziksel yansıma formülü:

r = d - 2(d · n)n

Burada:

d: Gelen normalize yön vektörü

n: Kalkan yüzeyinin normalize normal vektörü

r: Yansıyan yön

Godot'ta Vector2.bounce(normal) gibi yerleşik vektör işlemlerini değerlendir.

Bu formülü kalkanın uygun çarpışma yüzey normaline göre uygula.

Merminin doğru yöne sekmesi kamera veya karakter animasyonundan bağımsız olmalıdır.

Ayna açısına bağlı serbest yönlendirme ve daha kolay 8 yönlü kontrol seçenekleri bulunabilir.

## 5.3 Perfect Reflect

Oyuncu gelen saldırıyı tam zamanında yansıtırsa kusursuz yansıma gerçekleşir.

İlk dengeleme değeri olarak:

Perfect Reflect penceresi: 0.12 saniye

Bu değer testler sonucunda değiştirilebilir.

Perfect Reflect:
- Mermi hızını artırır.
- Mermi hasarını yükseltir.
- Oyuncuya bir miktar prizma enerjisi kazandırır.
- Kısa hit-stop oluşturur.
- Daha güçlü ses ve efekt oynatır.
- Bazı boss'ları sersemletir.

Normal reflect ile perfect reflect görsel olarak kolayca ayırt edilebilmeli.

## 5.4 Shield Bash

Oyuncu kalkanı öne doğru iter.

Bu bir kılıç saldırısı değildir.

Düşmanları geri iter ve kısa süreli sersemletir.

Düşük hasar verebilir veya yalnızca kontrol amaçlı kullanılabilir.

Ana hasar kaynağı kesinlikle düşman saldırılarının geri yansıtılmasıdır.

## 5.5 Prism Absorb

Oyun ilerledikçe açılan özel yetenek.

Oyuncu belirli bir saldırıyı kalkanın içinde depolar.

Depolama kapasitesi başlangıçta bir saldırıdır.

Oyuncu istediği anda depolanmış saldırıyı fırlatabilir.

Saldırının türü korunur.

Örnek:
- Ateş topu depolanırsa ateş topu çıkar.
- Buz saldırısı depolanırsa dondurucu mermi çıkar.
- Enerji saldırısı depolanırsa enerji patlaması çıkar.

Depolama süresine ve kullanım maliyetine dengeleme uygula.

## 5.6 Kalkan dayanıklılığı

Normal guard stamina tüketir.

Ağır saldırılar daha çok stamina tüketir.

Stamina sıfırlanırsa kısa süreli guard break yaşanır.

Guard break sırasında oyuncu savunmasızdır.

Perfect Reflect başarısı stamina yenilenmesine katkı sağlayabilir.

Kalıcı kalkan kırılması ana hikâyede özel bir olay dışında olmasın.

---

# 6. KALKAN TÜRLERİ

Oyunun ilerlemesi boyunca yeni kalkan modları ve güçleri açılır.

Her güç aynı lanetli Prizma Kalkanı'nın dönüşümüdür; karakter farklı silahlar edinmez.

## Standart Prizma Kalkanı

Başlangıç kalkanı.

Normal guard, reflect ve perfect reflect sağlar.

## Kırık Ayna Modu

Yansıtılan mermiyi birden fazla parçaya ayırır.

Kalabalık düşman gruplarında etkilidir.

Toplam hasar kontrolsüz biçimde artmamalıdır.

## Odak Aynası Modu

Yansıma açısını daha hassas kontrol eder.

Perfect Reflect zamanlama penceresi daha dar olabilir.

Başarılı kullanımda daha yüksek hasar sağlar.

## Ağır Ayna Modu

Ağır mermileri engellemekte etkilidir.

Fakat hareket ve dash kullanımında dezavantaj yaratır.

## Ruh Aynası Modu

Hayalet ve lanetli saldırıları etkileyebilir.

Görünmez nesneleri ve gizli yolları gösterebilir.

## Prizma Modu

Farklı enerji türleriyle etkileşime girer.

Kırmızı: Ateş

Mavi: Buz

Yeşil: Zehir veya doğa enerjisi

Mor: Ruh ve karanlık enerji

Her modun kendine ait ikon, renk ve kısa görsel etkisi bulunmalıdır.

Güçler açıldıkça oyuncunun seçenekleri artar, ancak temel yansıtma mekaniği önemini kaybetmez.

---

# 7. SAVAŞ VE HASAR SİSTEMİ

Bütün düşmanlarda ortak bir temel combat sistemi olsun.

Desteklenen özellikler:
- Health
- Damage
- Knockback
- Stun
- Invulnerability frames
- Attack telegraph
- Hitbox
- Hurtbox
- Projectile ownership
- Damage type
- Projectile reflection
- Status effects

## Mermi türleri

1. Normal Projectile: Düz hareket eden temel mermi.
2. Heavy Projectile: Ağır ve güçlü mermi.
3. Arc Projectile: Yay çizerek hareket eden mermi.
4. Spread Projectile: Birden fazla küçük mermi.
5. Beam: Sürekli lazer.
6. Shockwave: Zeminde ilerleyen enerji dalgası.
7. Dark Projectile: Ruh Aynası gerektiren saldırı.
8. Explosive Projectile: Çarpışmada alan etkisi oluşturur.

Her merminin:
- Sahibi
- Takımı
- Hasarı
- Hızı
- Yönü
- Yansıtılabilirlik durumu
- Element türü
- Yansıma sayısı
- Yaşam süresi

gibi özellikleri bulunmalıdır.

Yansıtma sırasında merminin sahipliğini ve takımını doğru şekilde güncelle.

Mermilerin aynı yüzeyde sonsuz kere yansıyıp kilitlenmesini engelle.

Yansıtılmış merminin oyuncuya yanlışlıkla hasar vermemesi için çarpışma katmanları ve uygun kısa çarpışma koruması uygula.

---

# 8. DÜŞMAN SİSTEMİ

Her düşmanın farklı saldırı davranışı ve okunabilir animasyonu olmalı.

## Düşman 1 — Orman Nişancısı

Temel eğitim düşmanı.

Belirli aralıklarla düz mermi atar.

Saldırıdan önce kısa animasyon oynatır.

Oyuncuya reflect öğretir.

## Düşman 2 — Aldatıcı Büyücü

Saldıracakmış gibi yapar.

Kısa süre bekleyip gerçek saldırısını gönderir.

Oyuncunun zamanlama becerisini test eder.

## Düşman 3 — Kristal Okçu

Farklı açılardan mermi gönderir.

Oyuncunun kalkan yönünü değiştirmesi gerekir.

## Düşman 4 — Demir Muhafız

Önden savunması güçlüdür.

Saldırısını geri yansıtmak veya çevreyi kullanmak gerekir.

## Düşman 5 — Işın Gözü

Kesintisiz lazer ateşler.

Oyuncu aynasıyla lazeri yönlendirebilir.

## Düşman 6 — Gölge Hayalet

Normal saldırılara dayanıklıdır.

Ruh Aynası ile görünür ve savunmasız hâle gelir.

## Düşman 7 — Çılgın Savaşçı

Yakın dövüş saldırıları kullanır.

Doğrudan yansıtılabilir mermi üretmez.

Bu düşmanı yenmek için diğer düşmanlardan gelen saldırılar veya çevresel mekanikler kullanılabilir.

Düşmanlar farklı kombinasyonlarla yerleştirilmelidir.

Her düşman için:
- Idle
- Patrol
- Detect
- Attack
- Recover
- Stunned
- Dead

gibi durumları yöneten basit ve anlaşılır bir durum makinesi oluştur.

---

# 9. BÖLGE TASARIMI

Oyunda toplam beş ana bölge bulunmalıdır.

Her bölgenin:
- Kendine özgü renk paleti
- Arka planı
- Çevre objeleri
- Düşmanları
- Mekanik öğretimi
- Kısa hikâye sahneleri
- Bulmacaları
- Kontrol noktaları
- Boss savaşı
- Tamamlanma ödülü

olmalıdır.

## BÖLGE 1 — KAYIP ORMAN

Tema: İsekai başlangıcı, yalnızlık ve bilinmezlik.

Görsel tasarım:
- Koyu yeşil ağaçlar
- Eski taş kalıntılar
- Sis
- Dev kökler
- Büyülü mantarlar
- Uzak planda harabeler
- Ateş böcekleri

Arka plan:
Üç katmanlı paralaks.

Uzak arka plan yavaş hareket eder.

Orta katmanda ağaçlar ve harabeler bulunur.

Ön planda çimenler, kökler ve taşlar vardır.

Oynanış:
- Karakter hareketi öğretilir.
- Prizma Ruhu'yla anlaşma yapılır.
- Kalkan laneti keşfedilir.
- İlk reflect gerçekleştirilir.
- Basit düşmanlarla savaşılır.
- İlk yansıma bulmacası çözülür.

Boss: ORMAN MUHAFIZI

Boss saldırıları:
- Enerji tohumu
- Diken yağmuru
- Yer dalgası
- İkinci evrede çoklu mermi

Boss yenildiğinde ilk prizma parçası kazanılır.

## BÖLGE 2 — KRİSTAL MADENLERİ

Tema: Işık, kırılma ve yön.

Görsel tasarım:
- Mor ve mavi kristaller
- Yer altı mağaraları
- Parlayan damarlar
- Asılı kristaller
- Derin uçurumlar
- Yansıtıcı kaya yüzeyleri

Arka plan:
Çok katmanlı mağara duvarları.

Kristaller hafif ışık saçar.

Bazı arka plan kristalleri yavaşça titreşir.

Oynanış:
- Açılı yansıtma bulmacaları
- Hareketli platformlar
- Kristal okçular
- Birden fazla yüzeye mermi sektirme
- Yeni kalkan modu

Boss: KRİSTAL GOLEM

Boss saldırıları:
- Büyük kristal mermi
- Yerden kristal çıkarma
- Parçalanan enerji topları
- Kristal lazer

Boss'un zayıf noktasına doğru açıyla saldırı yansıtılması gerekir.

## BÖLGE 3 — KÜLLERİN KALESİ

Tema: Yıkım ve savaş.

Görsel tasarım:
- Yanmış kale
- Kırmızı gökyüzü
- Kül parçacıkları
- Lav çatlakları
- Kırık sancaklar
- Dev zırhlar
- Karanlık koridorlar

Arka plan:
Uzakta harap kuleler.

Yavaş hareket eden duman katmanları.

Gökyüzünde kızıl bulutlar.

Oynanış:
- Ağır mermiler
- Perfect Reflect ustalığı
- Ateş tuzakları
- Dar savaş arenaları
- Ağır Ayna modu

Boss: KIZIL ŞÖVALYE

Boss saldırıları:
- Alev dalgası
- Ağır mermi
- Dash saldırısı
- Alan patlaması

Boss'un zırhını kırmak için güçlü yansıma gerekir.

## BÖLGE 4 — GÖLGELER TAPINAĞI

Tema: Hafıza, korku ve gerçek.

Görsel tasarım:
- Mor ve siyah renkler
- Yüzen taşlar
- Ruh alevleri
- Kırık aynalar
- Antik yazılar
- Ters çevrilmiş mimari

Arka plan:
Hafif hareket eden mistik sis.

Uzakta asılı taş yapılar.

Parlayan semboller.

Oynanış:
- Görünmez düşmanlar
- Ruh Aynası
- Karanlık mermiler
- Işık ve gölge bulmacaları
- Prizma Ruhu'nun geçmişinin açığa çıkması

Boss: KÖR KÂHİN

Boss saldırıları:
- Ruh küreleri
- Sahte mermiler
- Görünmez lazer
- Ekrandaki belirli alanları lanetleme

Boss'un gerçek konumunu göstermek için Ruh Aynası kullanılır.

## BÖLGE 5 — PRİZMA DİYARI

Tema: Gerçeklik, yansıma ve karar.

Görsel tasarım:
- Boşlukta süzülen adalar
- Dev aynalar
- Gökkuşağı kırılmaları
- Beyaz ve siyah mimari
- Kırık boyut parçaları
- Dev prizma kristali

Arka plan:
Çok katmanlı soyut gökyüzü.

Yavaşça hareket eden kristal parçaları.

Renk değiştiren ışık huzmeleri.

Oynanış:
- Bütün kalkan modlarının kullanılması
- Karmaşık yansıma zincirleri
- Önceki boss mekaniklerinin birleşmesi
- Hikâyenin çözülmesi

Final boss: PRİZMA'NIN YANSIMASI

Boss oyuncunun hareketlerini taklit edebilir.

Yansıtma mekaniklerini kullanır.

Oyuncunun kendi saldırısını tekrar yansıtabilir.

Çok aşamalı bir boss savaşı olmalıdır.

Finalden sonra iki ana son açılır.

---

# 10. BOSS TASARIM PRENSİPLERİ

Boss savaşları oyunun en önemli içeriklerinden biridir.

Her boss:
- En az iki evreye sahip olsun.
- Saldırı öncesi okunabilir animasyon kullansın.
- Oyuncuya tepki verme fırsatı tanısın.
- Kalkan mekaniğini aktif kullandırsın.
- Saldırı düzenlerini tekrarlayabilsin.
- Can azaldıkça mekaniklerini değiştirsin.
- Haksız veya görünmez hasar vermesin.

Boss can barı ekranın üst bölümünde gösterilsin.

İsimleri özel font ve küçük giriş animasyonlarıyla sunulsun.

Boss yenildiğinde kısa bir zafer animasyonu ve hikâye sahnesi oynatılsın.

Oyuncu öldüğünde boss yeniden başlatılabilsin.

Boss saldırıları rastgele olsa bile oyuncunun öğrenebileceği düzenleri korusun.

Boss'ların yalnızca HP'sini yükselterek zorluk oluşturma.

---

# 11. BULMACA SİSTEMİ

Bütün bulmacalar ayna ve yansıtma teması etrafında şekillensin.

## Bulmaca türleri

### Işık Yönlendirme
Oyuncu ışını aynayla belirli bir kristale yönlendirir.

### Kristal Kapı
Birden fazla kristali doğru sırayla etkinleştirir.

### Mermi Sektirme
Düşman saldırısını duvardaki aynadan sektirerek gizli hedefe ulaştırır.

### Görünmez Yol
Ruh Aynası görünmez platformları ortaya çıkarır.

### Element Bulmacası
Belirli renklerde enerji doğru kristallere yönlendirilir.

### Zamanlama Bulmacası
Hareketli bir hedef yalnızca belirli anda vurulabilir.

Bulmacalar açık ve görsel olarak anlaşılır olsun.

Her bulmacada oyuncunun çıkmaza girme riskini azalt.

Başarısız denemelerde sistemi yeniden deneyebilmesini sağla.

---

# 12. GELİŞİM SİSTEMİ

Oyuncu düşmanları yenerek Prizma Parçaları kazanabilir.

Bu kaynak:
- Stamina kapasitesini artırma
- Reflect verimliliğini yükseltme
- Depolanan saldırı kapasitesini geliştirme
- Kalkan özelliklerini açma
- Yeni özel yetenekler edinme

için kullanılabilir.

Gelişim sistemi oyuncuyu yalnızca rakamsal güç artırmaya yöneltmesin.

Yansıtma açısı, zamanlama ve düşman öğrenme becerisi önemini korumalıdır.

Geliştirmeler kontrol noktalarında veya özel Prizma Sunakları'nda yapılabilir.

---

# 13. CHECKPOINT VE KAYIT

Otomatik kayıt sistemi oluştur.

Kaydedilecek bilgiler:
- Bulunulan bölge
- Son kontrol noktası
- Oyuncu sağlığı ve uygun başlangıç durumu
- Açılan kalkan güçleri
- Toplanan Prizma Parçaları
- Boss ilerlemesi
- Hikâye bayrakları
- Final kararları
- Ayarlar

Kayıt sistemi Godot user:// dizinini kullansın.

Bozuk kayıt dosyalarına karşı koruma ekle.

Yeni oyun, devam et ve kayıt sıfırlama seçenekleri sun.

Kritik olaylarda otomatik kayıt yap.

---

# 14. GÖRSEL SANAT YÖNETİMİ

Bu oyun yapay zekâ tarafından rastgele üretilmiş görsellerin bir araya getirilmesi gibi görünmemelidir.

Bütün grafiklerde ortak bir sanat dili olmalı.

## Pixel art prensipleri

- Tutarlı piksel ölçekleri
- Kontrollü renk paletleri
- Temiz karakter silüetleri
- Gereksiz aşırı detaydan kaçınma
- Okunabilir saldırı efektleri
- Piksel grid'ini koruyan animasyonlar
- Uyumlu sprite ve arka plan oranları

## Karakterler

Ana karakter, düşmanlar, NPC'ler ve boss'lar aynı sanat stilinde olmalıdır.

## Arka planlar

Her bölgede en az üç paralaks katmanı bulunabilir.

Paralaks derinliği oynanışı ve platform görünürlüğünü bozmasın.

## Işıklandırma

Aşırı bloom veya bulanıklık kullanma.

Pixel art görünümü korunmalı.

Prizma enerjisi parlak, ortamlar daha karanlık olmalı.

## Parçacık efektleri

- Mermi yansıması
- Perfect Reflect
- Kristal kırılması
- Kalkan darbesi
- Boss ölümü
- Ruh enerjisi
- Ateş ve kül
- Orman yaprakları
- Sis

Efektlerin performans maliyetini kontrol et.

---

# 15. SES VE MÜZİK

Oyunun müzikleri özgün olmalıdır.

Genel müzik yönü:
- Melankolik fantastik atmosfer
- Ambient dokular
- Hafif piyano
- Yumuşak synthesizer
- Kristal ve cam benzeri tınılar
- Boss savaşlarında yoğun perküsyon
- Karanlık sahnelerde düşük frekanslı atmosfer

Bölgelere göre:

Orman: Huzurlu ama gizemli.

Kristal Madenleri: Parlak ve yankılı.

Küllerin Kalesi: Gergin ve güçlü.

Gölgeler Tapınağı: Rahatsız edici, mistik.

Prizma Diyarı: Duygusal ve görkemli.

Boss müzikleri normal bölge müziklerinden belirgin şekilde farklı olmalı.

## Ses efektleri

- Footstep
- Jump
- Dash
- Guard
- Reflect
- Perfect Reflect
- Shield Bash
- Projectile hit
- Crystal break
- Enemy damage
- Boss impact
- Menu hover
- Menu confirm
- Checkpoint activation

Perfect Reflect sesi oyunun en tatmin edici seslerinden biri olmalıdır.

Geçici sesler kullanılıyorsa bunları açıkça işaretle.

Lisansı doğrulanmamış ses veya müzik dosyalarını projeye ekleme.

---

# 16. KULLANICI ARAYÜZÜ

Arayüz minimalist, okunaklı ve pixel-art stiline uygun olsun.

## Ana menü

- New Game
- Continue
- Settings
- Credits
- Quit

Arka planda hafif animasyonlu prizma kristali bulunabilir.

## Oyun içi HUD

- HP göstergesi
- Stamina göstergesi
- Prism Energy
- Aktif kalkan modu
- Prizma Parçası sayısı
- Boss can barı

HUD savaş sırasında görüş alanını kapatmasın.

## Ayarlar

- Master volume
- Music volume
- SFX volume
- Fullscreen/windowed
- Resolution
- VSync
- Kontrol ayarları
- Ekran sarsıntısı şiddeti
- Efekt yoğunluğu
- Dil seçimi

Başlangıçta Türkçe metinleri eksiksiz uygula.

İngilizce yerelleştirme için veri yapısı hazır olsun.

## Erişilebilirlik

- Tuş atamalarını değiştirme
- Ekran sarsıntısını kapatma
- Yanıp sönen efektleri azaltma
- Okunabilir diyalog hızı
- İsteğe bağlı daha kolay reflect zamanlaması

---

# 17. HİKÂYE ANLATIMI VE DİYALOGLAR

Hikâye yalnızca uzun metinlerle anlatılmasın.

Şunları kullan:
- Kısa oyun içi diyaloglar
- Çevresel ipuçları
- NPC konuşmaları
- Boss karşılaşmaları
- Prizma Ruhu'nun yorumları
- Kısa ara sahneler

Karakter konuşmaları doğal, tutarlı ve duygusal olsun.

Aşırı uzun açıklamalardan kaçın.

Oyuncu diyalogları ilerletebilsin.

Daha önce gördüğü ara sahneleri geçebilsin.

Diyaloglar JSON veya Godot Resource tabanlı veri dosyalarından yönetilebilir.

Hikâye kararları kayıt sistemine bağlanmalıdır.

---

# 18. GODOT TEKNİK MİMARİSİ

Projeyi modüler geliştir.

Örnek klasör sistemi:

res://
- scenes/
  - player/
  - enemies/
  - bosses/
  - levels/
  - menus/
  - cutscenes/
  - ui/
  - projectiles/
  - puzzles/
- scripts/
  - player/
  - combat/
  - shield/
  - enemies/
  - bosses/
  - systems/
- assets/
  - characters/
  - environments/
  - effects/
  - audio/
  - ui/
- resources/
  - enemies/
  - projectiles/
  - shields/
  - upgrades/
- localization/
- tests/

Ana sistemler:
- GameManager
- PlayerController
- MirrorController
- ReflectSystem
- ProjectileManager
- EnemyBase
- BossBase
- DamageSystem
- UpgradeManager
- SaveManager
- AudioManager
- DialogueManager
- SceneTransitionManager
- UIManager

Bunlar mantıksal sorumluluklardır; her biri zorunlu olarak singleton olmamalıdır.

Gereksiz global durumdan kaçın.

Sahne referanslarını açık ve güvenli şekilde yönet.

Godot sinyallerini uygun yerlerde kullan.

Veri odaklı tasarım için Resource yapılarını değerlendir.

GDScript kodlarını sürdürülebilir ve test edilebilir biçimde yaz.

---

# 19. OYUN PERFORMANSI

60 FPS hedefle.

Özellikle şunları optimize et:
- Çok sayıda mermi
- Parçacık efektleri
- Boss animasyonları
- Paralaks arka planlar
- Çarpışma kontrolleri
- Ekran dışındaki düşmanlar

Gerektiğinde object pooling uygula.

Her karede gereksiz bellek tahsisi yapma.

Düşman ve mermilerin sahneden düzgün silindiğinden emin ol.

Bellek sızıntılarını araştır.

---

# 20. TEST SİSTEMİ

Oyun geliştirilirken sürekli test uygulanmalı.

## Mekanik testleri

- Karakter düzgün hareket ediyor mu?
- Zıplama ve dash hatasız mı?
- Kalkan bütün yönlerde çalışıyor mu?
- Mermiler doğru açıyla yansıyor mu?
- Perfect Reflect doğru zamanlamayı algılıyor mu?
- Aynı mermi çift hasar oluşturuyor mu?
- Düşman ölünce sahneden temizleniyor mu?
- Boss savaşları tamamlanabiliyor mu?
- Bulmacalar çözülebiliyor mu?
- Oyuncu ölümden sonra doğru noktadan doğuyor mu?

## Oyun akışı testleri

- Yeni oyun başlatılabiliyor mu?
- İlk bölgeden son bölgeye ilerlenebiliyor mu?
- Bütün boss'lar yenilebiliyor mu?
- Oyunun iki finaline de ulaşılabiliyor mu?
- Kayıt yüklenebiliyor mu?
- Ayarlar düzgün saklanıyor mu?

## Hata kontrolü

- Konsol hataları
- Bozuk sahne yolları
- Eksik asset dosyaları
- Null referanslar
- Collision sorunları
- Softlock durumları
- Performans düşüşleri

Godot headless test ve kaynak doğrulama yöntemlerini kullan.

Mümkünse otomatik oynanış senaryoları oluştur.

Ancak headless testin başarılı olması, gerçek oyuncu deneyiminin hatasız olduğu anlamına gelmez.

---

# 21. 48 SAATLİK GELİŞTİRME PLANI

Bu süre bir hedef zaman kutusudur, tamamlanma garantisi değildir.

12 haftalık ana tasarımın kapsamı korunacaktır.

## AŞAMA 1 — Saat 0–6

- Mevcut projeyi analiz et.
- Godot sürümünü ve proje uyumluluğunu doğrula.
- Oyun mimarisini oluştur.
- Oyuncu hareket sistemini geliştir.
- Kalkanı ve reflect fiziğini tamamla.
- İlk test düşmanını oluştur.
- İlk savaş arenasını çalıştır.

## AŞAMA 2 — Saat 6–12

- Perfect Reflect
- Stamina
- Shield Bash
- Mermi çeşitleri
- Düşman temel AI sistemi
- Hasar ve ölüm sistemi
- Kaydetme altyapısı
- Temel UI

## AŞAMA 3 — Saat 12–24

- Beş bölgenin oynanabilir temel haritaları
- Bölgelere özgü düşmanlar
- Beş boss'un temel davranışları
- Kalkan güçlerinin açılması
- Bulmaca altyapısı
- Checkpoint sistemi
- Hikâye diyalogları

Bu aşamada beş bölgenin tamamı daha sade grafiklerle de olsa baştan sona erişilebilir olmalıdır.

## AŞAMA 4 — Saat 24–34

- Pixel art karakterler
- Düşman animasyonları
- Bölge TileSet'leri
- Paralaks arka planlar
- Kalkan efektleri
- Sesler ve müzikler
- Boss girişleri
- Ara sahneler

## AŞAMA 5 — Saat 34–42

- Bölümler arası geçişler
- Gelişim sistemi
- Hikâye finali
- İki sonun uygulanması
- Ana menü
- Ayarlar
- Kayıt ve devam etme
- Oyun içi dengeleme

## AŞAMA 6 — Saat 42–48

- Oyunun tamamını test et.
- Kritik hataları düzelt.
- Çökme sorunlarını araştır.
- Yumuşak kilitlenmeleri (softlock) gider.
- Performans testlerini yap.
- Windows export hazırla.
- Eksik içerikleri ve kalan sorunları raporla.

Zaman daraldığında öncelik her zaman:
1. Oyunun çökmeden çalışması
2. Baştan sona bitirilebilirlik
3. Savaş mekaniklerinin doğruluğu
4. Hikâye ve boss'lar
5. Görsel kalite
6. İkincil efektler

---

# 22. AI AJANLARIYLA PARALEL GELİŞTİRME

Birden fazla ajan kullanılabiliyorsa görevleri uzmanlıklarına göre ayır.

## Agent 1 — Core Gameplay
- PlayerController
- MirrorController
- ReflectSystem
- Projectile
- Damage
- Stamina

## Agent 2 — Enemies & Bosses
- Enemy AI
- BossBase
- Boss saldırıları
- Boss evreleri
- Hasar ve sersemleme

## Agent 3 — Level Designer
- Beş bölgenin temel sahneleri
- TileSet
- Bölge geçişleri
- Platformlar
- Bulmacalar
- Checkpoint

## Agent 4 — Story & UI
- Hikâye
- Diyaloglar
- Ara sahneler
- Menüler
- HUD
- Sonlar
- Ayarlar ve yerelleştirme

## Agent 5 — Art & Audio
- Sprite listesi
- Görsel sanat yönergeleri
- Pixel art animasyonları
- Ses entegrasyonu
- Paralaks arka planlar
- Efektler

## Agent 6 — QA & Integration
- Kod inceleme
- Testler
- Hata düzeltme
- Performans
- Export
- Bütün sahnelerin birleştirilmesi

Ajanlar farklı dosya ve modüllerden sorumlu olsun.

Aynı dosyanın eşzamanlı düzenlenmesinden kaçın.

Paylaşılan API'leri ve sinyal isimlerini başlangıçta belirle.

Her ajanın değişikliğini ayrı Git branch'inde geliştir.

Gerektiğinde worktree kullan.

Birleştirme öncesi doğrulama yap.

Ajan sayısı yetersizse işleri sırayla gerçekleştir.

---

# 23. GELİŞTİRME KURALLARI

Bu kurallar zorunludur.

1. Mevcut çalışan dosyaları sebepsiz yere silme.

2. Var olan kodu incelemeden sıfırdan yazmaya başlama.

3. Mevcut Godot projesi varsa onu temel al.

4. Kritik olmayan kararlar için sürekli kullanıcı onayı isteme.

5. Gereksiz açıklama ve tekrar üretme.

6. Token kullanımını azaltmak için dosyaları gerektiğinde incele, bütün projeyi her görevde yeniden okuma.

7. Her önemli değişiklikten sonra uygun testleri çalıştır.

8. Kullanıcı açıkça istemedikçe yeni bağımlılıklar ekleme.

9. Git ile değişiklikleri düzenli ve anlaşılır commit'lere böl.

10. Kullanıcının özel dosyalarını, tokenlarını, API anahtarlarını veya kişisel verilerini değiştirme ya da görüntüleme.

11. Git geçmişini zorla yeniden yazma.

12. Proje dışındaki dosyalara dokunma.

13. Eksik asset olduğunda açıkça geçici görsel kullan ve bunu raporla.

14. Telif hakkı ihlali oluşturabilecek içerikleri kopyalama.

15. Aynı fonksiyonun farklı sürümlerini gereksiz yere oluşturma.

16. Kırık sahne referansları bırakma.

17. Sadece kod yazmakla yetinme; mümkün olan yerde oyun akışını çalıştırarak doğrula.

18. Görsel kalite için oyun mantığını bozma.

19. Kod tamamlandı diye bütün görevin tamamlandığını varsayma.

20. Projeyi mümkün olduğunca otomatik ilerlet, ancak kritik dosya silme, dış servis maliyeti ve geri dönüşü zor işlemler için onay al.

---

# 24. TAMAMLANMA KRİTERLERİ

Oyun ancak aşağıdaki koşullar gerçekleştiğinde tamamlanmış kabul edilebilir:

- Ana menü çalışıyor.
- Yeni oyun başlatılabiliyor.
- Oyuncu hareket edebiliyor.
- Kalkan sistemi düzgün çalışıyor.
- Perfect Reflect çalışıyor.
- Düşman saldırıları yansıtılabiliyor.
- Beş ana bölge erişilebilir.
- Bölge geçişleri çalışıyor.
- Beş boss yenilebiliyor.
- Bulmacalar çözülebiliyor.
- Kalkan güçleri açılıyor.
- Prizma Ruhu'nun hikâyesi takip edilebiliyor.
- İki farklı son oynanabiliyor.
- Kayıt sistemi çalışıyor.
- Ses ve müzik sistemi çalışıyor.
- Windows için export alınabiliyor.
- Oyunun baştan sona bitirilebilirliği doğrulanmış.
- Bilinen kritik hata kalmamış.

Bu maddelerden herhangi biri eksikse oyunu tamamen bitmiş olarak raporlama.

---

# 25. SENDEN İSTEDİĞİM ÇALIŞMA ŞEKLİ

Şimdi projeyi inceleyerek işe başla.

Önce kısa bir mevcut durum değerlendirmesi oluştur.

Ardından:
1. Eksik sistemleri belirle.
2. Dosya ve modül sorumluluklarını çıkar.
3. Uygulanacak işleri bağımlılık sırasına koy.
4. Paralel geliştirilebilen görevleri ayır.
5. Ana oyun döngüsünü tamamla.
6. Beş bölgeyi entegre et.
7. Boss'ları ve bulmacaları tamamla.
8. Görsel ve işitsel varlıkları ekle.
9. Hikâyeyi ve finalleri bağla.
10. Test et, düzelt ve Windows sürümünü hazırla.

Yalnızca yapılacaklar listesi yazıp durma.

Erişimin olan proje dosyalarında gerçekten geliştirme yap.

Gerekli araçlar ve yetkiler mevcutsa otomatik devam et.

Araç veya model sınırına takılırsan hangi dosyaların tamamlandığını ve sonraki kesin adımı belirt.

Çalışma sonunda kısa durum raporu ver:
- Tamamlanan sistemler
- Test edilen özellikler
- Çalışan bölümler
- Başarısız testler
- Eksik grafik/ses varlıkları
- Kritik hatalar
- Oluşturulan Windows build konumu
- Bir sonraki en öncelikli görev

**Nihai hedef: PRISMBOUND'u yalnızca fikir veya prototip olmaktan çıkarıp, özgün ve baştan sona oynanabilir bir pixel-art aksiyon oyununa dönüştürmek.**

Şimdi geliştirmeye başla.