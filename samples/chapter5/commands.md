# 第5章 コマンド集（コピペ実行用）

第5章「実践編:スケーラブルなWebサービスの構築と監視」で実行するコマンドを、書籍の流れに沿ってまとめています。上から順にコピペして実行できます。
- マニフェスト（YAML）とインストールスクリプトはこのディレクトリ（`samples/chapter5/`）に用意されています。
- 前提: 第3章で構築したkindクラスタと、第4章でインストールしたMetalLBを使用します。

## コマンド内のプレースホルダーについて
- `172.19.255.200` は、Kourierの実際のEXTERNAL-IP（`kubectl get svc -n kourier-system kourier` で確認）に置き換えてください。
- KNative・Kourier・Prometheusなどのバージョンはこのファイルおよびスクリプトのとおりですが、最新版は各公式リリースページで確認してください。

---

## KNativeのインストール

以下の手順をまとめて実行するスクリプトを用意しています。一括実行する場合は次のコマンドだけで完了します（個別に確認したい場合は下の手順に従ってください）。

```bash
cd samples/chapter5
./install-knative.sh
```

### 個別に実行する場合

1. KNative Serving のCRDをインストールします。

```bash
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.20.1/serving-crds.yaml
```

2. コアコンポーネントをインストールします。

```bash
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.20.1/serving-core.yaml
```

3. ネットワーキングレイヤー（Kourier）をインストールします。

```bash
kubectl apply -f https://github.com/knative-extensions/net-kourier/releases/download/knative-v1.20.0/kourier.yaml
```

4. KourierをデフォルトのIngressとして設定します。

```bash
kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'
```

5. インストールを確認します（すべて `Running` になればOK）。

```bash
kubectl get pods -n knative-serving
```

### カスタムドメインの設定

`config-domain.yaml`（このディレクトリに用意）を適用します。

```bash
kubectl apply -f config-domain.yaml
```

設定を確認します。

```bash
kubectl get configmap config-domain -n knative-serving -o yaml
```

### Kourierの確認

```bash
kubectl get pods -n kourier-system
```

---

## KNativeでFastAPIアプリをデプロイ

KNative Service（`restaurant-knative-service.yaml`、このディレクトリに用意）を適用します。

```bash
kubectl apply -f restaurant-knative-service.yaml
```

デプロイ状況を確認します（`READY` が `True` になればOK）。

```bash
kubectl get ksvc
```

Podの状態を確認します。

```bash
kubectl get pods -l serving.knative.dev/service=restaurant-demo
```

### 外部アクセス

KourierのExternal IPを確認します。

```bash
kubectl get svc -n kourier-system kourier
```

KNative ServiceのURLを確認します。

```bash
kubectl get ksvc restaurant-demo -o jsonpath='{.status.url}'
```

アプリケーションにアクセスします（`172.19.255.200` は実際のEXTERNAL-IPに置き換えてください）。

```bash
docker run --rm --network kind curlimages/curl:latest curl -H "Host: restaurant-demo.default.example.com" http://172.19.255.200/menu
```

インタラクティブに確認する場合。

```bash
docker run --rm -it --network kind curlimages/curl:latest sh
```

```bash
# コンテナ内で実行
curl -H "Host: restaurant-demo.default.example.com" http://172.19.255.200/menu
```

---

## 負荷テストツール「hey」

### 簡単なテスト実行（並行数5・スケールしない）

```bash
docker run --rm --network kind williamyeh/hey:latest -n 100 -c 5 -host "restaurant-demo.default.example.com" http://172.19.255.200/menu
```

### 負荷テストの実行とオートスケーリングの確認

負荷テスト前に現在のPod数を確認します。

```bash
kubectl get pods -l serving.knative.dev/service=restaurant-demo
```

高い負荷をかけます（並行数40・3分間）。

```bash
docker run --rm --network kind williamyeh/hey:latest -z 3m -c 40 -host "restaurant-demo.default.example.com" http://172.19.255.200/menu
```

別のターミナルでPod数の変化をリアルタイムに監視します。

```bash
watch -n 1 'kubectl get pods -l serving.knative.dev/service=restaurant-demo'
```

#### 補足
`watch` はmacOSに標準搭載されていません。未導入の場合は `brew install watch` でインストールできます。`watch` が使えない場合は、以下を繰り返し実行してください。
```bash
kubectl get pods -l serving.knative.dev/service=restaurant-demo
```

負荷テスト終了後、Pod数が減っていく様子を確認します。

```bash
kubectl get pods -l serving.knative.dev/service=restaurant-demo
```

### ゼロスケールの体験（オプション）

`restaurant-knative-service.yaml` の `minScale` を `"0"` に変更してから適用します。

```bash
kubectl apply -f restaurant-knative-service.yaml
```

3分ほど待つとPod数が0になります。

```bash
kubectl get pods -l serving.knative.dev/service=restaurant-demo
```

再度アクセスするとPodが起動します（コールドスタート）。

```bash
docker run --rm --network kind curlimages/curl:latest curl -H "Host: restaurant-demo.default.example.com" http://172.19.255.200/menu
```

```bash
kubectl get pods -l serving.knative.dev/service=restaurant-demo
```

体験後は `minScale` を `"1"` に戻して再適用します。

```bash
kubectl apply -f restaurant-knative-service.yaml
```

---

## Kubernetesの可視化と監視（Grafana / Prometheus）

### Helmのインストール（macOS）

```bash
brew install helm
```

```bash
helm version
```

### kube-prometheus-stackのインストール

以下の手順をまとめて実行するスクリプトを用意しています。一括実行する場合は次のコマンドだけで完了します（個別に確認したい場合は下の手順に従ってください）。

```bash
cd samples/chapter5
./install-prometheus-stack.sh
```

#### 個別に実行する場合

1. Helmリポジトリを追加します。

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

2. インストール用Namespaceを作成します。

```bash
kubectl create namespace monitoring
```

3. kube-prometheus-stackをインストールします（学習用に管理者パスワードを `admin` に設定）。

```bash
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=admin
```

4. インストールを確認します（すべて `Running` になるまで数分待ちます）。

```bash
kubectl get pods -n monitoring
```

### Grafanaダッシュボードへのアクセス

port-forwardを設定します（実行したまま、ブラウザで `http://localhost:3000` にアクセス。ログインは admin / admin）。

```bash
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80
```

### カスタムダッシュボードのPromQL（Grafana入力用）

以下はシェルコマンドではなく、Grafanaのパネル作成時にクエリ入力欄（Codeモード）へ貼り付けるPromQLです。

Pod数の推移:

```
count(kube_pod_info{namespace="default", pod=~"restaurant-demo.*"})
```

PodのCPU使用率:

```
sum(rate(container_cpu_usage_seconds_total{namespace="default", pod=~"restaurant-demo.*", container!=""}[1m])) by (pod)
```

### グラフを確認するための負荷テスト（並行数40・2分間）

```bash
docker run --rm --network kind williamyeh/hey:latest -z 2m -c 40 -host "restaurant-demo.default.example.com" http://172.19.255.200/menu
```

---

## 後片付け

### KNative Serviceの削除

```bash
kubectl delete ksvc restaurant-demo
```

### Grafana / Prometheusの削除（不要な場合）

```bash
# kube-prometheus-stackを削除
helm uninstall prometheus-stack -n monitoring

# monitoring Namespaceを削除
kubectl delete namespace monitoring
```

### クラスタごと削除して再作成する（クリーンな状態に戻す場合）

```bash
kind delete cluster --name k8s-demo-cluster
```

```bash
cd samples/chapter3
kind create cluster --config kind-config.yaml --name k8s-demo-cluster
```
