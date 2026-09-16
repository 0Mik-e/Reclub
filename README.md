# Reclub (Flutter)

Aplikasi komunitas olahraga bergaya [reclub.co](https://reclub.co/id) — cari klub, buat & ikut
_meet_, main kompetisi, dan ngobrol. Seluruh data **tersimpan di SQLite lokal** (bukan dummy
in-memory): apa pun yang kamu ubah tetap ada setelah app ditutup.

## Akun demo

| Email | Password | Nama |
|---|---|---|
| `demo@reclub.id` | `reclub123` | User |

Form login sudah terisi otomatis — tinggal tekan **Masuk**. Kamu juga bisa **Daftar** akun baru
(nama, email, password minimal 6 karakter, level, cabang olahraga, kota); akun tersimpan di tabel
`users` dengan password ter-hash **SHA-256 + salt acak per user** (`sha256(salt::password)`).

Selain email/password ada dua jalur masuk lain di layar login:

- **Lanjutkan dengan Google** — membuka sheet pemilih akun (mock, tanpa network). Akun yang
  dipilih dicari dulu di tabel `users` lewat email; kalau belum ada, dibuat baru dengan
  `provider = 'google'`, jadi login berikutnya memakai baris yang sama.
- **Lanjut sebagai tamu** — membuat/memakai akun `provider = 'guest'`. Semua aksi (gabung meet,
  chat, klub) tersimpan normal di SQLite. Di halaman Profil ada banner untuk **upgrade** ke akun
  penuh: baris user yang sama di-*update* (nama, email, password, `provider = 'password'`), jadi
  seluruh data tamu ikut terbawa.

## Menjalankan

```bash
flutter pub get

# iOS Simulator (mesin ini: Xcode terpasang tapi xcode-select menunjuk ke CommandLineTools)
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
flutter run -d "iPhone 17 Pro"

# Android emulator
flutter run -d emulator-5554
```

Build iOS pertama akan menjalankan `pod install` (sqflite adalah plugin native, butuh CocoaPods).

```bash
flutter analyze
flutter test          # memakai sqflite_common_ffi, jadi DB benar-benar dites
```

## Alur aplikasi

`main.dart` mem-boot `AppState` lalu memilih layar berdasarkan `BootStage`:

```
loading  →  splash
onboarding → 3 slide perkenalan (sekali saja, disimpan di app_meta)
auth     →  login / daftar
ready    →  RootShell: Discover · Klub · Meet · Compete · Chat
```

Sesi login disimpan di `app_meta['user_id']`, jadi app langsung masuk saat dibuka lagi.

## Halaman

- **Discover** — filter kota/olahraga, pencarian, filter lanjutan (tipe, jarak, khusus social),
  strip 7 hari, tab Klub/Meet/Kompetisi/Venue/Orang, dan tombol **Buat meet** (tersimpan ke DB,
  otomatis join + posting kartu meet ke chat klub).
- **Klub** — feed dengan like & post (post sendiri bisa dihapus), aktivitas dengan tombol hadir,
  daftar anggota dengan filter level, dan tab Tentang.
- **Meet** — detail, kapasitas, peserta per tim, match dengan input skor, dan klasemen yang
  dihitung ulang tiap skor disimpan. Tab Chat memakai thread meet.
- **Compete** — VFFL Season 4: detail, peserta, match pool (skor bisa diedit), hasil
  (Juara / Klasemen pool / Playoff / Statistik), dan diskusi.
- **Chat** — inbox dengan filter & pencarian, thread klub/meet/pribadi, balasan cepat, reaksi 🔥
  (ketuk dua kali), hapus pesan sendiri, dan kartu meet yang bisa dibuka.
- **Profil** — ubah profil, ganti password, reset database, keluar.

## Brand & ikon

Ikonnya berupa raket padel/pickleball berlubang plus bola hijau di atas tile amber (tanpa
huruf/teks). Semuanya digambar sebagai vektor di `lib/widgets/logo.dart` (`ReclubMark`,
`ReclubWordmark`, `ReclubBrand`), jadi satu sumber dipakai untuk logo di dalam app, splash
screen, dan seluruh launcher icon. Regenerasi semua aset:

```bash
flutter test tool/gen_icons.dart
```

Yang dihasilkan:

| Platform | File |
|---|---|
| iOS icon | `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` (15 ukuran, 20pt–1024pt) |
| iOS splash | `ios/Runner/Assets.xcassets/LaunchImage.imageset/*.png` (1x/2x/3x) |
| Android icon | `mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png` + `ic_launcher_round.png` |
| Android adaptive | `ic_launcher_background.png`, `ic_launcher_foreground.png`, `ic_launcher_monochrome.png` + `mipmap-anydpi-v26/ic_launcher.xml` |
| Android splash | `mipmap-*/launch_logo.png` + `drawable{,-v21}/launch_background.xml` |

Splash native (putih, gelap saat dark mode di Android) langsung menyambung ke splash Flutter
beranimasi di `lib/main.dart` selama `AppDb.open()` berjalan.

## Struktur

```
lib/
  data/
    db.dart          skema + seed SQLite (17 tabel), hashing password
    app_state.dart   store ChangeNotifier: hidrasi dari DB, write-through tiap mutasi
    models.dart      model + factory fromMap
  pages/             onboarding, auth, discover, club, meet, compete, chat, profile
  widgets/common.dart komponen bersama (Avatar, Tag, PillSwitch, SectionCard, dll)
  theme.dart         warna, radius, bayangan, tipografi
test/smoke_test.dart tes DB, auth, perhitungan, dan render tiap tab
```

### Tabel

`users`, `app_meta`, `clubs`, `club_members`, `players`, `meets`, `meet_participants`,
`activities`, `activity_attendees`, `posts`, `post_likes`, `matches`, `comp_teams`,
`pool_matches`, `bracket`, `threads`, `messages`, `reactions`.

Data seed (klub USC Pickleball, 16 pemain, 13 meet, match, pool, thread chat) hanya dibuat sekali
saat DB pertama kali dibuat. Jadwal meet otomatis digeser maju setiap app dibuka supaya strip
7 hari tidak pernah kosong. **Profil → Reset data** menghapus dan menyemai ulang database.
