# Kubernetes explicado con crayones 🖍️

Material práctico del taller **Introducción a Kubernetes**. Vas a levantar un cluster de Kubernetes en tu propia máquina con [k3d](https://k3d.io/) y, sobre él, desplegar, escalar, exponer y configurar una aplicación sencilla.

Funciona en **macOS** (Intel y Apple Silicon) y **Linux** (amd64 y arm64).

## Antes del taller

1. Clona este repo:
   ```bash
   git clone https://github.com/matias-craftech/kubernetes-explicado-con-crayones.git
   cd kubernetes-explicado-con-crayones
   ```
2. Sigue los pasos de **[00-setup](00-setup/README.md)**: instalar Docker, kubectl y k3d, y crear el cluster.
3. Verifica que todo funcione:
   ```bash
   ./00-setup/check-entorno.sh
   kubectl get nodes
   ```

Si llegas al taller con `kubectl get nodes` mostrando 3 nodos `Ready`, ya está todo listo.

## Agenda (3 horas)

| Horario | Bloque | Tipo |
|---|---|---|
| 00:00 – 00:10 | Bienvenida y objetivos | Charla |
| 00:10 – 00:25 | Verificación del entorno y resolución de problemas | Práctica |
| 00:25 – 01:05 | Teoría: el problema que resuelve un orquestador, arquitectura de Kubernetes, modelo declarativo | Charla |
| 01:05 – 01:15 | Pausa | — |
| 01:15 – 02:00 | **[Demo 1](01-demo-basicos/README.md)**: Namespace, Pod, Deployment (autorreparación, escalado, rolling update y rollback), Service NodePort | Práctica |
| 02:00 – 02:40 | **[Demo 2](02-demo-red-y-config/README.md)**: Service ClusterIP, Ingress, ConfigMap y Secret | Práctica |
| 02:40 – 02:50 | Desafíos (al final de la demo 2) | Práctica |
| 02:50 – 03:00 | Cierre, preguntas y recursos | Charla |

## Estructura del repo

```
00-setup/               Instalación de herramientas, verificación y configuración del cluster k3d
01-demo-basicos/        Demo 1: Namespace, Pod, Deployment, Service NodePort
02-demo-red-y-config/   Demo 2: Service ClusterIP, Ingress, ConfigMap, Secret + desafíos
apps/app-saludo/        Código de la aplicación que desplegamos (Flask)
99-cleanup/             Cómo borrar todo al terminar
```

Cada demo tiene un `README.md` con los comandos paso a paso y una sección **👀 Qué observar** que explica qué mirar en cada momento. Los manifiestos (`k8s/*.yaml`) tienen comentarios línea por línea: vale la pena leerlos.

## Chuleta de kubectl

| Comando | Para qué |
|---|---|
| `kubectl get <tipo> -n <ns>` | Listar recursos (`pods`, `deploy`, `svc`, `ingress`, `cm`, `secret`, `all`) |
| `kubectl get pods -o wide` | Ver también la IP y el nodo de cada pod |
| `kubectl describe <tipo> <nombre> -n <ns>` | Detalle y **eventos** (lo primero que hay que mirar cuando algo falla) |
| `kubectl logs <pod> -n <ns>` | Logs del contenedor (`-f` para seguirlos) |
| `kubectl exec -it <pod> -n <ns> -- sh` | Abrir una shell dentro del contenedor |
| `kubectl apply -f <archivo o carpeta>` | Declarar el estado deseado |
| `kubectl delete -f <archivo>` | Borrar lo declarado en el archivo |
| `kubectl explain deployment.spec` | Documentación de cada campo, desde la terminal |

## Para seguir aprendiendo

- [Documentación oficial de Kubernetes (en español)](https://kubernetes.io/es/docs/concepts/)
- [The Illustrated Children's Guide to Kubernetes](https://www.cncf.io/phippy/the-childrens-illustrated-guide-to-kubernetes/): Kubernetes explicado con crayones, literalmente
- [Tutorial interactivo "Kubernetes Basics"](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [Documentación de k3d](https://k3d.io/) y de [k3s](https://docs.k3s.io/)
- [k9s](https://k9scli.io/): interfaz de terminal para explorar el cluster
