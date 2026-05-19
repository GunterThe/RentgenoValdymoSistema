# RentgenoValdymoSistema

### Sukurimas

1. Linux
	- parsisiuskite docker packages
	- pradekite docker `sudo systemctl start docker`
	- aplanke kur yra docker-compose.yml darykite `sudo docker compose up --build`
	- nuoroda bus `http://<jusu-ip>:8080` ip galite rasti su `ip -4 addr show` konsoleje ir ieskokite tokio kaip `192.168.x.xxx`

2. Windows
	- parsisiuskite docker programa [Nuoroda](https://www.docker.com/)
	- praeikite visus instaliavimo zingsnius
	- kai viska padaret ir docker nemeta, kad nebereikia nieko atsinaujinti, nuekit i programos aplanka kur yra docker-compose.yml ir darykit `docker compose up --build`
	- nuoroda bus `http://<jusu-ip>:8080` ip galite rasti su `ipconfig` windows powershelle ir ieskokite tokio kaip `192.168.x.xxx`

3. Paleidimas
	- kai jau padarete `docker compose up --build` jeigu isjungete serveri arba perkrovet ta kompa tai reikia tiktai padaryti `docker compose up`, kad nebuildint be reikalo.
	- flutter run -d chrome --web-hostname=localhost --web-port=8080

---

## Hostinimas internete (Production + HTTPS)

Jeigu planuojate hostinti viešai internete, naudokite [docker-compose.prod.yml](docker-compose.prod.yml). Šis variantas:
- publikuoja tik `80/443` (UI per `https://<domenas>/`)
- **neeksponuoja** DB ir backend API portų į internetą (API pasiekiama per `/api/*` per reverse proxy)
- automatiškai sukonfigūruoja HTTPS sertifikatus (Let’s Encrypt) per Caddy

### Reikalavimai
- Linux serveris su Docker
- Domenas su DNS A/AAAA įrašu į serverio IP
- Atidaryti firewall/security-group portai: TCP `80` ir `443`

### Paleidimas
1. Susikurkite `.env` pagal pavyzdį:
	- `cp .env.example .env`
	- suveskite realias reikšmes: `DOMAIN`, `LETSENCRYPT_EMAIL`, `POSTGRES_PASSWORD`, `JWT_KEY`, `JWT_ISSUER`, `JWT_AUDIENCE`

2. Paleiskite production stack:
	- `docker compose -f docker-compose.prod.yml up -d --build`

3. Atidarykite naršyklėje:
	- `https://<jusu-domenas>/`