# Delira – Aplikasi Katalog Produk

Delira merupakan aplikasi katalog produk berbasis mobile yang dikembangkan menggunakan Flutter. Aplikasi ini terhubung dengan backend PHP dan MySQL yang dijalankan menggunakan Docker.

Aplikasi ini dibuat untuk memenuhi tugas pengembangan aplikasi dengan fitur pengelolaan data produk (CRUD).

## Teknologi yang Digunakan

- Flutter dan Dart
- PHP
- MySQL
- Docker dan Docker Compose
- Caddy
- REST API
- DummyJSON API
- Google Authenticator (OTP)

## Fitur Aplikasi

1. Registrasi akun.
2. Login menggunakan email dan password.
3. Verifikasi keamanan menggunakan Google Authenticator (OTP).
4. Menampilkan daftar produk.
5. Melihat detail produk.
6. Mencari produk.
7. Menambahkan produk.
8. Mengubah data produk.
9. Menghapus produk.
10. Keranjang dan daftar pesanan.

## Repository

**Frontend – Flutter**

https://github.com/husnidewialawiyah-ops/delira_app

**Backend – PHP, MySQL, Docker**

https://github.com/husnidewialawiyah-ops/pcc_sample_php_mysql_services

## Backend dan API

Backend menggunakan PHP sebagai pengelola API, MySQL sebagai database, serta Docker Compose untuk menjalankan layanan.

API berjalan melalui alamat:

`http://localhost:8086`

Endpoint utama yang digunakan:

| Method | Endpoint | Fungsi |
|---|---|---|
| POST | `/register` | Registrasi akun |
| POST | `/register/verify` | Verifikasi OTP registrasi |
| POST | `/login` | Verifikasi email dan password |
| POST | `/login/verify` | Verifikasi OTP login |
| POST | `/logout` | Logout |
| GET | `/products` | Menampilkan produk |
| GET | `/products/{id}` | Detail produk |
| POST | `/products/add` | Menambahkan produk |
| PUT | `/products/{id}` | Mengubah produk |
| DELETE | `/products/{id}` | Menghapus produk |

Endpoint produk memerlukan Bearer Token hasil autentikasi.

## Cara Menjalankan Backend

1. Clone repository backend.
2. Masuk ke folder backend.
3. Salin `.env.example` menjadi `.env`.
4. Sesuaikan konfigurasi database.
5. Jalankan Docker Compose:

```bash
docker compose up -d --build
```

6. Periksa layanan:

```bash
docker compose ps
```

7. Periksa API:

```text
http://localhost:8086/health
```

Pastikan API mengembalikan status berhasil.

Panduan lebih lengkap tersedia di repository backend.

## Cara Menjalankan Aplikasi Flutter

1. Clone repository Delira.
2. Buka folder proyek menggunakan VS Code atau Android Studio.
3. Instal dependency:

```bash
flutter pub get
```

4. Sesuaikan alamat `baseUrl` pada aplikasi dengan alamat backend.

Untuk penggunaan pada HP fisik, gunakan alamat IP lokal komputer yang menjalankan Docker, misalnya:

```dart
const String baseUrl = 'http://192.168.100.151:8086';
```

Ganti alamat IP tersebut sesuai jaringan yang digunakan.

5. Pastikan HP dan komputer terhubung ke jaringan yang sama.
6. Jalankan aplikasi:

```bash
flutter run
```

## Pengembang

**Nama:** Husni Dewi Alawiyah  
**Program Studi:** Teknik Informatika  
**Universitas:** Universitas Muhammadiyah Bandung
