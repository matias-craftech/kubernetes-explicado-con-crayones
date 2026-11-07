#!/usr/bin/env bash
# Verifica que la máquina tenga lo necesario para el taller. Funciona en macOS y Linux.
# Uso: ./00-setup/check-entorno.sh
set -u

OK="\033[32m✔\033[0m"; FAIL="\033[31m✘\033[0m"; WARN="\033[33m!\033[0m"
errores=0

ok()   { printf "  $OK %s\n" "$1"; }
fail() { printf "  $FAIL %s\n" "$1"; errores=$((errores + 1)); }
warn() { printf "  $WARN %s\n" "$1"; }

echo "Sistema: $(uname -s) $(uname -m)"
echo

echo "Herramientas:"
for cmd in docker kubectl k3d curl; do
  if command -v "$cmd" >/dev/null 2>&1; then ok "$cmd instalado"; else fail "$cmd no está instalado (ver 00-setup/README.md)"; fi
done
command -v k9s >/dev/null 2>&1 && ok "k9s instalado (opcional)" || warn "k9s no está instalado (opcional, pero recomendado)"
echo

echo "Docker:"
if docker info >/dev/null 2>&1; then
  ok "el daemon de Docker responde"
  mem=$(docker info --format '{{.MemTotal}}' 2>/dev/null || echo 0)
  mem_gb=$((mem / 1024 / 1024 / 1024))
  if [ "$mem_gb" -ge 4 ]; then ok "Docker tiene ${mem_gb} GB de RAM disponibles"
  else warn "Docker tiene ${mem_gb} GB de RAM; se recomiendan al menos 4 GB"; fi
else
  fail "Docker no responde. ¿Está iniciado Docker Desktop / el servicio docker? En Linux, ¿tu usuario está en el grupo docker?"
fi
echo

echo "Versiones:"
command -v kubectl >/dev/null 2>&1 && echo "  kubectl: $(kubectl version --client 2>/dev/null | head -1)"
command -v k3d     >/dev/null 2>&1 && echo "  k3d:     $(k3d version 2>/dev/null | head -1)"
echo

echo "Puertos libres (los usa el cluster):"
for port in 8080 30080; do
  if (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null; then
    if k3d cluster list 2>/dev/null | grep -q '^crayones'; then
      ok "puerto $port en uso por el cluster crayones"
    else
      fail "el puerto $port está ocupado por otro proceso"
    fi
  else
    ok "puerto $port libre"
  fi
done
echo

if [ "$errores" -eq 0 ]; then
  printf "$OK Todo listo. Siguiente paso: k3d cluster create --config 00-setup/k3d-cluster.yaml\n"
else
  printf "$FAIL Hay %d problema(s) para resolver antes del taller.\n" "$errores"
  exit 1
fi
