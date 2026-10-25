# Kodi CI Builder

Repositori ini adalah **CI Workflow Runner** untuk mengompilasi **Kodi** langsung dari upstream resmi [`xbmc/xbmc`](https://github.com/xbmc/xbmc) branch `Piers` tanpa perlu melakukan fork pada seluruh kode sumber Kodi.

## File yang Tersedia

- [`.github/workflows/build-linux.yml`](.github/workflows/build-linux.yml): Workflow build Kodi Linux (x11, wayland, gbm).
- [`.github/workflows/kademlia.yml`](.github/workflows/kademlia.yml): Workflow build Kodi Piers dengan Kademlia dari [`tumbresta-ops/xbmc`](https://github.com/tumbresta-ops/xbmc/tree/Piers).
- [`.github/workflows/build-android.yml`](.github/workflows/build-android.yml): Workflow build Kodi Android (arm64-v8a / arm8a dan armeabi-v7a / arm7a).

### Composite Actions Modular (`.github/actions/`):
- `ccache-restore`: Restore cache kompilasi C++ berbasis hash commit/platform.
- `ccache-save`: Save cache kompilasi C++ agar kompilasi berikutnya cepat (~5-10 menit).
- `build-binary-addons`: Membangun binary addon (contoh: `peripheral.joystick`) dan pelaporan ke GitHub Step Summary.
- `setup-android-build`: Setup toolchain host, Android SDK 37, dan NDK r28c (`28.2.13676358`).
- `configure-depends`: Bootstrap dan configure dependensi Android (`tools/depends`).
- `depends-cache-restore` & `depends-cache-save`: Cache dependensi Android yang telah dikompilasi.

---

## 1. Target Linux (Target Pertama)

### Platform yang Didukung:
- **`x11`**: OpenGL desktop (`gl`)
- **`wayland`**: OpenGL ES (`gles`)
- **`gbm`**: DRM/KMS direct rendering (`gles`)

### Output Build:
Paket installer Debian (`.deb`) yang dapat diinstal langsung di Ubuntu/Debian (`kodi_*.deb` dan `kodi-bin_*.deb`). Hasil build diunggah otomatis ke **GitHub Artifacts** (retensi 14 hari).

---

## 2. Target Android (Target Kedua)

### Arsitektur yang Didukung:
- **`arm64-v8a`** (ARM 64-bit / arm8a)
- **`armeabi-v7a`** (ARM 32-bit / arm7a)

### Output Build:
Paket aplikasi Android (`.apk`) siap pasang.

---

## Cara Menjalankan Build

1. Buka tab **Actions** di repositori ini (`https://github.com/tumbresta-ops/kodi/actions`).
2. Pilih workflow **Build Kodi (Linux)** atau **Build Kodi (Android)**.
3. Klik tombol **Run workflow**.
4. Parameter yang dapat dipilih:
   - `target_platform`: `x11`, `wayland`, `gbm`, atau `all`.
   - `configuration`: `Release` atau `Debug`.
   - `kodi_repo`: Default `xbmc/xbmc`.
   - `kodi_ref`: Default `Piers`.
5. Setelah build selesai, unduh file `.deb` atau `.apk` dari bagian **Artifacts**.

Untuk membangun versi Kademlia, pilih workflow **Build Kodi Piers (Kademlia)**. Workflow ini mengambil branch `Piers` dari `tumbresta-ops/xbmc` dan menghasilkan paket Linux `.deb`.
