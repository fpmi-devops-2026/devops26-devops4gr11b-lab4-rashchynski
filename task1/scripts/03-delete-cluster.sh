#!/usr/bin/env bash
# Задание 1. Удаление локального кластера kind.

set -euo pipefail

CLUSTER_NAME="lab4"
echo "==> Удаление кластера '${CLUSTER_NAME}'"
kind delete cluster --name "${CLUSTER_NAME}"
