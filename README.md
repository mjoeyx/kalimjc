![image](https://github.com/user-attachments/assets/b9f9cb33-697c-4923-9fec-156558006e17)

###  Installasi untuk Termux

Repositori ini berisi script bash sederhana untuk mengotomatiskan proses instalasi Kali Nethunter di Termux, aplikasi terminal android dan aplikasi lingkungan yang berbasis Linux.

## $${\color{red}Persyaratwn}$$

Sebelum menjalankan skrip, pastikan Anda memiliki prasyaratan berikut:

- **Termux** [https://f-droid.org/repo/com.termux_1020.apk] Aplikasi Termux yang diinstal pada perangkat Android Anda.
- ***Koneksi Internet***
- ***Ruang penyimpanan yang cukup tersedia di perangkat Anda..*** `1GB sampai 8GB`

## $${\color{red}Instalasi}$$

1. Buka Termux di Android device Anda.

2. Memberikan akses penyimpanan ke Termux menggunakan perintah berikut.
```bash
termux-setup-storage
```
4. Pertama install paket `git`(Jika belum diinstal).
```bash
pkg install git -y
```

6. Install paket `wget` (Jika belum diinstal).
```bash
pkg install wget -y 
```
7. Download Pemasangan script Kali Nethunter.
```bash
git clone https://github.com/mjoeyx/kalimjc && cd kalimjc
```
8. Membuat script dapat dieksekusi.
```bash
chmod +x kalimjc.sh setup
```
9. Eksekusi script.
```bash
./setup
```

Ikuti petunjuk atau instruksi apa pun yang muncul selama proses instalasi.

## Disclaimer

Skrip ini disediakan seadanya dan tanpa jaminan. Gunakan dengan risiko Anda sendiri. Pastikan untuk meninjau dan memahami perintah dalam script sebelum menjalankannya.
