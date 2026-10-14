# Overview

Report on LabRabota4 — «Методы и средства оркестрации в многоконтейнерных
системах» (Kubernetes, kind).

# Usage

To check, please, preview the report by [docs/report.md](docs/report.md).

Исходные файлы по заданиям лежат в каталогах `task1/`, `task2/`, `task3/`.

# Repository structure

```
task1/                      # Задание 1. Подготовка окружения и создание кластера
  kind-config.yaml          #   конфигурация кластера kind (1 control-plane + 2 worker)
  scripts/                  #   скрипты установки утилит и управления кластером
    01-install-tools.sh
    02-create-cluster.sh
    03-delete-cluster.sh
task2/                      # Задание 2. Ресурсы Kubernetes (pods, тома, ReplicaSet)
  pod-volume.yaml           #   под с томом emptyDir, общим для двух контейнеров
  pvc.yaml                  #   PersistentVolumeClaim
  pvc-pod.yaml              #   под, монтирующий PVC (данные переживают под)
  replicaset.yaml           #   ReplicaSet с 3 репликами nginx
task3/                      # Задание 3. Развёртывание приложения (Deployment)
  configmap.yaml            #   ConfigMap (env + файл index.html)
  secret.yaml               #   Secret (API_KEY)
  deployment.yaml           #   Deployment приложения (3 реплики, RollingUpdate)
  service.yaml              #   Service типа NodePort (порт 30000)
  ingress.yaml              #   Ingress (host lab4.local -> service web)
docs/
  report.md                 # отчёт по лабораторной работе
```

# Author

Ращинский \<Имя Отчество\>, группа 11б.

# Additional Notes

Репозиторий: https://github.com/fpmi-devops-2026/devops26-devops4gr11b-lab4-rashchynski

Кратко о содержании:
- **Задание 1** — подготовка окружения и создание локального кластера (kind + kubectl).
- **Задание 2** — знакомство с ресурсами Kubernetes (pods, тома, ReplicaSet).
- **Задание 3** — развёртывание приложения (Deployment).
