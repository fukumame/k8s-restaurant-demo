# 書籍サンプルコード
このレポジトリは、「イメージで理解！Kubernetesを始める人が最初に読む本(C&R研究所)」で使われるサンプルコードを管理するためのレポジトリです。

> [!WARNING]
> **本リポジトリは学習用サンプルです。本番環境では使用しないでください。**
>
> - `restaurant-secret.yaml` に含まれる `DB_PASSWORD` や `SECRET_RECIPE` などの値は、すべて解説用のダミーです。実在するクレデンシャルではありません。
> - Kubernetes の Secret の `data` は **暗号化ではなく単なる Base64 エンコード**であり、誰でも復号できます。本番では実際のパスワードをそのまま記載せず、外部シークレット管理（External Secrets、Sealed Secrets、クラウドの KMS など）の利用を検討してください。
> - `install-prometheus-stack.sh` の Grafana 管理者パスワードはローカル検証用のデフォルト値（`admin`）です。公開環境では必ず変更してください。

## ディレクトリ構成

- **第3章/** … Kubernetes環境構築（kind の設定など）
- **第4章/** … Pod / ReplicaSet / Deployment / ConfigMap / Secret / Service / Volume / StatefulSet / DaemonSet / CronJob のマニフェストとアプリ簡略版
- **第5章/** … Knative Serving 用の ConfigMap と KNative Service のマニフェスト

## 第3章で使うファイル

| ファイル | 説明 |
|----------|------|
| `kind-config.yaml` | 1 control-plane + 2 workers の kind クラスタ用設定 |
| `install-homebrew.sh` | macOS 向け Homebrew インストールスクリプト |
| `install-chocolatey.ps1` | Windows 向け Chocolatey インストールスクリプト |

**最小手順**

1. `samples/chapter3/` に移動する
2. `kind create cluster --config kind-config.yaml --name k8s-demo-cluster` でクラスタを作成する

## 第4章で使うファイル

| ファイル | 説明 |
|----------|------|
| `app.py` | 書籍掲載の FastAPI 簡略版（参照用。実行は Docker イメージ `docker.io/fukumame/k8s-restaurant-demo:1.0.0` を推奨） |
| `restaurant-pod.yaml` | Pod 単体 |
| `restaurant-replicaset.yaml` | ReplicaSet |
| `restaurant-deployment.yaml` | Deployment（基本） |
| `restaurant-configmap.yaml` | ConfigMap |
| `restaurant-deployment-with-configmap.yaml` | ConfigMap 参照 Deployment |
| `restaurant-secret.yaml` | Secret |
| `restaurant-deployment-with-secret.yaml` | Secret 参照 Deployment |
| `restaurant-service-clusterip.yaml` | ClusterIP Service |
| `restaurant-service-nodeport.yaml` | NodePort Service |
| `install-metallb.sh` | MetalLB 本体のインストールスクリプト |
| `metallb-ip-pool.yaml` | MetalLB 用 IP プール（LoadBalancer 利用前に適用） |
| `restaurant-service-loadbalancer.yaml` | LoadBalancer Service |
| `restaurant-deployment-temp.yaml` | Volume 未使用 Deployment（データ消失のデモ用） |
| `recipe-pvc.yaml` | PersistentVolumeClaim |
| `restaurant-deployment-with-pvc.yaml` | PVC マウント Deployment |
| `nginx-statefulset-service.yaml` | StatefulSet 用 Headless Service |
| `nginx-statefulset.yaml` | StatefulSet |
| `node-info-daemonset.yaml` | DaemonSet |
| `nginx-deployment.yaml` | Deployment（DaemonSet 比較用） |
| `inventory-check-cronjob.yaml` | CronJob |
| `column-port-forward.md` | コラム: `kubectl port-forward` ではServiceの代わりにならないのか？ |

**適用順の目安**

1. 第3章の kind クラスタを用意したうえで、`samples/chapter4/` に移動する
2. 原稿の流れに従い、Pod → ReplicaSet → Deployment の順で適用する
3. ConfigMap / Secret は該当マニフェストを先に適用し、その後 Deployment を適用する
4. Service は Deployment が稼働した後に適用する
5. MetalLB 利用時は、MetalLB 本体のマニフェスト適用後に `metallb-ip-pool.yaml` を適用する
6. PV/PVC を試す場合は、`recipe-pvc.yaml` → `restaurant-deployment-with-pvc.yaml` の順で適用する

## 第5章で使うファイル

| ファイル | 説明 |
|----------|------|
| `config-domain.yaml` | Knative のカスタムドメイン用 ConfigMap（`example.com`） |
| `restaurant-knative-service.yaml` | KNative Service（FastAPI アプリ） |

**最小手順**

1. 第5章の原稿に従い、Knative Serving と Kourier をインストールする
2. `kubectl apply -f config-domain.yaml` でドメインを設定する
3. `kubectl apply -f restaurant-knative-service.yaml` で KNative Service をデプロイする
