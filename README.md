# Sampel Lab — versi antarperangkat

Paket siap dikonfigurasi untuk GitHub Pages + Supabase. Paket ini BELUM terhubung ke server: pemilik aplikasi harus membuat proyek Supabase sendiri dan mengisi konfigurasi. Tidak ada kredensial atau data sampel asli di paket.

## Yang sudah dibuat

- Database tim bersama: catatan yang disimpan dapat dilihat oleh akun tim lain.
- Login email + password. Tidak perlu OTP setiap membuka halaman; sesi tersimpan di sessionStorage selama tab masih digunakan, dengan pembaruan token otomatis. Password tidak disimpan aplikasi. Setelah tab ditutup, biasanya perlu masuk lagi; perilaku pemulihan tab bisa berbeda menurut browser.
- Foto private: hanya akun anggota lab yang diizinkan server dapat mengunduhnya. Foto dimuat ketika detail/edit dibuka agar daftar tetap ringan.
- Kompresi otomatis: JPEG, sisi panjang maksimal 960 piksel, kualitas adaptif. Target sekitar 100 KB/foto; turun bertahap hingga 640 piksel bila perlu. Ukuran akhir tidak selalu tepat 100 KB. Periksa keterbacaan tulisan kecil; pertahankan foto asli di perangkat bila perlu.
- Daftar diperbarui setiap 15 detik ketika tab aktif dan tidak ada form/detail terbuka. Tombol Perbarui tersedia. Kecepatan bergantung koneksi dan layanan gratis; belum ada benchmark server live.
- Perubahan bersamaan dilindungi revision check. Jika catatan sudah diubah orang lain, form meminta muat ulang, tanpa diam-diam menimpa perubahan tersebut.
- Status dan kategori lama dipertahankan: Belum ditentukan, Dipakai, Tidak terpakai/disimpan, dan Dibuang.
- Form Dipakai singkat: pengguna dan keterangan, dengan waktu server otomatis.
- Tombol Hapus per bahan. Menghapus dari database tim, bukan hanya perangkat sendiri.
- Backup terenkripsi AES-256-GCM + PBKDF2-SHA256 (250.000 iterasi). Password backup terpisah dari password login; tanpa password file tidak dapat dipulihkan.
- Bisa memulihkan backup JSON dari versi lokal lama. Saat memulihkan, foto diperkecil dan diunggah ke server; maksimum 100 catatan / 50 MB sekali proses.

## 1. Buat proyek Supabase

1. Buka https://supabase.com lalu buat akun dan proyek baru.
2. Pilih region Singapore bila tersedia untuk pengguna Indonesia.
3. Gunakan password database yang unik dan kuat. Password ini tidak dimasukkan ke aplikasi.
4. Buka SQL Editor. Salin seluruh isi `setup.sql`, lalu Run. Skrip ini untuk proyek baru, bukan untuk dijalankan berulang pada proyek yang sudah berisi tabel sama.
5. Buka Authentication → pengaturan Sign In / Providers. Aktifkan email/password dan nonaktifkan pendaftaran pengguna baru/public signups.
6. Jika tersedia, atur minimum password 12 karakter. Pengguna bisa mengganti password setelah masuk.

## 2. Buat akun dan beri akses

1. Buka Authentication → Users → Add user → Create new user.
2. Buat akun email/password untuk dirimu dan setiap rekan. Pastikan akun dikonfirmasi (Auto Confirm) bila pilihan tersedia. Gunakan password berbeda per orang, bukan password bersama. Kirim password awal lewat kanal pribadi.
3. Di SQL Editor jalankan query ini dengan email sebenarnya:

```sql
insert into public.lab_members(user_id)
select id from auth.users
where email in ('anda@example.com', 'rekan@example.com')
on conflict (user_id) do nothing;
```

4. Cek Table Editor → lab_members: setiap akun yang disetujui harus memiliki baris user_id.
5. Untuk mencabut akses segera, hapus user_id-nya dari lab_members. Token login yang masih aktif tidak mengabaikan pemeriksaan anggota pada request berikutnya. Foto yang sudah diunduh tetap bisa dimiliki pengguna; tidak ada mekanisme menarik kembali salinan tersebut.

Akun terdaftar yang tidak ada di lab_members tetap ditolak. Pemilik proyek saja yang mengelola anggota melalui dashboard/SQL. Semua anggota yang diizinkan bisa membaca, menambah, mengubah, dan menghapus catatan bersama.

## 3. Isi config.js

Dari dashboard Supabase, ambil Project URL dan **Publishable Key**. Isi:

```js
window.LAB_CONFIG = {
  supabaseUrl: 'https://REF_PROYEK.supabase.co',
  publishableKey: 'sb_publishable_KEY_ASLI',
  appUrl: 'https://USERNAME.github.io/sampel-lab/'
};
```

Gunakan URL final GitHub Pages dengan slash `/` di akhir. Jangan menaruh secret key, service_role key, password akun, token login, atau password database di GitHub. Publishable key boleh ada di aplikasi; akses sebenarnya diperiksa oleh server.

## 4. Upload ke GitHub

1. Backup data di aplikasi lama sebelum mengganti file.
2. Upload `index.html`, `config.js`, `sw.js`, dan `.nojekyll` ke root repository GitHub Pages. README boleh ikut. `setup.sql` tidak diperlukan website: jalankan di Supabase; jangan isi SQL yang diunggah publik dengan email asli tim.
3. Aktifkan GitHub Pages dari branch main, folder / (root), jika belum aktif.
4. Tunggu deployment. Buka URL HTTPS yang persis sama dengan appUrl, lalu masuk dengan akun yang telah ditambahkan ke lab_members.
5. Jika memakai repository lama, lakukan reload dan tutup semua tab aplikasi lama lalu buka kembali. `sw.js` baru mencabut cache versi lama; pada browser yang tetap menampilkan antarmuka lama, hapus SERVICE WORKER/CACHE aplikasinya saja setelah backup, bukan seluruh data situs.
6. Gunakan Pulihkan untuk memindahkan data lokal lama ke database tim. Catatan lokal tidak otomatis diunggah.

Website ini tidak mendaftarkan service worker baru dan tidak menyimpan cache respons private. Membaca/menulis catatan tim memerlukan koneksi internet; tidak ada antrean edit offline. Data IndexedDB aplikasi lama tidak dihapus oleh paket ini.

## 5. Pemeriksaan sebelum dipakai tim

Pengujian berikut perlu dilakukan setelah konfigurasi server selesai; belum dijalankan terhadap akun/proyekmu:

1. Buka link di HP A dan laptop B, masuk memakai dua akun anggota yang berbeda.
2. Tambah satu sampel + foto di A. Tekan Perbarui di B atau tunggu hingga 15 detik saat halaman aktif; pastikan bahan muncul.
3. Ubah status Dipakai di B. Periksa perubahan dan waktu penggunaan di A.
4. Buka form bahan yang sama di dua perangkat; simpan di A lalu B. B harus mendapat pesan konflik, lalu muat ulang sebelum menyimpan.
5. Buat akun uji tanpa baris lab_members. Login harus ditolak akses lab. Membuka HTML tanpa login tidak boleh memperoleh data server.
6. Periksa bucket lab-photos tetap Private, lalu buka URL storage public dari file contoh tanpa login: harus ditolak.
7. Backup satu catatan; Pulihkan dengan password salah harus gagal, password benar harus berhasil. Jangan hilangkan password backup.
8. Hapus catatan contoh; pastikan catatan hilang di dua perangkat dan foto server dihapus.

Jika save mengalami timeout, hasilnya bisa sudah tersimpan di server. Tekan Perbarui sebelum mencoba ulang. Foto yang gagal dikaitkan karena timeout/konflik dapat tertinggal di bucket; pemilik dapat membersihkan foto tak terpakai setelah mencocokkan path dengan data lab_samples. Aplikasi sengaja tidak menghapus upload ketika hasil commit tidak pasti agar foto catatan yang berhasil tidak ikut hilang.

## Keamanan dan batasnya

- HTTPS untuk pengiriman data; Supabase menjalankan enkripsi penyimpanan pada infrastruktur yang dikelolanya. Ini bukan enkripsi end-to-end: operator layanan/pemilik proyek dengan akses admin masih dapat mengakses data.
- RLS server-side, membership allowlist, bucket private, tanpa direct write grant ke tabel; perubahan melalui fungsi server yang memeriksa anggota dan revision.
- Audit server terpisah (`lab_audit`) mencatat waktu, aktor, dan aksi save/delete; anggota tidak diberi izin mengubah log ini. Riwayat di dalam catatan adalah riwayat aplikasi, bukan audit tak bisa diubah oleh admin proyek.
- Tidak ada CDN/library eksternal. Teks pengguna di-escape sebelum dirender; CSP membatasi script, koneksi, dan sumber gambar. Token ada di sessionStorage, tidak pernah di config.js. CSP ini bukan pengganti pembatasan server atau review keamanan.
- Login memeriksa alamat aplikasi resmi dari config.js. Simpan bookmark URL asli dan gunakan password manager. Situs phishing yang sengaja menyalin lalu mengubah kode masih bisa menipu orang; aplikasi ini tidak kebal phishing dan tidak menerapkan passkey/MFA.
- Lindungi akun GitHub dan Supabase pemilik dengan 2FA. Siapa pun yang bisa mengubah kode website bisa menyisipkan kode berbahaya, sehingga akses repository harus dibatasi.
- Backup terenkripsi melindungi file backup, bukan database utama. Password backup yang lemah masih berisiko ditebak. Password kuat dan unik diperlukan.
- Tidak ada jaminan 100% aman. Ini implementasi awal yang perlu diuji live dan ditinjau sebelum dipakai untuk data sangat sensitif. Sesuaikan penggunaan layanan cloud dengan izin penyimpanan data lab/perusahaan.

## Kuota gratis dan sumber

Supabase Free saat diperiksa: database 500 MB, file 1 GB, egress 5 GB + cached egress 5 GB. Proyek bisa dijeda setelah 1 minggu tidak aktif; layanan dan kuota dapat berubah. Karena foto diunduh secara authenticated, jangan mengasumsikan seluruh unduhan mendapat cached egress.

- https://supabase.com/security
- https://supabase.com/pricing
- https://supabase.com/docs/guides/platform/regions
- https://supabase.com/docs/guides/auth/passwords
- https://supabase.com/docs/guides/database/postgres/row-level-security
- https://supabase.com/docs/guides/storage/security/access-control
- https://supabase.com/docs/guides/getting-started/api-keys

## Mengubah kode

Jika mengubah JavaScript inline pada index.html, perbarui hash `sha256-...` pada meta Content-Security-Policy. Jika tidak, browser akan memblokir script yang berubah. Mengubah config.js saja tidak memerlukan perubahan hash. Jangan mengganti hash dengan script-src unsafe-inline untuk menghindari langkah ini.

## Validasi paket yang telah dilakukan

Pemeriksaan sintaks JavaScript, hash CSP, dan pengujian logika dua klien menggunakan REST mock telah lolos: sinkronisasi, form Dipakai, konflik revision, penolakan akun bukan anggota, penghapusan bersama, logika target ukuran foto, serta backup AES-GCM (password benar/salah dan deteksi perubahan ciphertext). Pengujian ini bukan pengujian izin server live. SQL/RLS belum dieksekusi pada Supabase/PostgreSQL, dan hasil foto serta tampilan belum diuji di browser nyata. Lakukan pemeriksaan live di atas setelah setup.
