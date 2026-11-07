# 99 · Limpieza

Borrar las demos (si no lo hiciste al final de cada una):

```bash
kubectl delete namespace demo-basicos demo-red-config --ignore-not-found
```

Borrar el cluster completo (libera RAM y los puertos 8080 y 30080):

```bash
k3d cluster delete crayones
```

Esto también elimina el contexto `k3d-crayones` de tu `~/.kube/config`.

Para recuperar espacio en disco, puedes borrar las imágenes descargadas:

```bash
docker image rm rancher/k3s:v1.36.5-k3s1 ghcr.io/matias-craftech/kubernetes-explicado-con-crayones/app-saludo:v1
```

¿Lo quieres de nuevo? Ejecuta `k3d cluster create --config 00-setup/k3d-cluster.yaml` y listo.
