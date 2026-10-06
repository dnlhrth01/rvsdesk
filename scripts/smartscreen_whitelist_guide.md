# Panduan Mengatasi Windows Defender & SmartScreen (100% Percuma)

Bila perisian `.exe` baharu dikeluarkan tanpa membeli Sijil EV (Extended Validation) bernilai ratusan dolar setahun, Windows SmartScreen akan memaparkan mesej amaran standard:
> *"Windows protected your PC / Windows Defender SmartScreen prevented an unrecognized app from starting."*

Berikut adalah 3 langkah rasmi & percuma untuk menangani isu ini:

---

## 1. Menjalankan Perisian Buat Kali Pertama (Cara Biasa)
Apabila tetingkap amaran SmartScreen muncul:
1. Klik teks **"More info"** (Maklumat lanjut).
2. Klik butang **"Run anyway"** (Jalankan juga).
*Nota: Selepas dijalankan sekali, Windows akan mengingati pilihan tersebut dan tidak akan bertanya lagi pada masa akan datang.*

---

## 2. Hantar ke Portal Microsoft Security Intelligence (Percuma - Disyorkan!)
Microsoft menyediakan portal percuma untuk pembangun perisian menghantar fail `.exe` bagi proses semakan automatik keselamatan:

1. Pergi ke: **[Microsoft Security Intelligence Submission Portal](https://www.microsoft.com/en-us/wdsi/filesubmission)**
2. Pilih tab **"Software developer"**.
3. Muat naik fail `RVSDesk.exe`.
4. Pilih sebab: *"Incorrectly detected as malware / Unknown software whitelisting"*.
5. Dalam masa **2 hingga 4 jam**, sistem cloud AI Microsoft akan mengimbas binari tersebut, mengesahkan ia bersih daripada sebarang virus/trojan, dan memasukkan tandatangan hash fail tersebut ke dalam pangkalan data Windows Defender sedunia secara automatik.
6. Selepas itu, tiada lagi amaran merah atau sekatan pada mana-mana PC Windows!

---

## 3. Manfaatkan GitHub Releases untuk Reputasi Muat Turun
- SmartScreen menggunakan algoritma *download reputation*.
- Apabila fail `.exe` dimuat turun daripada domain yang dipercayai seperti `github.com/<username>/rvsdesk/releases` oleh beberapa orang pengguna dan tiada aduan keselamatan dibuat, skor reputasi fail tersebut akan meningkat secara automatik.

---

## 4. Pemasangan Sijil Self-Signed (Untuk Komputer Dalaman / Pejabat)
Jika anda menggunakan RVSDesk untuk kegunaan syarikat atau komputer keluarga:
- Jalankan skrip `create_self_signed_cert.ps1` yang disediakan.
- Sijil akan dimasukkan terus ke dalam `Trusted Root Certification Authorities` Windows.
- Sekali gus, Windows akan mengiktiraf perisian sebagai sah dan dipercayai sepenuhnya tanpa sebarang popup amaran.
