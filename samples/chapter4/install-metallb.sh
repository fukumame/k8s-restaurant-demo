#!/bin/bash
set -euo pipefail

METALLB_VERSION="v0.15.3"

echo "MetalLB ${METALLB_VERSION} をインストールします..."
kubectl apply -f "https://raw.githubusercontent.com/metallb/metallb/${METALLB_VERSION}/config/manifests/metallb-native.yaml"

echo "MetalLBのPodが起動するまで待機します..."
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=90s

echo "MetalLBのPodの状態を確認します..."
kubectl get pods -n metallb-system

echo "MetalLBのインストールが完了しました。"
