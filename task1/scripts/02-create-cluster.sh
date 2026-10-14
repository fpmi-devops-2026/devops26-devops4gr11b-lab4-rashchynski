#!/usr/bin/env bash
# Задание 1. Создание локального кластера Kubernetes при помощи kind.
# Запускать из корня репозитория.

set -euo pipefail

CLUSTER_NAME="lab4"
CONFIG="task1/kind-config.yaml"

echo "==> Создание кластера '${CLUSTER_NAME}' по конфигу ${CONFIG}"
kind create cluster --name "${CLUSTER_NAME}" --config "${CONFIG}"

echo
echo "==> Проверка кластера"
kubectl cluster-info
kubectl config current-context
kubectl get nodes -o wide
kubectl get namespaces
