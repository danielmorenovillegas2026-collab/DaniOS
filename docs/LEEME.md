# Publicar la web y la ISO

## 1. Personaliza la web

`./scripts/publish.sh` sustituye **`TU_USUARIO`** por tu usuario de GitHub
automáticamente. Si prefieres hacerlo a mano:

```bash
sed -i 's/TU_USUARIO/tu-usuario/g' web/index.html
```

Prueba en local:

```bash
python3 -m http.server -d web 8000
# abre http://localhost:8000
```

## 2. Súbela a GitHub Pages

```bash
git init
git add .
git commit -m "DaniOS 1.0"
git branch -M main
git remote add origin https://github.com/tu-usuario/DaniOS.git
git push -u origin main
```

En el repositorio: **Settings → Pages → Source: GitHub Actions**.
El workflow `pages.yml` publica `web/` en
`https://tu-usuario.github.io/DaniOS/` con cada push.

## 3. Publica las ISOs

Hay dos ediciones (AMD y NVIDIA). Cada ISO pesa ~2,7 GB y GitHub limita cada
archivo de un release a **2 GiB**, así que cada una se parte en dos. Lo más
cómodo es dejar que `publish.sh` lo haga todo (partes, sumas, web, commit,
push, release y Pages):

```bash
brew install gh               # Bazzite ya trae Homebrew
gh auth login
./scripts/publish.sh
```

A mano:

```bash
./scripts/split-iso.sh out/DaniOS-amd-amd64-1.1-.iso
./scripts/split-iso.sh out/DaniOS-nvidia-1.1.iso
./scripts/update-web.sh       # tamaños y SHA-256 reales en la web
# dist/ tendrá las partes de las dos, las sumas y unir.sh

gh release create v1.0 dist/* \
  --title "DaniOS 1.0 «Café»" \
  --notes "Base Debian 13 trixie. Ediciones AMD e NVIDIA. GNOME, KDE, XFCE y Cinnamon."
```

Los enlaces `releases/latest/download/...` de la web funcionarán solos.
Para unir las partes: `bash unir.sh DaniOS-amd-amd64-1.1-.iso`.

## 4. Dominio propio (opcional)

- **GitHub Pages**: añade un archivo `web/CNAME` con tu dominio y configura
  el DNS (`CNAME` → `tu-usuario.github.io`). HTTPS es gratis.
- **Cloudflare R2** (si algún día la ISO crece): 10 GB gratis y sin coste de
  salida si pasa por Cloudflare.

## 5. Antes de repartirla

- Comprueba el SHA-256 publicado contra la ISO descargada.
- Indica que DaniOS es un proyecto personal **no afiliado a Debian**.
- Si va a usarla gente fuera de tu casa, ponle contraseña al usuario
  (`sudo passwd tu_usuario`) y borra el autologin.
