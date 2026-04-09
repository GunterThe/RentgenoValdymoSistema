# RentgenoValdymoSistema

## Local dev (Flutter web)
`flutter run -d chrome --web-hostname=localhost --web-port=8080 --dart-define=API_BASE=http://localhost:5158`

## Docker (LAN-accessible)
This runs:
- `web` (Flutter web via Nginx) on `http://<your-ip>:8080`
- `backend` (ASP.NET API) on `http://<your-ip>:5158` (optional direct access)
- `db` (Postgres) internally

### Start
1. Ensure Docker daemon is running (Linux):
	- `sudo systemctl enable --now docker`
	- optional (no sudo): `sudo usermod -aG docker $USER` then re-login

2. Run the stack:
	- `docker compose up --build`

3. Open from another device on your local network:
	- `http://<your-ip>:8080`

Notes:
- Database is initialized from `Backend/sql/rentgenai.sql` on first run only.
- Uploaded files persist in a Docker volume (`uploads`).