# RentgenoValdymoSistema

### Sukurimas

1. Linux
	- parsisiuskite docker packages
	- pradekite docker `sudo systemctl start docker`
	- aplanke kur yra docker-compose.yml darykite `sudo docker compose up --build`
	- nuoroda bus `http://<jusu-ip>:8080` ip galite rasti su `ip -4 addr show` konsoleje ir ieskokite tokio kaip `192.168.x.xxx`

2. Windows
	- parsisiuskite docker programa [text](https://www.docker.com/)
	- praeikite visus instaliavimo zingsnius
	- kai viska padaret ir docker nemeta, kad nebereikia nieko atsinaujinti, nuekit i programos aplanka kur yra docker-compose.yml ir darykit `sudo docker compose up --build`
	- nuoroda bus `http://<jusu-ip>:8080` ip galite rasti su `ipconfig` windows powershelle ir ieskokite tokio kaip `192.168.x.xxx`