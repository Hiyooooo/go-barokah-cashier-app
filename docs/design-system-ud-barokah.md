# Analisis UI/UX — UD. BAROKAH E-Commerce Interface

## 1. UI Style & Konsep Visual

**Gaya Desain:** Clean SaaS / Minimalist E-commerce dengan sentuhan Organic-Fresh Grocery Branding.

**Karakteristik Visual Utama:**

- Layout bersih dengan banyak whitespace, komponen berbasis card dengan sudut membulat
- Kombinasi warna hijau tua sebagai identitas brand (natural, segar, "pangan sehat") dipadukan netral krem/putih untuk kesan bersih dan terpercaya
- Struktur informasi sangat terorganisir: sidebar navigasi, card ringkasan, badge status berwarna
- Tidak ada elemen dekoratif berlebihan — pendekatan functional-first, mengutamakan keterbacaan dan efisiensi transaksi

**Tone & Vibe:** Terpercaya, segar, dan "grounded" — cocok untuk platform grosir/pangan (UD. Barokah = toko bahan pangan). Kesan profesional namun tetap hangat berkat aksen warna coklat/tanah dan hijau alami, bukan hijau korporat yang dingin.

---

## 2. Color Palette & Token Warna

| Token                    | HEX                           | Deskripsi                                                                |
| ------------------------ | ----------------------------- | ------------------------------------------------------------------------ |
| Background / Canvas      | `#F7F8F6` – `#FAFAF9`         | Abu-abu keputihan sangat terang, netral hangat                           |
| Card / Surface           | `#FFFFFF`                     | Putih bersih untuk kontras dengan canvas                                 |
| Primary / Action / CTA   | `#2B5D42` (Deep Forest Green) | Digunakan pada logo, heading aksen "BAROKAH", tombol checkout utama      |
| Secondary / Accent       | `#8A653B` (Warm Brown)        | Aksen sekunder, kemungkinan untuk kategori/badge, melengkapi hijau       |
| Tertiary / Soft Accent   | `#9EB394` (Sage Green)        | Background lembut, hover state, elemen pendukung ringan                  |
| Neutral Cream            | `#EEE9D3`                     | Background alternatif, area highlight lembut (misal badge "SEMUA" aktif) |
| Typography Heading       | `#1A1A1A` – `#222222`         | Hitam pekat untuk judul (mis. "KERANJANG BELANJA")                       |
| Typography Body          | `#4A4A4A` – `#6B6B6B`         | Abu-abu gelap untuk teks deskriptif/harga sekunder                       |
| Border & Divider         | `#E5E5E5` – `#ECECEC`         | Abu sangat tipis, hampir tak terlihat, untuk pemisah antar card          |
| Status - Warning/Pending | `#E8B84B`                     | Badge "MENUNGGU", "LANJUTKAN PEMBAYARAN"                                 |
| Status - Error/Danger    | `#D9534F`                     | Badge "BELUM DIBAYAR", "BATALKAN"                                        |

**Catatan Kontras:**

- Hijau tua `#2B5D42` terhadap putih memberi rasio kontras tinggi (baik untuk aksesibilitas WCAG AA pada teks besar/tombol)
- Krem `#EEE9D3` dipakai sebagai low-emphasis background (tab aktif, state terpilih) — bukan untuk teks langsung karena kontrasnya rendah
- Warna status (merah/kuning/hijau) sengaja dibuat kontras kuat dan terpisah dari palet brand agar cepat dikenali sebagai indikator, bukan elemen dekoratif

---

## 3. Typography Breakdown

**Font Terpakai:** Poppins (dikonfirmasi oleh user) — geometric sans-serif dengan karakter huruf bulat dan modern.

**Rekomendasi Font Alternatif (jika perlu variasi/fallback):**

- **Poppins** — pilihan utama, sudah sesuai
- **Plus Jakarta Sans** — alternatif lokal Indonesia dengan geometri mirip, sedikit lebih netral
- **Manrope** — jika ingin kesan lebih modern-teknis namun tetap ramah

**Hierarki Teks:**

| Level             | Ukuran (estimasi) | Weight                                 | Contoh                                 |
| ----------------- | ----------------- | -------------------------------------- | -------------------------------------- |
| Heading (H1)      | 28–32px           | Bold / SemiBold (600–700)              | "KERANJANG BELANJA"                    |
| Section Title     | 16–18px           | SemiBold (600)                         | "Ringkasan Belanja", "Riwayat Pesanan" |
| Body / Item Name  | 14–15px           | Medium (500)                           | "Scarlett Triple Combo..."             |
| Price / Numeric   | 14–20px           | SemiBold–Bold, warna hijau untuk total | "Rp 25.910.000"                        |
| Caption / Meta    | 11–12px           | Regular (400), warna abu               | "11 barang terpilih", tanggal order    |
| Badge/Status Text | 10–11px           | SemiBold, uppercase                    | "MENUNGGU", "SELESAI"                  |

---

## 4. Layout, Spacing & UI Treatment

- **Border & Radius:** Smooth, sekitar 12–16px pada card besar (keranjang, ringkasan), 8px pada elemen kecil (input qty, badge status), tombol utama cenderung pill/rounded-full atau radius besar (~24px)
- **Elevasi & Depth:** Sangat flat — nyaris tanpa drop shadow signifikan, mengandalkan perbedaan warna background (putih vs abu terang) dan border tipis untuk memisahkan card dari canvas. Jika ada shadow, sangat halus (`0 1px 3px rgba(0,0,0,0.04)`)
- **Spacing & Grid:** Kategori balanced-to-spacious — padding internal card generous (~24px), jarak antar elemen list konsisten (~16–20px). Layout 2 kolom pada halaman keranjang (list produk : ringkasan ≈ 65:35), 2 kolom pada halaman profil (sidebar : konten ≈ 25:75)
- **Ikon:** Line-icon minimalis (ikon cart, user, trash, search) — konsisten stroke tipis, bukan filled/solid

---

## 5. Panduan Replikasi (Quick Implementation)

- **Base Layer:** Gunakan background abu-putih `#F7F8F6`, semua konten utama diletakkan dalam card putih `#FFFFFF` dengan radius 12–16px dan border tipis `#ECECEC` (tanpa shadow berat)
- **Brand Anchor:** Warna hijau `#2B5D42` khusus dipakai untuk logo, CTA utama, dan angka/total penting — jangan digunakan berlebihan di body text agar tetap jadi aksen yang menonjol
- **Status System:** Bangun token warna terpisah untuk status (merah=belum bayar, kuning=menunggu, hijau=selesai) yang konsisten di seluruh badge dan tombol aksi terkait status tersebut
- **Tipografi Konsisten:** Terapkan Poppins dengan skala tegas — Bold untuk heading utama, SemiBold untuk harga/angka penting, Regular/Medium untuk teks deskriptif, dan selalu gunakan warna abu gelap (bukan hitam pekat) untuk body text sekunder agar hierarki terasa lembut namun jelas
