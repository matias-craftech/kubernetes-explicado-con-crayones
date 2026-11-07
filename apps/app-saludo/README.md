# app-saludo

App web mínima (Flask + gunicorn) que usamos en las dos demos. Escucha en el puerto `8000`.

Imagen: `ghcr.io/matias-craftech/kubernetes-explicado-con-crayones/app-saludo:v1` (linux/amd64 y linux/arm64).

| Ruta | Qué devuelve | Qué sirve para mostrar |
|---|---|---|
| `/` | Saludo + nombre del pod | Balanceo entre réplicas |
| `/de`, `/it` | Saludos fijos | — |
| `/en` | Variable de entorno `ENG_MSG` | ConfigMap como variable de entorno |
| `/color` | Variable de entorno `COLOR` | ConfigMap como variable de entorno |
| `/secret` | Archivo indicado en `SECRETS_PATH` | Secret montado como volumen |
| `/healthz` | `ok` | Probes |

## Probarla con Docker (sin Kubernetes)

```bash
docker run --rm -p 8000:8000 -e ENG_MSG="Hello from Docker" \
  ghcr.io/matias-craftech/kubernetes-explicado-con-crayones/app-saludo:v1
curl localhost:8000/
curl localhost:8000/en
```

## Publicar la imagen (solo quien mantiene el repo)

La imagen se construye y publica **automáticamente** con GitHub Actions ([`.github/workflows/app-saludo-image.yml`](../../.github/workflows/app-saludo-image.yml)) cada vez que llega a `main` un cambio en `apps/app-saludo/src/`:

- publica `:v1` (definido en `APP_VERSION` dentro del workflow) y `:sha-<commit>`;
- para `linux/amd64` y `linux/arm64`;
- en los pull requests solo hace el build, para validar, sin publicar.

También se puede ejecutar a mano desde la pestaña **Actions → app-saludo image → Run workflow**.

Como se publica con el `GITHUB_TOKEN` del workflow, la imagen hereda la visibilidad del repo (pública) y no hace falta ningún token personal ([documentación de GitHub](https://docs.github.com/en/packages/managing-github-packages-using-github-actions-workflows/publishing-and-installing-a-package-with-github-actions)).

> Si un cambio en la app deja de ser compatible con las demos, sube `APP_VERSION` a `v2` en el workflow y actualiza los manifiestos.

### Alternativa: publicar desde tu máquina

Solo si Actions no está disponible. Requiere login en `ghcr.io` con un token **classic** con permiso `write:packages`, pasado por stdin (nunca escrito en archivos del repo):

```bash
gh auth token | docker login ghcr.io -u matias-craftech --password-stdin   # requiere: gh auth refresh -s write:packages
./build-push.sh
```

⚠️ Un paquete publicado a mano se crea **privado**. Conviene que la primera publicación la haga el workflow.
