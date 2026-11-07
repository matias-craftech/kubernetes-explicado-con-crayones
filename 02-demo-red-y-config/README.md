# Demo 2 · Red y configuración: Service, Ingress, ConfigMap y Secret

**Duración estimada:** 40 minutos · **Namespace:** `demo-red-config`

Objetivos:
- ver cómo se comunican los pods **dentro** del cluster y cómo se exponen **hacia afuera** de forma ordenada;
- separar la configuración del código: la misma imagen, distinta configuración.

> Todos los comandos se ejecutan desde la raíz del repo.

Terminal de apoyo (opcional):

```bash
kubectl get pods,svc,ingress -n demo-red-config --watch
```

---

## Paso 1 · La app, sin exponer

```bash
kubectl apply -f 02-demo-red-y-config/k8s/1-namespace.yaml
kubectl apply -f 02-demo-red-y-config/k8s/2-deployment.yaml
kubectl apply -f 02-demo-red-y-config/k8s/3-service-clusterip.yaml
kubectl get svc -n demo-red-config
```

👀 **Qué observar:** el Service es de tipo `ClusterIP` y no tiene `EXTERNAL-IP` ni NodePort. Desde tu máquina no se puede llegar directamente.

### 1a · Desde adentro del cluster: DNS de servicios

Levantamos un pod temporal con `curl` y le hablamos al Service **por su nombre**:

```bash
kubectl run curl-tmp --rm -it --restart=Never --image=curlimages/curl -n demo-red-config -- \
  sh -c 'curl -s http://app-saludo/; curl -s http://app-saludo.demo-red-config.svc.cluster.local/'
```

👀 **Qué observar:** dentro del cluster, cada Service tiene un nombre DNS. Así se encuentran las aplicaciones entre sí (por ejemplo, un backend y su base de datos), sin conocer IPs.

### 1b · Desde tu máquina: port-forward (solo para depurar)

```bash
kubectl port-forward service/app-saludo 9090:80 -n demo-red-config
# en otra terminal:
curl localhost:9090/
```

Corta el port-forward con `Ctrl+C`. Sirve para depurar, no para exponer una app a usuarios: el túnel depende de tu terminal y de tus credenciales.

## Paso 2 · Ingress: la puerta de entrada HTTP

```bash
kubectl apply -f 02-demo-red-y-config/k8s/4-ingress.yaml
kubectl get ingress -n demo-red-config
```

Probamos:

```bash
curl http://saludo.localhost:8080/
curl http://localhost:8080/                              # 404: ninguna regla coincide con este host
curl -H "Host: saludo.localhost" http://localhost:8080/  # lo que hace el navegador por detrás
```

También puedes abrir <http://saludo.localhost:8080/> en el navegador.

👀 **Qué observar:**
- Un solo punto de entrada (puerto 80 del cluster) puede atender **muchas** apps, eligiendo el destino según el host o la ruta del pedido.
- El Ingress solo define reglas; quien las ejecuta es el **Ingress Controller** (en k3s, Traefik). Puedes verlo con `kubectl get pods -n kube-system | grep traefik`.

> Camino del tráfico: `saludo.localhost:8080` → `serverlb` de k3d → puerto 80 del cluster → Traefik → Service `app-saludo` → pod.

## Paso 3 · Sin configuración, la app se queja

```bash
curl http://saludo.localhost:8080/en
curl http://saludo.localhost:8080/color
curl http://saludo.localhost:8080/secret
```

👀 **Qué observar:** `/en` y `/secret` devuelven error, y `/color` dice `sin configurar`. La app espera que alguien le pase configuración.

## Paso 4 · ConfigMap y Secret

```bash
kubectl apply -f 02-demo-red-y-config/k8s/5-configmap.yaml
kubectl apply -f 02-demo-red-y-config/k8s/6-secret.yaml
kubectl get configmap,secret -n demo-red-config
kubectl describe configmap app-saludo-config -n demo-red-config
kubectl describe secret app-saludo-secret -n demo-red-config     # no muestra el valor...
```

...pero "no mostrar" no es lo mismo que "proteger":

```bash
kubectl get secret app-saludo-secret -n demo-red-config -o jsonpath='{.data.SECRET_MSG}' | base64 -d; echo
```

> ⚠️ **base64 no es cifrado.** Cualquiera con permiso para leer Secrets en el namespace puede ver su contenido. Los Secrets se protegen con permisos (RBAC), con cifrado en etcd y, sobre todo, **no subiéndolos nunca a git**. Más detalles en las [buenas prácticas de la documentación oficial](https://kubernetes.io/docs/concepts/security/secrets-good-practices/).

Crear los objetos no alcanza: hay que decirle al pod que los use.

```bash
diff 02-demo-red-y-config/k8s/2-deployment.yaml 02-demo-red-y-config/k8s/7-deployment-con-config.yaml
kubectl apply -f 02-demo-red-y-config/k8s/7-deployment-con-config.yaml
kubectl rollout status deployment/app-saludo -n demo-red-config
```

```bash
curl http://saludo.localhost:8080/en
curl http://saludo.localhost:8080/color
curl http://saludo.localhost:8080/secret
```

Miramos desde adentro de un pod:

```bash
kubectl exec -it deploy/app-saludo -n demo-red-config -- sh
  printenv | grep -E 'ENG_MSG|COLOR'
  ls /run/secrets/app-saludo/
  cat /run/secrets/app-saludo/SECRET_MSG
  exit
```

👀 **Qué observar:** el ConfigMap llegó como **variables de entorno** y el Secret como **archivo**. Son las dos formas habituales de inyectar configuración.

## Paso 5 · ¿Qué pasa si cambio la configuración?

```bash
kubectl patch configmap app-saludo-config -n demo-red-config -p '{"data":{"color":"violeta"}}'
curl http://saludo.localhost:8080/color      # ¡sigue diciendo naranja!
```

👀 **Qué observar:** las variables de entorno se leen **al arrancar** el contenedor. Para que tomen el valor nuevo hay que recrear los pods:

```bash
kubectl rollout restart deployment/app-saludo -n demo-red-config
kubectl rollout status deployment/app-saludo -n demo-red-config
curl http://saludo.localhost:8080/color      # violeta
```

En cambio, los ConfigMaps y Secrets **montados como volumen** se actualizan solos dentro del pod, con algo de demora ([documentación](https://kubernetes.io/docs/concepts/configuration/configmap/#mounted-configmaps-are-updated-automatically)).

## Para cerrar la demo

```bash
kubectl delete namespace demo-red-config
```

### Resumen

| Recurso | En una frase |
|---|---|
| Service ClusterIP | Nombre DNS e IP estables, solo dentro del cluster |
| Ingress | Reglas HTTP (host/ruta → Service) que ejecuta un Ingress Controller |
| ConfigMap | Configuración no sensible, separada de la imagen |
| Secret | Datos sensibles; base64 **no** es cifrado |

---

## Desafíos (ejercicio integrador)

Para quien termina antes, o para seguir en casa:

1. **Otro host.** Agrega al Ingress una regla para `hola.localhost` que apunte al mismo Service y pruébala con `curl http://hola.localhost:8080/`.
2. **Otra app, otro namespace.** Despliega la app de la demo 1 en `demo-basicos` (Deployment + Service ClusterIP) y crea un Ingress para `basicos.localhost`. ¿Puede un Ingress de un namespace apuntar a un Service de otro?
3. **Secret desde la CLI.** Crea el Secret sin escribir base64 a mano: `kubectl create secret generic mi-secreto --from-literal=SECRET_MSG='hola' -n demo-red-config --dry-run=client -o yaml`. ¿Qué hace `--dry-run=client -o yaml`?
4. **Todo junto.** Agrega un ConfigMap montado como **volumen** y verifica que el archivo cambia dentro del pod al editar el ConfigMap, sin reiniciar nada.
