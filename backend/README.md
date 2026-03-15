# Backend (PostgreSQL)

Bu klasor PostgreSQL tabanli API icin baslangic kodudur.

## 1) Postgres'i ac

Iki secenek var.

### Secenek A: Docker

```bash
docker compose -f backend/docker-compose.yml up -d
```

### Secenek B: Homebrew (macOS)

```bash
brew install postgresql@16
brew services start postgresql@16
```

## 2) Ortam dosyasini hazirla

```bash
cp backend/.env.example backend/.env
```

`backend/.env` icinde `DATABASE_URL` dogru olmali.

Homebrew ile calisiyorsan bu URL isler:

```env
DATABASE_URL=postgresql://<mac-kullanici-adi>@localhost:5432/duzlemolcer
```

## 3) SQL migration calistir

Once veritabaniyi olustur:

```bash
createdb duzlemolcer
```

Sonra migration dosyalarini uygula:

```bash
psql -d duzlemolcer < backend/sql/001_init.sql
psql -d duzlemolcer < backend/sql/002_auth.sql
```

## 4) API bagimliliklarini kur

```bash
cd backend
npm install
```

## 5) API'yi baslat

```bash
npm run dev
```

API adresi:

- `GET /api/health`
- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/me`
- `GET /api/measurements?limit=50` (JWT gerekli)
- `POST /api/measurements` (JWT gerekli)

## Flutter baglanti notu

Uygulama varsayilan olarak bu adresleri kullanir:

- Android emulator: `http://10.0.2.2:8080`
- iOS simulator: `http://127.0.0.1:8080`

Farkli bir API adresi kullanmak icin:

```bash
flutter run --dart-define=API_BASE_URL=http://<senin-ip-adresin>:8080
```

Flutter'in otomatik auth denemesi icin:

```bash
flutter run \\
  --dart-define=API_BASE_URL=http://<senin-ip-adresin>:8080 \\
  --dart-define=API_AUTH_EMAIL=user@example.com \\
  --dart-define=API_AUTH_PASSWORD=StrongPass123!
```

`POST /api/auth/register` ornek body:

```json
{
  "email": "user@example.com",
  "password": "StrongPass123!"
}
```

`POST /api/measurements` ornek body (Authorization: Bearer <token>):

```json
{
  "angle_x": 1.2,
  "angle_y": -0.4,
  "mode": "level"
}
```

## Guvenlik Notu

Bu surumde JWT auth ve kullanici bazli veri izolasyonu vardir.
Canliya cikmadan once su adimlari tamamla:

- HTTPS arkasi deploy
- Guclu sifre ve gizli anahtar yonetimi
- Refresh token/oturum yenileme
- CORS origin listesini sadece gercek domain ile sinirla
