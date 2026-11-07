# syntax=docker/dockerfile:1
FROM python:3.13-alpine

# Vincula la imagen al repo en GitHub Container Registry
LABEL org.opencontainers.image.source=https://github.com/matias-craftech/kubernetes-explicado-con-crayones
LABEL org.opencontainers.image.description="app-saludo: app de ejemplo del taller Kubernetes explicado con crayones"

# Logs sin buffer: los print() aparecen al instante en `kubectl logs`
ENV PYTHONUNBUFFERED=1

WORKDIR /code
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .

# No corremos como root dentro del contenedor
RUN adduser -D -u 10001 app
USER 10001

EXPOSE 8000
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "1", "--access-logfile", "-", "app:app"]
