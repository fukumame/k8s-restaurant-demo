# 書籍サンプルコード
このレポジトリは、「[イメージで理解！Kubernetesを始める人が最初に読む本(C&R研究所)](https://www.c-r.com/book/detail/1623)」で使われるサンプルコードを管理するためのレポジトリです。

**本リポジトリは学習用サンプルです。本番環境では使用しないでください。**

- `restaurant-secret.yaml` に含まれる `DB_PASSWORD` や `SECRET_RECIPE` などの値は、すべて解説用のダミーです。実在するクレデンシャルではありません。
- Kubernetes の Secret の `data` は **暗号化ではなく単なる Base64 エンコード**であり、誰でも復号できます。本番では実際のパスワードをそのまま記載せず、外部シークレット管理（External Secrets、Sealed Secrets、クラウドの KMS など）の利用を検討してください。
- `install-prometheus-stack.sh` の Grafana 管理者パスワードはローカル検証用のデフォルト値（`admin`）です。公開環境では必ず変更してください。

## お詫びと補足

### リソース要求・制限について

書籍本文では、コンテナの「リソース要求・制限（`resources`）」の解説が抜けておりました。読者の皆さまに深くお詫び申し上げます。

本書掲載のマニフェストには、各コンテナの CPU・メモリのリソース要求（`requests`）と制限（`limits`）の記述が含まれていませんでした。  
実運用では、この設定が無いと次のような問題が起こり得ます。

- `requests` が無い場合: スケジューラが必要リソースを把握できず、Pod のノードへの配置（スケジューリング）が適切に行われません。
- `limits` が無い場合: 1 つのコンテナがノードの CPU・メモリを使い切り、同じノード上の他の Pod に悪影響を与えることがあります。

本リポジトリのサンプルでは、学習の参考になるよう 各マニフェストに `resources` を追記済みです。  
そのため、書籍誌面のマニフェストとは一部記述が異なります（誌面には `resources` の行はありません）。あらかじめご了承ください。

追記している設定の例（`restaurant-deployment.yaml`）:

```yaml
resources:
  requests:        # スケジューリング時に確保される最低限のリソース
    cpu: "100m"
    memory: "128Mi"
  limits:          # 使用量の上限。CPU は使用量が上限までに制限される（動作が遅くなるだけ）が、メモリは超えるとコンテナが強制終了される
    cpu: "500m"
    memory: "256Mi"
```

### `ImagePullBackOff` でイメージが取得できなかった件について

書籍サンプルで使用する Docker イメージの一部が、一時期 amd64（x86_64）環境で取得できず、`ImagePullBackOff` となる不具合がありました。読者の皆さまにご迷惑をおかけし、深くお詫び申し上げます。なお、本不具合はすでに解消済みです。

第4章などで Deployment や Pod を適用した際、次のように Pod が起動せず `ImagePullBackOff` になる状態でした。

```
NAME                                      READY   STATUS             RESTARTS   AGE
restaurant-demo-deploy-xxxxxxxxxx-xxxxx   0/1     ImagePullBackOff   0          11m
```

原因は、公開していた `docker.io/fukumame/k8s-restaurant-demo` イメージを、著者の作業環境（Apple Silicon Mac）向けの arm64 版のみでビルドして公開しており、amd64（x86_64）版を含めていなかったことです。Docker のイメージは CPU アーキテクチャ（amd64 / arm64 など）ごとに中身が分かれているため、amd64 環境では対応するイメージが見つからず、取得に失敗していました。マニフェストのイメージ名・タグは正しく、読者の皆さまの操作や設定に誤りがあったわけではありません。

対応済みの内容として、書籍で使用するすべてのイメージ（`1.0.0` / `2.0.0` / `secret_recipe` / `volume`）を、amd64・arm64 の両対応（マルチアーキテクチャ）で公開し直しました。イメージ名・タグは従来と同じため、マニフェスト（YAML）の変更は不要です。

すでに `ImagePullBackOff` となった Pod が残っている場合は、再適用いただくと新しいイメージを取得して起動します。

```bash
kubectl apply -f restaurant-deployment.yaml
```

状態が変わらない場合は、失敗している Pod を削除してください（再作成時にイメージを取得し直します）。

```bash
kubectl delete pod -l app=restaurant-demo
```

### 負荷テストでオートスケールしない場合について

第5章の負荷テストでは、`hey` の並行数40（`-c 40`）でオートスケール（負荷に応じて Pod が増える様子）を確認する手順を掲載しています。しかし、本アプリのレスポンスが数ミリ秒と非常に高速なため、環境によっては並行数40では 1Pod あたりの同時リクエスト数がオートスケールの閾値（`restaurant-knative-service.yaml` の `target: "30"`）に安定して到達せず、Pod が増えないことがあります。  
その場合は、並行数を 200（`-c 200`）に増やして再実行すると、Pod が増えていく様子を確認できます。 もしそれでもオートスケールしない場合は、この`-c`オプションの数字を変えることで並列数を更に増やす事も可能です。

```bash
docker run --rm --network kind williamyeh/hey:latest -z 3m -c 200 -host "restaurant-demo.default.example.com" http://172.19.255.200/menu
```

本リポジトリの [第5章 コマンド集](samples/chapter5/commands.md) には、この補足（並行数200での再実行）を追記済みです。

## コマンド集（コピペ実行用）

各章で実行するコマンドを、書籍の流れに沿ってコピペ実行できる形でまとめています。書籍を読みながら手で打つ代わりに、上から順にコピペして進められます。

- [第3章 コマンド集](samples/chapter3/commands.md) … 環境構築（Docker Desktop / kubectl / kind / クラスタ作成）
- [第4章 コマンド集](samples/chapter4/commands.md) … Pod / ReplicaSet / Deployment / ConfigMap / Secret / Service / Volume / StatefulSet / DaemonSet / CronJob
- [第5章 コマンド集](samples/chapter5/commands.md) … KNative / hey負荷テスト / Grafana・Prometheus監視

第1章・第2章は概念解説のため、実行コマンドはありません。

## ディレクトリ構成

- **第3章/** … Kubernetes環境構築（kind の設定など）
- **第4章/** … Pod / ReplicaSet / Deployment / ConfigMap / Secret / Service / Volume / StatefulSet / DaemonSet / CronJob のマニフェストとアプリ簡略版
- **第5章/** … Knative Serving 用の ConfigMap と KNative Service のマニフェスト

## 第3章で使うファイル

| ファイル | 説明 |
|----------|------|
| `commands.md` | 本章のコマンドをコピペ実行用にまとめたもの |
| `kind-config.yaml` | 1 control-plane + 2 workers の kind クラスタ用設定 |
| `install-homebrew.sh` | macOS 向け Homebrew インストールスクリプト |
| `install-chocolatey.ps1` | Windows 向け Chocolatey インストールスクリプト |

**最小手順**

1. `samples/chapter3/` に移動する
2. `kind create cluster --config kind-config.yaml --name k8s-demo-cluster` でクラスタを作成する

## 第4章で使うファイル

| ファイル | 説明 |
|----------|------|
| `commands.md` | 本章のコマンドをコピペ実行用にまとめたもの |
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
| `commands.md` | 本章のコマンドをコピペ実行用にまとめたもの |
| `config-domain.yaml` | Knative のカスタムドメイン用 ConfigMap（`example.com`） |
| `restaurant-knative-service.yaml` | KNative Service（FastAPI アプリ） |

**最小手順**

1. 第5章の原稿に従い、Knative Serving と Kourier をインストールする
2. `kubectl apply -f config-domain.yaml` でドメインを設定する
3. `kubectl apply -f restaurant-knative-service.yaml` で KNative Service をデプロイする
