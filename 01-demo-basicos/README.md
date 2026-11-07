# Demo 1 · Lo básico: Namespace, Pod, Deployment y Service

**Duración estimada:** 45 minutos · **Namespace:** `demo-basicos`

Objetivo: entender que en Kubernetes **no damos órdenes, declaramos un estado deseado**, y que el cluster trabaja todo el tiempo para que la realidad coincida con lo que declaramos.

> Todos los comandos se ejecutan desde la raíz del repo, con el cluster de [00-setup](../00-setup/README.md) creado.

**Sugerencia:** abre una segunda terminal y deja corriendo esto durante toda la demo, para ver los cambios en vivo:

```bash
kubectl get pods -n demo-basicos -o wide --watch
```

(o usa `k9s -n demo-basicos`)

---

## Paso 0 · ¿Con qué cluster estoy hablando?

```bash
kubectl config current-context        # k3d-crayones
kubectl get nodes -o wide             # 1 server + 2 agents
kubectl get pods -A                   # pods del sistema que ya vienen con k3s
```

👀 **Qué observar:** antes de hacer nada, el cluster ya tiene pods corriendo en `kube-system` (DNS, Traefik, etc.). Kubernetes también se administra a sí mismo con pods.

## Paso 1 · Namespace

```bash
kubectl apply -f 01-demo-basicos/k8s/1-namespace.yaml
kubectl get namespaces
```

👀 **Qué observar:** `apply` no "crea": **declara**. Vuelve a ejecutarlo y fíjate que dice `unchanged`.

## Paso 2 · Un Pod suelto

```bash
kubectl apply -f 01-demo-basicos/k8s/2-pod.yaml
kubectl get pods -n demo-basicos -o wide
kubectl describe pod saludo-suelto -n demo-basicos     # mira la sección Events al final
kubectl logs saludo-suelto -n demo-basicos
```

Entramos al pod y le hablamos a la app desde adentro:

```bash
kubectl exec -it saludo-suelto -n demo-basicos -- sh
  wget -qO- localhost:8000/
  hostname          # el nombre del pod
  exit
```

Ahora lo borramos:

```bash
kubectl delete pod saludo-suelto -n demo-basicos
kubectl get pods -n demo-basicos
```

👀 **Qué observar:** el pod **no vuelve**. Nadie le pidió a Kubernetes que lo mantuviera vivo. Un pod suelto es como un contenedor de `docker run`: si muere, muere.

## Paso 3 · Deployment: el estado deseado

```bash
kubectl apply -f 01-demo-basicos/k8s/3-deployment.yaml
kubectl get deployments,replicasets,pods -n demo-basicos -o wide
```

👀 **Qué observar:** un Deployment creó un ReplicaSet, que creó 3 pods. Fíjate en la columna `NODE`: el scheduler repartió los pods entre los nodos.

### 3a · Autorreparación

Borra un pod cualquiera (copia un nombre de la lista):

```bash
kubectl delete pod <nombre-de-un-pod> -n demo-basicos
kubectl get pods -n demo-basicos
```

👀 **Qué observar:** aparece uno nuevo en segundos. El estado deseado dice 3; el controlador vio 2 y corrigió. Esto es el **ciclo de reconciliación**.

Bonus para valientes: simula la caída de un nodo entero.

```bash
docker stop k3d-crayones-agent-0
kubectl get nodes          # tras ~40 s pasa a NotReady
# Kubernetes espera unos 5 minutos antes de reubicar los pods de un nodo caído (no esperes en vivo)
docker start k3d-crayones-agent-0
```

### 3b · Escalado

```bash
kubectl scale deployment app-saludo --replicas=6 -n demo-basicos
kubectl get pods -n demo-basicos -o wide
kubectl scale deployment app-saludo --replicas=3 -n demo-basicos
```

> ⚠️ `kubectl scale` es **imperativo**: el YAML sigue diciendo `replicas: 3`. Si alguien vuelve a aplicar el manifiesto, gana el YAML. En el día a día se cambia el archivo y se hace `apply` (y el archivo vive en git).

## Paso 4 · Service NodePort: acceso estable

```bash
kubectl apply -f 01-demo-basicos/k8s/4-service-nodeport.yaml
kubectl get service app-saludo -n demo-basicos
kubectl get endpointslices -n demo-basicos      # las IPs de los pods detrás del Service
```

Desde tu máquina:

```bash
for i in $(seq 1 6); do curl -s localhost:30080/; done
```

👀 **Qué observar:** responden pods distintos. El Service reparte el tráfico entre todas las réplicas, y no nos importa qué IP tiene cada una.

> El camino del tráfico: `localhost:30080` → contenedor `serverlb` de k3d → puerto 30080 de un nodo → Service → algún pod.

## Paso 5 · Actualización progresiva (rolling update) y rollback

En una terminal, deja un loop que consulte la app sin parar:

```bash
while true; do curl -s localhost:30080/color; sleep 0.5; done
```

En otra, cambiamos la configuración del Deployment:

```bash
kubectl set env deployment/app-saludo COLOR=verde -n demo-basicos
kubectl rollout status deployment/app-saludo -n demo-basicos
```

👀 **Qué observar:** el loop pasa de `azul` a `verde` **sin cortes**. Kubernetes levanta pods nuevos y recién después baja los viejos (mira cómo aparece un ReplicaSet nuevo con `kubectl get rs -n demo-basicos`).

Ahora, un despliegue que sale mal: una imagen que no existe.

```bash
kubectl set image deployment/app-saludo app-saludo=ghcr.io/matias-craftech/kubernetes-explicado-con-crayones/app-saludo:no-existe -n demo-basicos
kubectl get pods -n demo-basicos
```

👀 **Qué observar:** el pod nuevo queda en `ErrImagePull` / `ImagePullBackOff`, pero **los pods viejos siguen atendiendo**: el loop no se cortó. El rollout se frena solo.

Volvemos atrás:

```bash
kubectl rollout history deployment/app-saludo -n demo-basicos
kubectl rollout undo deployment/app-saludo -n demo-basicos
kubectl rollout status deployment/app-saludo -n demo-basicos
```

## Para cerrar la demo

```bash
kubectl delete namespace demo-basicos      # borra TODO lo que hay adentro
```

### Resumen

| Recurso | En una frase |
|---|---|
| Namespace | Separación lógica de recursos dentro del cluster |
| Pod | Uno o más contenedores que comparten red; efímero |
| Deployment | Estado deseado de N pods iguales; los recrea, escala y actualiza |
| Service | Nombre e IP estables que reparten tráfico entre pods (por labels) |

Comandos clave: `apply`, `get`, `describe`, `logs`, `exec`, `delete`, `scale`, `rollout`.
