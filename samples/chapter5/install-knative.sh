#!/bin/bash
set -euo pipefail

KNATIVE_SERVING_VERSION="knative-v1.20.1"
KOURIER_VERSION="knative-v1.20.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "KNative Serving のCRDを適用します..."
kubectl apply -f "https://github.com/knative/serving/releases/download/${KNATIVE_SERVING_VERSION}/serving-crds.yaml"

echo "KNative Serving のコアコンポーネントを適用します..."
kubectl apply -f "https://github.com/knative/serving/releases/download/${KNATIVE_SERVING_VERSION}/serving-core.yaml"

echo "knative-serving のPodが起動するまで待機します..."
kubectl wait --namespace knative-serving \
  --for=condition=ready pod --all \
  --timeout=180s

echo "Kourier (Ingress) を適用します..."
kubectl apply -f "https://github.com/knative-extensions/net-kourier/releases/download/${KOURIER_VERSION}/kourier.yaml"

echo "kourier-system のPodが起動するまで待機します..."
kubectl wait --namespace kourier-system \
  --for=condition=ready pod --all \
  --timeout=180s

echo "KourierをデフォルトのIngressとして設定します..."
kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'

echo "カスタムドメイン (config-domain) を適用します..."
kubectl apply -f "${SCRIPT_DIR}/config-domain.yaml"

echo "Pod の状態を確認します..."
kubectl get pods -n knative-serving
kubectl get pods -n kourier-system

echo "KNative Serving のインストールが完了しました。"
