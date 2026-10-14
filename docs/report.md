# Лабораторная работа №4

**Тема:** Методы и средства оркестрации в многоконтейнерных системах
**Дисциплина:** Непрерывное интегрирование и сборка программного обеспечения
**Автор:** Ращинский \<Имя Отчество\>, группа 11б
**Год:** 2026

---

## 1. Цель работы

Изучение создания кластера Kubernetes и работы с ним: настройка локального
кластера (kind + kubectl), знакомство с базовыми ресурсами Kubernetes
(pods, тома, ReplicaSet) и развёртывание приложения через Deployment.

## 2. Вариант задания

Вариант группы **11б**: согласно критериям оценивания (для групп 10–12)
выполняются **все три задания** лабораторной работы.

## 3. Задание 1. Подготовка окружения для локального кластера

### 3.1. Используемые инструменты

| Инструмент | Версия | Назначение |
|------------|--------|------------|
| Docker Desktop | 29.8.0 (aarch64) | Контейнерный движок; kind использует его как провайдер нод кластера |
| kind | v0.33.0 (darwin/arm64) | Запуск локального кластера Kubernetes в Docker-контейнерах |
| kubectl | v1.36.1 | Управление кластером из командной строки |
| Kubernetes (образ ноды) | v1.37.0 | Версия кластера, поднятого через kind |

На macOS Docker Desktop сам работает внутри Linux-виртуальной машины, а kind
запускает каждую ноду кластера как отдельный Docker-контейнер в этой VM. Так
и получается локальный кластер Kubernetes «в виртуальной машине».

### 3.2. Установка утилит

**Что делаем.** Устанавливаем `kind` через Homebrew. `kubectl` и Docker Desktop
в системе уже есть (kubectl входит в комплект Docker Desktop), поэтому их
отдельно ставить не нужно.

**Команда:**

```bash
brew install kind
```

**Результат:**

```text
🍺  /opt/homebrew/Cellar/kind/0.33.0: 10 files, 10.5MB
```

**Пояснение.** Homebrew скачал готовый бинарник `kind` версии 0.33.0 под
архитектуру Apple Silicon (arm64) и разместил его в `/opt/homebrew`. Команда
`kind` стала доступна в PATH.

### 3.3. Проверка версий утилит

**Что делаем.** Убеждаемся, что все три утилиты установлены и совместимы
между собой (клиент kubectl, движок Docker, сам kind).

**Команды:**

```bash
kind version
kubectl version --client
docker version --format 'Client {{.Client.Version}} / Server {{.Server.Version}}'
```

**Результат:**

```text
kind v0.33.0 go1.27.0 darwin/arm64

Client Version: v1.36.1
Kustomize Version: v5.8.1

Client 29.8.0 / Server 29.8.0
```

**Пояснение.** Все утилиты установлены корректно:
`kind v0.33.0` (сборка под darwin/arm64), `kubectl v1.36.1`, `docker` 29.8.0 —
причём у Docker совпадают версии клиента и сервера (демон запущен и доступен).

### 3.4. Конфигурация кластера

**Что делаем.** Описываем желаемую топологию кластера в файле конфигурации:
одна управляющая нода (control-plane) и две рабочие (worker). Для управляющей
ноды дополнительно пробрасываем на хост-машину порты 80, 443 и 30000–30002 —
они понадобятся в Заданиях 2–3, чтобы сервисы типов NodePort и Ingress были
доступны снаружи.

Полный файл: [`task1/kind-config.yaml`](../task1/kind-config.yaml). Ключевой
фрагмент:

```yaml
name: lab4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30000
        hostPort: 30000
  - role: worker
  - role: worker
```

**Пояснение.** Поле `nodes` задаёт состав кластера (1 + 2 ноды), а
`extraPortMappings` показывает, какие порты нод кластера «выставить» наружу,
на хост. Без этого проброса к сервисам внутри кластера не получилось бы
обратиться с Mac.

### 3.5. Создание кластера

**Что делаем.** Создаём кластер по подготовленному конфигу с именем `lab4`.

**Команда:**

```bash
kind create cluster --name lab4 --config task1/kind-config.yaml
```

**Результат:**

```text
Creating cluster "lab4" ...
 • Ensuring node image (kindest/node:v1.37.0) 🖼️
 ✓ Ensuring node image (kindest/node:v1.37.0) 🖼️
 • Preparing nodes 📦 📦 📦   ...
 ✓ Preparing nodes 📦 📦 📦
 • Writing configuration 📜  ...
 ✓ Writing configuration 📜
 • Starting control-plane 🕹️  ...
 ✓ Starting control-plane 🕹️
 • Installing CNI 🔌  ...
 ✓ Installing CNI 🔌
 • Installing StorageClass 💾  ...
 ✓ Installing StorageClass 💾
 • Joining worker nodes 🚜  ...
 ✓ Joining worker nodes 🚜
Set kubectl context to "kind-lab4"
```

**Пояснение.** kind скачал образ ноды `kindest/node:v1.37.0`, создал три
Docker-контейнера (control-plane и два worker), инициализировал control-plane,
установил сетевой плагин (CNI) и StorageClass, подключил worker-ноды и
переключил текущий контекст kubectl на `kind-lab4`.

### 3.6. Демонстрация работающего кластера

**Что делаем.** Проверяем, что кластер доступен, все ноды готовы, а
системные компоненты запущены.

**Команда — информация о кластере:**

```bash
kubectl cluster-info
```

**Результат:**

```text
Kubernetes control plane is running at https://127.0.0.1:52961
CoreDNS is running at https://127.0.0.1:52961/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

**Команда — текущий контекст:**

```bash
kubectl config current-context
```

**Результат:**

```text
kind-lab4
```

**Команда — список нод:**

```bash
kubectl get nodes -o wide
```

**Результат (все ноды в состоянии `Ready`):**

```text
NAME                 STATUS   ROLES           AGE   VERSION   INTERNAL-IP   OS-IMAGE                       CONTAINER-RUNTIME
lab4-control-plane   Ready    control-plane   26s   v1.37.0   172.29.0.4    Debian GNU/Linux 13 (trixie)   containerd://2.3.4
lab4-worker          Ready    <none>          12s   v1.37.0   172.29.0.2    Debian GNU/Linux 13 (trixie)   containerd://2.3.4
lab4-worker2         Ready    <none>          12s   v1.37.0   172.29.0.3    Debian GNU/Linux 13 (trixie)   containerd://2.3.4
```

**Команда — пространства имён:**

```bash
kubectl get ns
```

**Результат:**

```text
NAME                 STATUS   AGE
default              Active   19s
kube-node-lease      Active   19s
kube-public          Active   19s
kube-system          Active   19s
local-path-storage   Active   15s
```

**Команда — системные поды:**

```bash
kubectl get pods -n kube-system
```

**Результат (все поды `Running`):**

```text
NAME                                         READY   STATUS    RESTARTS   AGE
coredns-559f6c778d-49t4s                     1/1     Running   0          16s
coredns-559f6c778d-qtp89                     1/1     Running   0          16s
etcd-lab4-control-plane                      1/1     Running   0          24s
kindnet-mxr84                                1/1     Running   0          12s
kindnet-xmmgq                                1/1     Running   0          16s
kindnet-zt9pv                                1/1     Running   0          12s
kube-apiserver-lab4-control-plane            1/1     Running   0          24s
kube-controller-manager-lab4-control-plane   1/1     Running   0          24s
kube-proxy-584sj                             1/1     Running   0          12s
kube-proxy-m565w                             1/1     Running   0          16s
kube-proxy-vh5z8                             1/1     Running   0          12s
kube-scheduler-lab4-control-plane            1/1     Running   0          24s
```

**Команда — ноды кластера как Docker-контейнеры:**

```bash
docker ps --filter "label=io.x-k8s.kind.cluster=lab4"
```

**Результат:**

```text
NAMES                IMAGE                  STATUS
lab4-control-plane   kindest/node:v1.37.0   Up
lab4-worker          kindest/node:v1.37.0   Up
lab4-worker2         kindest/node:v1.37.0   Up
```

**Пояснение.** Кластер доступен по адресу control-plane, контекст переключён
на `kind-lab4`, все три ноды в состоянии `Ready`. Системные компоненты
(CoreDNS, etcd, kube-apiserver, kube-controller-manager, kube-scheduler,
kube-proxy, kindnet) запущены. Через `docker ps` видно, что каждая нода — это
отдельный Docker-контейнер, как и предполагает kind.

### 3.7. Вывод по заданию 1

Установлена утилита `kind`, проверена работоспособность `kubectl` и Docker.
По конфигурации [`task1/kind-config.yaml`](../task1/kind-config.yaml) успешно
создан локальный кластер Kubernetes `lab4` (v1.37.0) из трёх нод
(1 control-plane + 2 worker). Все ноды перешли в состояние `Ready`, системные
компоненты запущены. Кластер готов к выполнению Заданий 2 и 3.

Скрипты для воспроизведения: [`task1/scripts/01-install-tools.sh`](../task1/scripts/01-install-tools.sh),
[`task1/scripts/02-create-cluster.sh`](../task1/scripts/02-create-cluster.sh),
[`task1/scripts/03-delete-cluster.sh`](../task1/scripts/03-delete-cluster.sh).

---

## 4. Задание 2. Знакомство с ресурсами Kubernetes

Все объекты в Kubernetes — это ресурсы. Список ресурсов выводится командой
`kubectl get`, а полный перечень доступных ресурсов с псевдонимами —
`kubectl api-resources`. Рабочие ресурсы размещаем в отдельном пространстве
имён `lab4`, а системные компоненты смотрим в `kube-system`.

### 4.1. Системные поды и их назначение

**Что делаем.** Выводим все поды кластера и разбираем, за что отвечает каждый
системный компонент.

**Команда:**

```bash
kubectl get pods -A -o wide
```

**Результат:**

```text
NAMESPACE            NAME                                         READY   STATUS    RESTARTS   AGE   IP           NODE
kube-system          coredns-559f6c778d-49t4s                     1/1     Running   0          18m   10.244.0.2   lab4-control-plane
kube-system          coredns-559f6c778d-qtp89                     1/1     Running   0          18m   10.244.0.4   lab4-control-plane
kube-system          etcd-lab4-control-plane                      1/1     Running   0          18m   172.29.0.4   lab4-control-plane
kube-system          kindnet-mxr84                                1/1     Running   0          18m   172.29.0.3   lab4-worker2
kube-system          kindnet-xmmgq                                1/1     Running   0          18m   172.29.0.4   lab4-control-plane
kube-system          kindnet-zt9pv                                1/1     Running   0          18m   172.29.0.2   lab4-worker
kube-system          kube-apiserver-lab4-control-plane            1/1     Running   0          18m   172.29.0.4   lab4-control-plane
kube-system          kube-controller-manager-lab4-control-plane   1/1     Running   0          18m   172.29.0.4   lab4-control-plane
kube-system          kube-proxy-584sj                             1/1     Running   0          18m   172.29.0.2   lab4-worker
kube-system          kube-proxy-m565w                             1/1     Running   0          18m   172.29.0.4   lab4-control-plane
kube-system          kube-proxy-vh5z8                             1/1     Running   0          18m   172.29.0.3   lab4-worker2
kube-system          kube-scheduler-lab4-control-plane            1/1     Running   0          18m   172.29.0.4   lab4-control-plane
local-path-storage   local-path-provisioner-75f7fc7dc5-x5fbw      1/1     Running   0          18m   10.244.0.3   lab4-control-plane
```

**Пояснение.** Все системные компоненты запущены. Их назначение:

| Компонент | Где работает | Назначение |
|-----------|--------------|------------|
| `etcd` | control-plane | key-value хранилище, в котором лежит всё состояние кластера |
| `kube-apiserver` | control-plane | REST API — единая точка входа; через него общаются все компоненты и `kubectl` |
| `kube-controller-manager` | control-plane | запускает контроллеры, которые приводят состояние кластера к желаемому |
| `kube-scheduler` | control-plane | выбирает, на какой ноде запустить новый под |
| `kube-proxy` | каждая нода | реализует сетевую маршрутизацию для сервисов (iptables/IPVS) |
| `CoreDNS` | control-plane | DNS внутри кластера: превращает имена сервисов в IP |
| `kindnet` | каждая нода | CNI-плагин: сеть подов, выдача IP и связность между нодами |
| `local-path-provisioner` | control-plane | динамически создаёт PersistentVolume (StorageClass `standard`) |

Компоненты `etcd`, `kube-apiserver`, `kube-controller-manager` и
`kube-scheduler` запускаются как статические поды на управляющей ноде, поэтому
их имена содержат суффикс `lab4-control-plane`.

### 4.2. Том и его монтирование в под

#### 4.2.1. Временный том `emptyDir`, общий для двух контейнеров

**Что делаем.** Создаём под [`task2/pod-volume.yaml`](../task2/pod-volume.yaml)
с двумя контейнерами (`writer` и `reader`), которые монтируют один и тот же
том `emptyDir` в каталог `/data`. Контейнер `writer` пишет в том, а `reader`
читает оттуда — так видно, что том общий.

**Команда:**

```bash
kubectl apply -f task2/pod-volume.yaml
kubectl get pod volume-demo -n lab4 -o wide
```

**Результат:**

```text
pod/volume-demo created

NAME          READY   STATUS    RESTARTS   AGE   IP           NODE
volume-demo   2/2     Running   0          3s    10.244.2.2   lab4-worker
```

**Что демонстрируем.** Читаем файл, записанный контейнером `writer`, из
контейнера `reader`:

```bash
kubectl exec -n lab4 volume-demo -c reader -- cat /data/log.txt
kubectl logs -n lab4 volume-demo -c reader | tail -5
```

**Результат:**

```text
Wed Oct 14 17:02:51 UTC 2026
Wed Oct 14 17:02:56 UTC 2026
Wed Oct 14 17:03:01 UTC 2026
```

**Пояснение.** Контейнер `reader` видит файл, который создал контейнер
`writer`, — значит оба контейнера используют один том. Тип `emptyDir` создаёт
временное хранилище, которое живёт, пока существует под, и удаляется вместе с ним.

#### 4.2.2. Постоянный том через PVC и PV

**Что делаем.** Создаём `PersistentVolumeClaim` и под, который его монтирует
([`task2/pvc.yaml`](../task2/pvc.yaml) и
[`task2/pvc-pod.yaml`](../task2/pvc-pod.yaml)). Записываем данные, удаляем под
и создаём заново — проверяем, что данные сохранились.

**Команды:**

```bash
kubectl apply -f task2/pvc.yaml -f task2/pvc-pod.yaml
kubectl get pvc -n lab4
kubectl get pv
```

**Результат:**

```text
persistentvolumeclaim/demo-pvc created
pod/pvc-demo created

NAME       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
demo-pvc   Bound    pvc-110df543-abec-4a5d-b777-a05352736f77   1Gi        RWO            standard       6s

NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM           STORAGECLASS
pvc-110df543-abec-4a5d-b777-a05352736f77   1Gi        RWO            Delete           Bound    lab4/demo-pvc   standard
```

**Проверка сохранности данных:**

```bash
kubectl exec -n lab4 pvc-demo -- sh -c 'echo "persistent-data-$(date +%s)" > /data/persist.txt && cat /data/persist.txt'
kubectl delete pod pvc-demo -n lab4
kubectl apply -f task2/pvc-pod.yaml
kubectl exec -n lab4 pvc-demo -- cat /data/persist.txt
```

**Результат:**

```text
persistent-data-1791997406
pod "pvc-demo" deleted from lab4 namespace
pod/pvc-demo created
persistent-data-1791997406
```

**Пояснение.** При первом использовании StorageClass `standard` (provisioner
`rancher.io/local-path`) динамически создал PersistentVolume и привязал его к
нашему PVC (`STATUS: Bound`). После удаления и пересоздания пода файл
`/data/persist.txt` остался на месте — данные хранятся в PV, а не в контейнере.
Так закрывается тема «PV/PVC»: PVC — это запрос на хранилище, PV — само
хранилище.

### 4.3. Работа с ReplicaSet

**Что делаем.** Создаём ReplicaSet [`task2/replicaset.yaml`](../task2/replicaset.yaml)
с тремя репликами nginx и смотрим, как он поддерживает нужное число подов.

**Команды:**

```bash
kubectl apply -f task2/replicaset.yaml
kubectl get rs -n lab4 -o wide
kubectl get pods -n lab4 -l app=web -o wide
```

**Результат:**

```text
replicaset.apps/web created

NAME   DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES       SELECTOR
web    3         3         3       83s   web          nginx:1.27   app=web

NAME        READY   STATUS    RESTARTS   AGE   IP           NODE
web-627vg   1/1     Running   0          83s   10.244.1.6   lab4-worker2
web-pn5kd   1/1     Running   0          83s   10.244.2.3   lab4-worker
web-wktkl   1/1     Running   0          83s   10.244.1.5   lab4-worker2
```

**Масштабирование** до 5 реплик:

```bash
kubectl scale rs web --replicas=5 -n lab4
kubectl get rs -n lab4
```

**Результат:**

```text
replicaset.apps/web scaled
NAME   DESIRED   CURRENT   READY   AGE
web    5         5         5       91s
```

**Самовосстановление** — удаляем один под:

```bash
kubectl delete pod <один из подов web> -n lab4
kubectl get pods -n lab4 -l app=web -o wide
```

**Результат:**

```text
pod "web-48589" deleted from lab4 namespace

NAME        READY   STATUS    RESTARTS   AGE
web-627vg   1/1     Running   0          98s
web-cg448   1/1     Running   0          11s   <- создан заново
web-dk6wv   1/1     Running   0          7s
web-pn5kd   1/1     Running   0          98s
web-wktkl   1/1     Running   0          98s
```

**Пояснение.** ReplicaSet держит ровно `replicas` подов: при увеличении до 5
он создал ещё два пода, а после удаления одного — сразу создал новый вместо
него. Поды распределяются по worker-нодам планировщиком. В реальной практике
ReplicaSet напрямую используют редко: им управляет Deployment, который
добавляет версионирование и обновления (см. Задание 3).

## 5. Задание 3. Работа с Kubernetes

Читаем главу 17 (3rd ed.) / 16 (4th ed.) «Deploying, Updating, and Securing an
Application with Kubernetes» и разворачиваем приложение в кластере: Deployment,
Service, ConfigMap/Secret, обновление без простоя и Ingress.

### 5.1. Создание пространства имён

**Что делаем.** Заводим отдельное пространство имён `lab4`, чтобы изолировать
ресурсы лабораторной работы.

**Команда:**

```bash
kubectl create namespace lab4
```

**Результат:**

```text
namespace/lab4 created
```

**Пояснение.** Namespace — логическая изоляция ресурсов внутри кластера. Это
позволяет разделять окружения и команды (например, dev/stage/prod), а также
не пересекаться с системными объектами в `kube-system`.

### 5.2. ConfigMap и Secret

**Что делаем.** Создаём ConfigMap ([`task3/configmap.yaml`](../task3/configmap.yaml))
для неконфиденциальных данных и Secret ([`task3/secret.yaml`](../task3/secret.yaml))
для ключа. Данные в под передаём **двумя способами**: переменными окружения
(`envFrom`) и смонтированным файлом (`volumeMounts`).

**Команда:**

```bash
kubectl apply -f task3/configmap.yaml -f task3/secret.yaml
```

**Результат:**

```text
configmap/app-config created
secret/app-secret created
```

**Пояснение.** ConfigMap хранит обычные настройки (`APP_MODE`) и файл
`index.html`, который nginx отдаёт как страницу. Secret хранит `API_KEY`.
Секреты нельзя держать в ConfigMap, потому что ConfigMap не предназначен для
конфиденциальных данных: он хранится и отображается в открытом виде, тогда как
Secret как минимум помечается как конфиденциальный и его можно шифровать и
ограничивать по RBAC. Проверка передачи данных показана в п. 5.3.

### 5.3. Deployment приложения

**Что делаем.** Разворачиваем Deployment [`task3/deployment.yaml`](../task3/deployment.yaml):
3 реплики nginx, стратегия `RollingUpdate` (`maxSurge: 1`, `maxUnavailable: 0`),
данные из ConfigMap и Secret.

**Команды:**

```bash
kubectl apply -f task3/deployment.yaml
kubectl rollout status deployment/web -n lab4
kubectl get deploy,rs,pods -n lab4 -o wide
```

**Результат:**

```text
deployment.apps/web created
deployment "web" successfully rolled out

NAME                  READY   UP-TO-DATE   AVAILABLE   IMAGES
deployment.apps/web   3/3     3            3           nginx:1.27

NAME                             DESIRED   CURRENT   READY   IMAGES
replicaset.apps/web-5859ccb994   3         3         3       nginx:1.27

NAME                       READY   STATUS    AGE   NODE
pod/web-5859ccb994-5jhqm   1/1     Running   0     lab4-worker2
pod/web-5859ccb994-5s5h9   1/1     Running   0     lab4-worker
pod/web-5859ccb994-pvzxf   1/1     Running   0     lab4-worker
```

**Проверка данных из ConfigMap и Secret в поде:**

```bash
kubectl exec -n lab4 <pod> -- sh -c 'echo APP_MODE=$APP_MODE; echo API_KEY=$API_KEY'
kubectl exec -n lab4 <pod> -- head -3 /usr/share/nginx/html/index.html
```

**Результат:**

```text
APP_MODE=production
API_KEY=s3cr3t-value-123

<!DOCTYPE html>
<html lang="ru">
  <head><meta charset="utf-8"><title>Lab4</title></head>
```

**Пояснение.** `APP_MODE` пришёл из ConfigMap как переменная окружения,
`API_KEY` — из Secret, а `index.html` смонтирован из ConfigMap как файл и
отдаётся nginx. Deployment создал ReplicaSet, а тот — три пода.

### 5.4. Service и доступ к приложению

**Что делаем.** Публикуем приложение через Service типа `NodePort`
([`task3/service.yaml`](../task3/service.yaml)) на порту 30000, который был
проброшен на хост при создании кластера.

**Команды:**

```bash
kubectl apply -f task3/service.yaml
kubectl get svc -n lab4
curl -s http://localhost:30000
```

**Результат:**

```text
service/web created

NAME   TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
web    NodePort   10.96.89.206   <none>        80:30000/TCP   0s

<!DOCTYPE html>
<html lang="ru">
  <head><meta charset="utf-8"><title>Lab4</title></head>
  <body>
    <h1>Lab4: nginx</h1>
    <p>Страница отдаётся из ConfigMap, смонтированного в pod.</p>
  </body>
</html>
```

**Пояснение.** Service даёт подам стабильный виртуальный IP и имя `web`,
скрывая их изменчивые адреса. Тип `NodePort` открывает сервис на каждой ноде
на порту 30000; поскольку этот порт проброшен на хост, приложение доступно с
Mac по `http://localhost:30000`. Несколько запросов `curl` обслуживают разные
поды — работает балансировка нагрузки.

### 5.5. Обновление без простоя (rolling update) и откат

**Что делаем.** Меняем образ `nginx:1.27 → nginx:1.28` и следим за
обновлением. Одновременно «пингуем» приложение, чтобы убедиться в отсутствии
простоя. Затем откатываемся на предыдущую версию.

**Команды:**

```bash
kubectl set image deployment/web web=nginx:1.28 -n lab4
kubectl rollout status deployment/web -n lab4
kubectl rollout history deployment/web -n lab4
```

**Результат:**

```text
deployment.apps/web image updated
deployment "web" successfully rolled out

REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

**Проверка отсутствия простоя** — 30 запросов `curl` во время обновления:

```text
  30 200
```

**Поды после обновления:**

```text
NAME                             DESIRED   CURRENT   READY   IMAGES
replicaset.apps/web-5859ccb994   0         0         0       nginx:1.27   <- старый
replicaset.apps/web-76548dbbc9   3         3         3       nginx:1.28   <- новый
```

**Откат:**

```bash
kubectl rollout undo deployment/web -n lab4
kubectl rollout status deployment/web -n lab4
```

**Результат:**

```text
deployment.apps/web rolled back
deployment "web" successfully rolled out
```

**Пояснение.** Стратегия `RollingUpdate` с `maxUnavailable: 0` заменяет поды
постепенно, не прерывая обслуживание: все 30 запросов во время обновления
вернули код `200`. При обновлении создаётся новый ReplicaSet, а старый
постепенно сводится к нулю — это и есть механизм версионирования. Команда
`kubectl rollout undo` откатывает приложение на предыдущую ревизию.

### 5.6. Ingress

**Что делаем.** Устанавливаем ingress-nginx controller (манифест для kind) и
создаём Ingress [`task3/ingress.yaml`](../task3/ingress.yaml), который
маршрутизирует запросы к хосту `lab4.local` в сервис `web`.

**Команды:**

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl apply -f task3/ingress.yaml
kubectl get ingress -n lab4
curl -s -H "Host: lab4.local" http://localhost/
```

**Результат:**

```text
ingress.networking.k8s.io/web created

NAME   CLASS   HOSTS        ADDRESS   PORTS   AGE
web    nginx   lab4.local             80      3s

<!DOCTYPE html>
<html lang="ru">
  <head><meta charset="utf-8"><title>Lab4</title></head>
  <body>
    <h1>Lab4: nginx</h1>
    <p>Страница отдаётся из ConfigMap, смонтированного в pod.</p>
  </body>
</html>
```

**Пояснение.** Ingress решает проблему публикации множества сервисов через
один внешний адрес и порт (80/443): контроллер принимает HTTP-трафик и по
правилам `host`/`path` направляет его в нужный сервис. Здесь правило «хост
`lab4.local`, путь `/`» ведёт в сервис `web`. Контроллер работает на
управляющей ноде (у неё метка `ingress-ready=true`), а порты 80/443 проброшены
на хост, поэтому Ingress доступен с Mac. Запрос с заголовком
`Host: lab4.local` вернул ту же страницу (`HTTP 200`).

### 5.7. Вывод по заданию 3

В отдельном пространстве имён `lab4` развёрнуто приложение: Deployment из трёх
реплик nginx с конфигурацией из ConfigMap и Secret, опубликованное через
Service (NodePort) и Ingress. Продемонстрировано обновление версии приложения
без простоя (rolling update) с возможностью отката, а также маршрутизация
внешнего трафика через Ingress.

## 6. Ответы на контрольные вопросы

### 1. Что такое Kubernetes и зачем он нужен в работе с контейнерами?

Kubernetes (K8s) — это платформа оркестрации контейнеров: она автоматически
разворачивает, масштабирует, связывает между собой и восстанавливает
контейнерные приложения. В работе с контейнерами он нужен потому, что при
переходе от одного-двух контейнеров к десяткам и сотням на множестве машин
ручное управление становится нереальным. Kubernetes берёт на себя:

- **планирование** — решает, на какой ноде запустить каждый под;
- **самовосстановление** — перезапускает упавшие контейнеры и пересоздаёт поды;
- **масштабирование** — держит заданное число реплик, умеет масштабироваться под нагрузку;
- **сетевые абстракции** — сервисы, DNS, балансировка нагрузки;
- **обновления** — выкатка новых версий без простоя;
- **конфигурацию** — ConfigMap, Secret, тома.

### 2. Отличие «запустить контейнеры вручную через Docker» от «управлять ими в Kubernetes»

**Вручную через Docker:** команда `docker run` запускает контейнер на одной
конкретной машине. Если контейнер упал — его никто не перезапустит. Масштабирование,
перезапуск, балансировку, обновление версии и сеть между контейнерами инженер
настраивает и контролирует сам. Нет декларативного описания желаемого состояния.

**В Kubernetes:** вы описываете желаемое состояние в манифестах, а кластер сам
приводит к нему реальное состояние. Планировщик выбирает ноду, контроллеры
пересоздают упавшие поды, сервисы дают стабильные адреса, а обновления идут
постепенно и без простоя. Работа идёт не с отдельным контейнером на одной
машине, а с кластером из многих нод.

### 3. Примеры задач, где оркестрация экономит время

1. **Самовосстановление.** В нашем Задании 2 после удаления пода ReplicaSet
   сразу создал новый вместо него — вручную это был бы постоянный мониторинг и
   ручной перезапуск.
2. **Обновление без простоя.** В Задании 3 `kubectl set image` обновил версию
   nginx постепенно; все 30 запросов во время обновления вернули `200`.
3. **Масштабирование.** `kubectl scale --replicas=5` за секунды увеличил число
   подов вместо ручного запуска новых контейнеров на разных машинах.

### 4. Основные компоненты кластера Kubernetes

**Control-plane (управляющий слой):**

- **kube-apiserver** — REST API, единая точка входа; через него общаются все
  компоненты и `kubectl`, он проверяет и сохраняет объекты.
- **etcd** — распределённое key-value хранилище, в котором лежит всё состояние
  кластера.
- **kube-controller-manager** — запускает контроллеры, которые приводят
  фактическое состояние к желаемому (например, ReplicaSet создаёт поды).
- **kube-scheduler** — выбирает ноду для нового пода с учётом ресурсов и
  ограничений.

**Рабочие ноды:**

- **kubelet** — агент на ноде, запускает и следит за контейнерами подов.
- **kube-proxy** — обеспечивает сетевую маршрутизацию сервисов (iptables/IPVS).
- **container runtime** (в kind — containerd) — запускает контейнеры.
- **CNI-плагин** (в kind — kindnet) — сеть подов и их связность.

**Дополнения:** CoreDNS (DNS внутри кластера), local-path-provisioner
(динамические тома). В нашем кластере всё это видно в `kube-system`.

### 5. Создание пода через YAML-манифест и обязательные поля

Под создаётся описанием его в YAML-файле и командой `kubectl apply -f pod.yaml`.
Обязательные поля верхнего уровня:

- **apiVersion** — версия API ресурса (для пода `v1`);
- **kind** — тип ресурса (`Pod`);
- **metadata** — метаданные: имя, метки, пространство имён;
- **spec** — спецификация: что именно запускать (контейнеры, тома и т.д.).

Без этих полей API-сервер не сможет понять, что за объект создаётся.

### 6. Пример YAML для простого пода и что будет при пропуске поля

```yaml
apiVersion: v1          # версия API
kind: Pod               # тип ресурса
metadata:
  name: simple-pod      # имя пода
spec:
  containers:           # список контейнеров
    - name: web
      image: nginx:1.27 # образ
      ports:
        - containerPort: 80
```

Ключевые поля: `apiVersion`/`kind` задают, что создаётся; `metadata.name` —
имя пода; `spec.containers` — какие контейнеры запускать и из каких образов.

Если пропустить обязательное поле, `kubectl`/API-сервер вернёт ошибку
валидации и под не создастся: без `apiVersion`/`kind` — «не удаётся распознать
тип объекта», без `metadata.name` — «name is required», без `spec.containers` —
«containers is required».

### 7. Сервисы: ClusterIP и Headless

**Service** — это абстракция над набором подов, дающая им стабильный
виртуальный IP и DNS-имя. Поды появляются и исчезают, их IP меняются, а сервис
остаётся неизменной точкой входа и распределяет трафик между подами.

- **ClusterIP** — тип по умолчанию. Сервису выдаётся один виртуальный IP
  внутри кластера; `kube-proxy` балансирует запросы на него между подами.
  Пример: внутренний API, к которому обращаются другие сервисы.
- **Headless-сервис** (`clusterIP: None`) — виртуального IP нет, а DNS-запрос
  к сервису возвращает IP **всех** подов напрямую. Пример: кластер базы данных
  или StatefulSet, где клиенту нужно знать конкретные поды (лидер/реплики), а
  не абстрактный балансировщик.

### 8. NodePort и LoadBalancer: как внешний пользователь попадает в под

- **NodePort.** Сервис открывает один и тот же порт (30000–32767) на **каждой**
  ноде кластера. Путь: внешний пользователь → `IP любой ноды:NodePort` →
  `kube-proxy` на ноде → нужный под.
- **LoadBalancer.** Строится поверх NodePort. Облачный провайдер создаёт
  внешний балансировщик с публичным IP. Путь: пользователь → публичный IP
  балансировщика → (трафик распределяется) → `нода:NodePort` → `kube-proxy` →
  под.

В нашем Задании 3 использовался NodePort 30000, проброшенный на хост: запрос
шёл на `localhost:30000` и попадал в один из подов nginx.

### 9. Порты и ограничения NodePort

По умолчанию NodePort использует диапазон **30000–32767** (настраивается
флагом `--service-node-port-range`). Ограничения:

- доступны только высокие порты, «красивый» 80/443 так не открыть;
- на один сервис — один порт, нет домена и TLS «из коробки»;
- нужно, чтобы IP нод были доступны клиенту;
- номер порта надо помнить/передавать пользователям;
- не подходит как полноценное решение для продакшна.

### 10. Когда NodePort достаточно, а когда нужен LoadBalancer

- **NodePort достаточно:** локальная разработка, тестовый стенд, внутренний
  доступ, когда есть прямой доступ к IP нод. Например, наша лабораторная:
  приложение доступно по `localhost:30000`.
- **Нужен LoadBalancer:** продакшн, где требуется один стабильный публичный
  IP/домен, TLS, автоматическое распределение нагрузки и «отказоустойчивый»
  вход. В облаке это делается одним типом сервиса без ручного проброса портов.

### 11. Ingress

**Ingress** — это ресурс HTTP(S)-маршрутизации уровня L7. Он решает проблему
публикации **многих** сервисов через **один** внешний адрес и порт (80/443):
контроллер Ingress принимает трафик и по правилам `host`/`path` направляет его
в нужный сервис, а также может терминировать TLS.

Пример манифеста (одно правило: хост + путь):

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web
spec:
  ingressClassName: nginx
  rules:
    - host: lab4.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web
                port:
                  number: 80
```

Запрос к `lab4.local/` попадёт в сервис `web`. Именно это мы проверяли в
Задании 3 (`curl -H "Host: lab4.local" http://localhost/` → `HTTP 200`).

### 12. Deployment, StatefulSet и DaemonSet

| Критерий | Deployment | StatefulSet | DaemonSet |
|----------|------------|-------------|-----------|
| Цель | обычные stateless-приложения | приложения с состоянием и стабильной идентичностью | по одному поду на каждой (подходящей) ноде |
| Как создаются поды | без порядка, взаимозаменяемы | упорядоченно, с устойчивыми именами и своим хранилищем | по поду на каждую ноду |
| Привязка к узлам | нет, планировщик выбирает | нет, но под привязан к своему PV | да, жёстко к каждой ноде |

Примеры и поведение при масштабировании до 3 реплик:

- **Deployment** (веб-приложение): получим 3 взаимозаменяемых пода, любой может
  обслужить запрос.
- **StatefulSet** (база данных): получим `app-0`, `app-1`, `app-2` с
  предсказуемыми именами и своими томами; создаются по очереди.
- **DaemonSet** (агент логирования): по поду на **каждую** ноду; «масштабирование
  до 3» означает 3 подходящие ноды, а не 3 копии на одной.

### 13. Job и CronJob

- **Job** — одноразовая задача, которая выполняется до успешного завершения.
  Пример: миграция схемы БД, разовый расчёт, бэкап.
- **CronJob** — запускает Job по расписанию (cron-синтаксис). Пример: ночная
  очистка логов, регулярный бэкап.

Проверить результат: `kubectl get jobs`, `kubectl get pods` (статус
`Completed`), `kubectl logs <pod>`. Для CronJob — `kubectl get cronjobs` и
история созданных Job.

### 14. ConfigMap и Secret, два способа передачи в под

- **ConfigMap** — неконфиденциальные настройки (режимы, URL, конфиг-файлы).
- **Secret** — конфиденциальные данные (пароли, токены, ключи).

Два способа передать данные в под:

1. **Переменные окружения** — `env`/`envFrom` (`configMapRef`/`secretRef`).
   Удобно для небольших значений, которые читает приложение.
2. **Монтирование как файла** (`volumes` + `volumeMounts`). Удобно для
   конфиг-файлов и сертификатов; обновление ConfigMap подхватывается без
   пересоздания пода.

В Задании 3 мы использовали оба способа: `APP_MODE` и `API_KEY` пришли как
переменные окружения, а `index.html` — как смонтированный файл.

### 15. YAML для ConfigMap и Secret; почему пароли нельзя в ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_MODE: "production"
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
type: Opaque
stringData:
  API_KEY: "s3cr3t-value-123"
```

Пароли нельзя хранить в ConfigMap потому, что ConfigMap не предназначен для
конфиденциальных данных: он хранится в открытом виде, легко выводится
(`kubectl get configmap -o yaml`), доступен любому, у кого есть права на чтение
в namespace, и может попасть в логи/манифесты. Secret хотя бы отделяет
конфиденциальные данные: его можно шифровать в etcd, ограничивать через RBAC,
он не выводится в открытом виде и монтируется в память (tmpfs).

### 16. Основные команды kubectl по группам задач

**Посмотреть состояние:**

- `kubectl get` — список ресурсов (`get pods`, `get svc`, `get all`);
- `kubectl describe` — подробности и события объекта;
- `kubectl logs` — логи контейнера;
- `kubectl get events` — события кластера.

**Создать/обновить:**

- `kubectl apply -f` — применить манифест;
- `kubectl create` — создать ресурс;
- `kubectl set image` — сменить образ (обновление);
- `kubectl scale` — изменить число реплик;
- `kubectl edit` — править ресурс на месте.

**Удалить:**

- `kubectl delete -f` / `kubectl delete pod <name>`;
- `kubectl rollout undo` — откатить обновление.

**Отладить:**

- `kubectl exec -it <pod> -- sh` — зайти в контейнер;
- `kubectl port-forward` — пробросить порт локально;
- `kubectl logs`/`describe`/`top` — логи, события, потребление ресурсов.

### 17. Пространства имён (namespaces)

Namespace — логическое разделение ресурсов внутри одного кластера: имена
ресурсов уникальны в пределах namespace, а не всего кластера. Используются для
изоляции и разграничения доступа (RBAC), квот ресурсов и удобства навигации.
Примеры пользы: разделение **dev/stage/prod**, разделение по **командам**, а
также отдельный namespace под задачу (как `lab4` в этой работе).

### 18. Как создать namespace и работать только в нём

```bash
kubectl create namespace lab4
```

Выполнять команды в нём можно двумя способами:

```bash
kubectl get pods -n lab4                              # флагом для каждой команды
kubectl config set-context --current --namespace=lab4 # сделать namespace текущим
```

### 19. Пробы (probes)

- **livenessProbe** — проверяет, «жив» ли контейнер. Если проба не проходит,
  kubelet перезапускает контейнер (лечит зависания).
- **readinessProbe** — проверяет, готов ли контейнер принимать трафик. Если нет,
  под исключается из endpoints сервиса, но не перезапускается.
- **startupProbe** — проверяет, завершился ли «долгий» старт приложения; пока
  она не пройдёт, liveness/readiness не запускаются (защита от ложных перезапусков).

### 20. PersistentVolume (PV) и PersistentVolumeClaim (PVC)

- **PV** — ресурс хранилища в кластере (реальный диск/NFS/облачный том).
- **PVC** — запрос пользователя на хранилище (сколько и с каким режимом
  доступа). Под использует PVC, а не PV напрямую.

Место выделяется через **StorageClass** и provisioner: при создании PVC
provisioner динамически создаёт подходящий PV и «биндит» его с PVC. В нашей
работе StorageClass `standard` (provisioner `rancher.io/local-path`) создал PV
на 1Gi; после пересоздания пода данные сохранились.

### 21. Как Kubernetes реагирует, если под или узел «упали»

1. **Пересоздание подов контроллером.** ReplicaSet/Deployment держат нужное
   число реплик: если под удалён или упал, создаётся новый (мы это видели в
   Задании 2).
2. **Перезапуск контейнера kubelet'ом.** Согласно `restartPolicy` kubelet
   перезапускает упавший контейнер в поде.
3. **Лечение пробами.** `livenessProbe` перезапускает «зависший» контейнер.
4. **Переселение с упавших нод.** Если нода недоступна, контроллеры через
   некоторое время пересоздают её поды на других нодах.

### 22. Обновление без простоя и rolling update

Обновление без простоя обеспечивает стратегия **RollingUpdate** у Deployment:
поды новой версии поднимаются постепенно, и только после того, как они станут
готовы, удаляются старые. За это отвечают параметры:

- **maxUnavailable** — сколько подов можно убрать одновременно (у нас `0`, то
  есть доступность не снижается);
- **maxSurge** — сколько подов сверх желаемого можно создать временно (у нас `1`).

Готовность подов определяется **readinessProbe**, поэтому трафик не идёт на ещё
не готовые поды. В нашем Задании 3 во время обновления все 30 запросов вернули
`200` — простоя не было.

### 23. Как запустить обновление и следить за прогрессом

```bash
kubectl set image deployment/web web=nginx:1.28 -n lab4   # или kubectl apply с новым манифестом
kubectl rollout status deployment/web -n lab4             # прогресс обновления
kubectl rollout history deployment/web -n lab4            # история ревизий
kubectl get rs,pods -n lab4                               # старый и новый ReplicaSet
kubectl rollout undo deployment/web -n lab4               # откат при необходимости
```

`rollout status` показывает, сколько новых реплик уже доступно; `rollout
history` — список ревизий; `rollout undo` возвращает предыдущую версию. Так
обновление и откат контролируются и обратимы.
