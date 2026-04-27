# 書籍サンプルコード
このレポジトリは、「イメージで理解！Kubernetesを始める人が最初に読む本(C&R研究所)」で使われるサンプルコードを管理するためのレポジトリです。

## ディレクトリ構成

- **第3章/** … Kubernetes環境構築（kind の設定など）
- **第4章/** … Pod / ReplicaSet / Deployment / ConfigMap / Secret / Service / Volume / StatefulSet / DaemonSet / CronJob のマニフェスト
- **第5章/** … Knative Serving 用の ConfigMap と KNative Service のマニフェスト

## 第3章で使うファイル

| ファイル | 説明 |
|----------|------|
| `kind-config.yaml` | 1 control-plane + 2 workers の kind クラスタ用設定 |


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


## 第5章で使うファイル

| ファイル | 説明 |
|----------|------|
| `config-domain.yaml` | Knative のカスタムドメイン用 ConfigMap（`example.com`） |
| `restaurant-knative-service.yaml` | KNative Service（FastAPI アプリ） |
