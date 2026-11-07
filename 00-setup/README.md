# 00 · Preparar el entorno

> **Haz esto antes del taller.** Las descargas (Docker, imágenes de k3s) pesan varios cientos de MB y el wifi del aula no siempre ayuda.

Necesitamos cuatro cosas:

| Herramienta | Para qué |
|---|---|
| **Docker** | k3d crea cada nodo de Kubernetes como un contenedor de Docker |
| **kubectl** | La CLI para hablar con cualquier cluster de Kubernetes |
| **k3d** | Crea clusters [k3s](https://k3s.io/) (Kubernetes liviano) dentro de Docker |
| **k9s** *(opcional)* | Interfaz de terminal para ver el cluster en vivo |

Requisitos de la máquina: al menos 4 GB de RAM libres para Docker y unos 3 GB de disco.

## 1. Instalar las herramientas

### macOS

Con [Homebrew](https://brew.sh/):

```bash
brew install kubectl k3d k9s
```

Docker: instala [Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/) (elige la versión para tu chip: Apple Silicon o Intel) y ábrelo al menos una vez. Alternativas livianas que también funcionan con k3d: [OrbStack](https://orbstack.dev/) o [Colima](https://github.com/abiosoft/colima).

### Linux

Docker Engine: sigue la [guía oficial para tu distribución](https://docs.docker.com/engine/install/) y después los [pasos post-instalación](https://docs.docker.com/engine/install/linux-postinstall/) para usar Docker sin `sudo`:

```bash
sudo usermod -aG docker $USER
# Cierra sesión y vuelve a entrar (o ejecuta `newgrp docker`) para que tome el grupo
```

kubectl ([documentación oficial](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)):

```bash
ARCH=$(uname -m | sed 's/x86_64/amd64/; s/aarch64/arm64/')
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
```

k3d ([documentación oficial](https://k3d.io/stable/#installation)):

```bash
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```

k9s (opcional): ver las [opciones de instalación](https://k9scli.io/topics/install/).

## 2. Verificar

Desde la raíz del repo:

```bash
./00-setup/check-entorno.sh
```

Tiene que terminar con `✔ Todo listo`. Si algo falla, el mensaje indica qué revisar.

## 3. Crear el cluster

```bash
k3d cluster create --config 00-setup/k3d-cluster.yaml
```

Tarda uno o dos minutos la primera vez (descarga la imagen de k3s). Este comando:

- crea **1 nodo server** (control plane) y **2 nodos agent** (workers), cada uno como un contenedor de Docker;
- publica `localhost:8080` → Ingress del cluster (demo 2) y `localhost:30080` → NodePort (demo 1);
- configura `kubectl` para que apunte al cluster nuevo (contexto `k3d-crayones`).

Comprobamos:

```bash
kubectl config current-context   # k3d-crayones
kubectl get nodes                # 3 nodos en estado Ready
docker ps                        # ¡los "nodos" son contenedores!
```

### Exportar el kubeconfig a un archivo propio

El **kubeconfig** es el archivo que le dice a `kubectl` a qué cluster conectarse y con qué credenciales. k3d ya agregó el cluster a `~/.kube/config`, pero conviene tener también un archivo separado para este cluster. Así no se mezcla con otros clusters que uses:

```bash
k3d kubeconfig write crayones --output ~/.kube/crayones.yaml
chmod 600 ~/.kube/crayones.yaml
```

Para usarlo:

```bash
export KUBECONFIG=~/.kube/crayones.yaml   # vale para la terminal actual
kubectl get nodes
unset KUBECONFIG                          # vuelve a usar ~/.kube/config
```

> ⚠️ Este archivo contiene un certificado con permisos de **administrador** del cluster: trátalo como una contraseña y no lo subas a ningún repositorio.

Prueba también la imagen de la app, así queda descargada antes del taller:

```bash
docker pull ghcr.io/matias-craftech/kubernetes-explicado-con-crayones/app-saludo:v1
```

## Problemas frecuentes

| Síntoma | Causa probable | Qué hacer |
|---|---|---|
| `Cannot connect to the Docker daemon` | Docker no está corriendo | Abre Docker Desktop / `sudo systemctl start docker` |
| `permission denied ... docker.sock` (Linux) | Tu usuario no está en el grupo `docker` | Ver pasos post-instalación arriba |
| `port is already allocated` al crear el cluster | Otro proceso usa el 8080 o el 30080 | Libera el puerto o cámbialo en `k3d-cluster.yaml` (y usa el nuevo en las demos) |
| `kubectl get nodes` responde con otro cluster | El contexto activo es otro | `kubectl config use-context k3d-crayones` |
| Nodos en `NotReady` por mucho tiempo | Poca RAM para Docker | Aumenta la memoria en Docker Desktop → Settings → Resources |
| Ya existe un cluster `crayones` roto | Restos de un intento anterior | `k3d cluster delete crayones` y crearlo de nuevo |
