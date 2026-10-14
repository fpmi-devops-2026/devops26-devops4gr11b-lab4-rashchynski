#!/usr/bin/env bash
# Задание 1. Установка утилит для работы с локальным кластером Kubernetes.
#
# Требуется: macOS + Homebrew + Docker Desktop.
# kind использует Docker в качестве провайдера нод кластера,
# поэтому Docker-демон должен быть запущен.

set -euo pipefail

echo "==> Проверка Docker Desktop"
if ! docker info >/dev/null 2>&1; then
  echo "Docker-демон не запущен. Запускаю Docker Desktop..."
  open -a Docker
  echo "Ожидание запуска демона Docker..."
  for _ in $(seq 1 60); do
    if docker info >/dev/null 2>&1; then
      echo "Docker готов."
      break
    fi
    sleep 5
  done
  docker info >/dev/null 2>&1 || { echo "Docker так и не запустился."; exit 1; }
else
  echo "Docker уже запущен."
fi

echo "==> Установка kind (если не установлен)"
if command -v kind >/dev/null 2>&1; then
  echo "kind уже установлен: $(kind version)"
else
  brew install kind
fi

echo "==> Проверка kubectl"
if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl не найден. Установите его (например, через Docker Desktop или: brew install kubectl)."
  exit 1
fi

echo
echo "Версии установленных утилит:"
kind version
kubectl version --client
docker version --format 'docker client {{.Client.Version}} / server {{.Server.Version}}'
