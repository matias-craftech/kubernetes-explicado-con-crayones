"""app-saludo: una app mínima para jugar con Kubernetes.

Rutas:
  /        saludo + nombre del pod que respondió (útil para ver el balanceo)
  /de /it  saludos fijos en el código
  /en      saludo leído de la variable de entorno ENG_MSG (ConfigMap)
  /color   color leído de la variable de entorno COLOR (ConfigMap)
  /secret  contenido del archivo indicado en SECRETS_PATH (Secret montado)
  /healthz chequeo de salud para las probes
"""
import os
import socket

from flask import Flask

app = Flask(__name__)
POD = socket.gethostname()


def responder(msg):
    print(msg.strip(), flush=True)
    return msg


@app.route("/")
def hola():
    return responder(f"¡Hola gente! Soy app-saludo y me respondió el pod: {POD}\n")


@app.route("/de")
def hola_de():
    return responder("Hallo Leute! Ich bin eine einfache App.\n")


@app.route("/it")
def hola_it():
    return responder("Ciao a tutti! Sono una semplice app.\n")


@app.route("/en")
def hola_en():
    msg = os.environ.get("ENG_MSG")
    if not msg:
        return responder("ENG_MSG no está definida. ¿Le pasaste el ConfigMap al pod?\n"), 500
    return responder(msg.rstrip("\n") + "\n")


@app.route("/color")
def color():
    return responder(f"Mi color configurado es: {os.environ.get('COLOR', 'sin configurar')}\n")


@app.route("/secret")
def secreto():
    path = os.environ.get("SECRETS_PATH", "/run/secrets/SECRET_MSG")
    try:
        with open(path, encoding="utf-8") as f:
            return responder(f.read().rstrip("\n") + "\n")
    except OSError:
        return responder(f"No encuentro el secreto en {path}. ¿Montaste el Secret?\n"), 500


@app.route("/healthz")
def healthz():
    return "ok\n"


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
