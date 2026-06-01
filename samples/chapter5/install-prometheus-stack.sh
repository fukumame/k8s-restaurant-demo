#!/bin/bash
set -euo pipefail

# 注意: デフォルトのパスワード "admin" はローカル検証用です。
# 公開環境では必ず GRAFANA_ADMIN_PASSWORD 環境変数で別の値を指定してください。
GRAFANA_ADMIN_PASSWORD="${GRAFANA_ADMIN_PASSWORD:-admin}"

echo "Helmリポジトリを追加します..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "monitoring Namespace を作成します..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

echo "kube-prometheus-stack をインストールします..."
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword="${GRAFANA_ADMIN_PASSWORD}"

echo "monitoring NamespaceのPodが起動するまで待機します..."
kubectl wait --namespace monitoring \
  --for=condition=ready pod --all \
  --timeout=300s

echo "Pod の状態を確認します..."
kubectl get pods -n monitoring

echo "kube-prometheus-stack のインストールが完了しました。"
echo "Grafanaにアクセスするには: kubectl port-forward svc/prometheus-stack-grafana 3000:80 -n monitoring"
