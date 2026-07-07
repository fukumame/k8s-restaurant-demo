#!/bin/bash
set -euo pipefail

METALLB_VERSION="v0.15.3"
# イメージ取得(quay.io)が遅い環境でもタイムアウトしにくいよう、待機時間は長めに設定
WAIT_TIMEOUT="300s"

echo "MetalLB ${METALLB_VERSION} をインストールします..."
kubectl apply -f "https://raw.githubusercontent.com/metallb/metallb/${METALLB_VERSION}/config/manifests/metallb-native.yaml"

echo "MetalLBのPodが起動するまで待機します（最大 ${WAIT_TIMEOUT}）..."
if ! kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout="${WAIT_TIMEOUT}"; then
  echo "" >&2
  echo "----------------------------------------------------------------" >&2
  echo "[注意] ${WAIT_TIMEOUT} 以内に MetalLB の Pod が Ready になりませんでした。" >&2
  echo "多くの場合は失敗ではなく、イメージ取得（quay.io）に時間がかかっているだけです。" >&2
  echo "" >&2
  echo "まず現在の状態を確認してください:" >&2
  echo "  kubectl get pods -n metallb-system" >&2
  echo "  kubectl describe pod -n metallb-system -l app=metallb   # 末尾の Events に原因が出ます" >&2
  echo "" >&2
  echo "STATUS が ImagePullBackOff / ErrImagePull、または ContainerCreating が続く場合は、" >&2
  echo "quay.io への到達性（回線・プロキシ・DNS）を確認してください。" >&2
  echo "kind をお使いなら、ホストで取得してクラスタへ読み込む回避策があります:" >&2
  echo "  docker pull quay.io/metallb/controller:${METALLB_VERSION}" >&2
  echo "  docker pull quay.io/metallb/speaker:${METALLB_VERSION}" >&2
  echo "  kind load docker-image quay.io/metallb/controller:${METALLB_VERSION} --name <クラスタ名>" >&2
  echo "  kind load docker-image quay.io/metallb/speaker:${METALLB_VERSION} --name <クラスタ名>" >&2
  echo "  （<クラスタ名> は 'kind get clusters' で確認。本書では k8s-demo-cluster）" >&2
  echo "----------------------------------------------------------------" >&2
  echo "" >&2
  echo "現在の Pod 一覧:" >&2
  kubectl get pods -n metallb-system || true
  exit 1
fi

echo "MetalLBのPodの状態を確認します..."
kubectl get pods -n metallb-system

echo "MetalLBのインストールが完了しました。"
