# Penerimaan Sampel Laboratorium

Aplikasi penerimaan sampel bahan: penerima, bahan, tanggal, lokasi, catatan, foto penerimaan dan peletakan, status dipakai/tidak dipakai, pengguna, penyimpanan/pembuangan, serta riwayat perubahan.

## Upload ke GitHub Pages

1. Ekstrak ZIP ini di HP atau komputer.
2. Buat repository baru, misalnya `sampel-lab`. Untuk GitHub Free, gunakan repository Public.
3. Klik **Add file → Upload files**. Upload `index.html`, `sw.js`, dan `README.md` ke tingkat paling atas repository, lalu **Commit changes**. `.nojekyll` boleh ikut diunggah jika terlihat; aplikasi tetap berfungsi tanpa file tersebut.
4. Buka **Settings → Pages**.
5. Pada **Source**, pilih **Deploy from a branch**.
6. Pilih branch **main**, folder **/ (root)**, lalu **Save**.
7. Tunggu proses deployment selesai. Buka URL yang muncul di Settings → Pages, biasanya `https://USERNAME.github.io/sampel-lab/`.

Jangan upload ZIP sebagai satu file. Pastikan `index.html` langsung berada di root repository, bukan di dalam folder tambahan.

Dokumentasi resmi: https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site

## Penyimpanan data

- GitHub Pages menyediakan halaman aplikasi; data sampel dan foto disimpan di IndexedDB browser perangkat masing-masing.
- Kode ini tidak mengunggah data sampel atau foto ke GitHub dan tidak menggunakan layanan analitik, library, font, atau API eksternal.
- URL yang dibagikan membuka aplikasi kosong untuk browser/perangkat baru. Data tidak otomatis sama antarperangkat.
- Browser yang sama pada domain yang sama berbagi penyimpanan. Jangan membuat beberapa salinan aplikasi ini dalam repository berbeda di domain GitHub Pages yang sama jika membutuhkan database terpisah.
- Gunakan **Backup** untuk mengunduh JSON berisi catatan dan foto. Gunakan **Pulihkan** di perangkat lain untuk memindahkan data secara manual. Catatan dengan ID sama diperbarui dari backup; catatan lainnya tetap ada.
- Data dari versi HTML lokal tidak berpindah otomatis ke versi online. Backup di versi lokal, lalu Pulihkan di versi online.
- Membersihkan data situs/browser atau memakai mode privat dapat menyebabkan data hilang. File backup juga memuat data sampel dan foto, jadi simpan terpisah dari repository publik.
- Repository Public dan halaman aplikasi dapat dilihat orang lain. Data yang dimasukkan tidak otomatis menjadi isi repository atau halaman pengguna lain. Aplikasi ini tidak memiliki login.

## Mode offline

1. Buka link online pertama kali dan tunggu halaman selesai dimuat agar service worker menyimpan aplikasi.
2. Buka ulang URL yang sama. Halaman dapat dibuka offline selama cache dan data situs tidak dihapus oleh browser.
3. Browser HP yang hanya menampilkan pratinjau file mungkin tidak menjalankan penyimpanan. Gunakan browser biasa seperti Chrome atau Edge.

## Update aplikasi

Edit `index.html` di repository yang sama dan Commit changes. Link tetap sama selama username, repository, dan domain tidak diganti. Data browser tetap ada selama database dan domain tidak berubah. Untuk perubahan daftar aset offline, naikkan versi CACHE pada `sw.js`. Tutup seluruh tab aplikasi lalu buka kembali setelah deployment jika pembaruan belum muncul.

## Isi paket

- `index.html`: aplikasi lengkap tanpa dependensi eksternal.
- `sw.js`: cache aplikasi untuk mode offline.
- `.nojekyll`: penanda agar file static dilayani langsung.
- `README.md`: panduan upload dan penggunaan.

## Tampilan kategori dan penggunaan

Halaman utama menampilkan empat kategori: Belum ditentukan, Dipakai, Tidak terpakai (tetap disimpan), dan Dibuang. Tekan kategori untuk membuka daftar; tekan kembali atau Tutup daftar untuk menutupnya.

Tombol Dipakai membuka formulir singkat berisi pengguna dan keterangan. Tanggal dan waktu penggunaan dicatat otomatis saat Simpan, tanpa mengubah tanggal penerimaan.
