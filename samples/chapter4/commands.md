# 第4章 コマンド集（コピペ実行用）

第4章「Kubernetesの基本操作とサービス構築」で実行するコマンドを、書籍の流れに沿ってまとめています。上から順にコピペして実行できます。

- マニフェスト（YAML）はこのディレクトリ（`samples/chapter4/`）に用意されています。`kubectl apply -f <ファイル名>` でそのまま適用できます。
- 前提: 第3章で構築したkindクラスタ（context: `kind-k8s-demo-cluster`）を使用します。


## コマンド内のプレースホルダーについて
- `restaurant-demo-rs-xxxxx` や `<Pod名>` などは、`kubectl get pods` で表示される実際の名前に置き換えてください。
- `172.19.0.7` / `172.19.255.200` などのIPアドレスは、ご自身の環境で確認した実際の値に置き換えてください。
- `kubectl port-forward` は実行したまま待機します。確認が終わったら `Ctrl+C` で停止してください。`curl` は別のターミナルを開いて実行します。

---

## Pod、ReplicaSet、Deployment

### WebサービスをPodとして起動

```bash
kubectl apply -f restaurant-pod.yaml
```

```bash
kubectl get pods
```

```bash
kubectl logs restaurant-demo-pod
```

Podにアクセスします。

```bash
# 【ターミナル1】起動したまま待機します（確認後 Ctrl+C）
kubectl port-forward pod/restaurant-demo-pod 8000:8000
```

```bash
# 【ターミナル2】別のターミナルで実行します
curl http://127.0.0.1:8000/menu
```

Podを削除します（port-forwardは先に `Ctrl+C` で停止しておきます）。

```bash
kubectl delete pod restaurant-demo-pod
```

```bash
kubectl get pods
```

### ReplicaSetによる冗長化

```bash
kubectl apply -f restaurant-replicaset.yaml
```

```bash
kubectl get pods -l app=restaurant-demo
```

Podを1つ削除して、自動で再作成される様子を確認します（`xxxxx` は実際のPod名に置き換えてください）。

```bash
kubectl delete pod restaurant-demo-rs-xxxxx
```

Deploymentに移行する前に、ReplicaSetを削除します。

```bash
kubectl delete replicaset restaurant-demo-rs
```

```bash
kubectl get replicasets
kubectl get pods -l app=restaurant-demo
```

### DeploymentでPodの更新と管理を楽にする

```bash
kubectl apply -f restaurant-deployment.yaml
```

```bash
kubectl get deployments
kubectl get pods -l app=restaurant-demo
```

```bash
kubectl rollout status deploy/restaurant-demo-deploy
```

アクセスして確認します。

```bash
# 【ターミナル1】
kubectl port-forward deploy/restaurant-demo-deploy 8000:8000
```

```bash
# 【ターミナル2】
curl http://127.0.0.1:8000/menu
```

#### 新しいバージョンへ更新する

`restaurant-deployment.yaml` をエディタで開き、以下の2箇所を変更してから再適用します。

- `image` を `1.0.0` → `2.0.0` に変更
- `MENU_NAME` を「焼き立てクロワッサン」→「季節のフルーツタルト」に変更

```bash
kubectl apply -f restaurant-deployment.yaml
```

```bash
kubectl rollout status deploy/restaurant-demo-deploy
```

```bash
# 【ターミナル1】
kubectl port-forward deploy/restaurant-demo-deploy 8000:8000
```

```bash
# 【ターミナル2】
curl http://127.0.0.1:8000/menu
```

ログを確認します。

```bash
kubectl logs -l app=restaurant-demo --tail=10
```

#### ロールバックして元に戻す

```bash
kubectl rollout history deploy/restaurant-demo-deploy
```

```bash
kubectl rollout undo deploy/restaurant-demo-deploy
```

```bash
kubectl rollout status deploy/restaurant-demo-deploy
```

```bash
# 【ターミナル1】
kubectl port-forward deploy/restaurant-demo-deploy 8000:8000
```

```bash
# 【ターミナル2】
curl http://127.0.0.1:8000/menu
```

---

## ConfigMapとSecret

### ConfigMapで設定値を保存

```bash
kubectl apply -f restaurant-configmap.yaml
```

```bash
kubectl describe configmap restaurant-config
```

ConfigMapを環境変数として読み込むDeploymentを適用します。

```bash
kubectl apply -f restaurant-deployment-with-configmap.yaml
```

```bash
kubectl logs -l app=restaurant-demo --tail=10
```

#### ConfigMapの値を変更してみる

`kubectl edit` で直接編集するか（`MENU_NAME` を `シーフードピザ` に変更）、YAMLを編集して再適用します。

```bash
kubectl edit configmap restaurant-config
```

```bash
# （YAMLを編集して再適用する場合）
kubectl apply -f restaurant-configmap.yaml
```

Podを再起動して変更を反映します。

```bash
kubectl rollout restart deploy/restaurant-demo-deploy
```

ログとレスポンスを確認します。

```bash
kubectl logs -l app=restaurant-demo --tail=10
```

```bash
# 【ターミナル1】
kubectl port-forward deploy/restaurant-demo-deploy 8000:8000
```

```bash
# 【ターミナル2】
curl http://127.0.0.1:8000/menu
```

### Secretで機密情報を保存

Base64エンコードの確認（任意）。

```bash
echo -n "secret_recipe_with_special_sauce" | base64
echo -n "password123" | base64
```

Secretを適用します。

```bash
kubectl apply -f restaurant-secret.yaml
```

YAMLを使わず、コマンドで直接作成することもできます（Base64エンコード不要）。

```bash
kubectl create secret generic restaurant-secret \
  --from-literal=SECRET_RECIPE="secret_recipe_with_special_sauce" \
  --from-literal=DB_PASSWORD="password123"
```

作成したSecretを確認します。

```bash
kubectl describe secret restaurant-secret
```

実際の値を確認する場合（Base64デコード）。

```bash
kubectl get secret restaurant-secret -o jsonpath='{.data.SECRET_RECIPE}' | base64 -d
```

Secretを環境変数として読み込むDeploymentを適用します。

```bash
kubectl apply -f restaurant-deployment-with-secret.yaml
```

```bash
kubectl logs -l app=restaurant-demo --tail=10
```

#### Secretの値を変更してみる

新しい値で上書きします（`create` の結果を `apply` に渡すことで、既存のSecretを更新できます）。

```bash
kubectl create secret generic restaurant-secret \
  --from-literal=SECRET_RECIPE="new_secret_recipe_for_premium_sauce" \
  --from-literal=DB_PASSWORD="new_secure_password456" \
  --dry-run=client -o yaml | kubectl apply -f -
```

Podを再起動して変更を反映します。

```bash
kubectl rollout restart deploy/restaurant-demo-deploy
```

```bash
kubectl logs -l app=restaurant-demo --tail=10
```

---

## Serviceと外部公開

### 事前確認：Deploymentの起動状態

```bash
kubectl apply -f restaurant-deployment.yaml
kubectl rollout status deployment/restaurant-demo-deploy
```

```bash
kubectl get pods -l app=restaurant-demo
```

### ClusterIP

```bash
kubectl apply -f restaurant-service-clusterip.yaml
```

```bash
kubectl get svc restaurant-service-clusterip
```

#### アクセステスト方法1: port-forward

```bash
# 【ターミナル1】
kubectl port-forward svc/restaurant-service-clusterip 8000:80
```

```bash
# 【ターミナル2】
curl http://127.0.0.1:8000/menu
```

#### アクセステスト方法2: クラスタ内の別Podから

一時的なPodを起動してシェルに入ります。

```bash
kubectl run curl-test --image=curlimages/curl:latest --rm -it --restart=Never -- sh
```

Pod内で実行します（DNS名でアクセス）。

```bash
curl http://restaurant-service-clusterip.default.svc.cluster.local/menu
```

シェルを抜けます（`--rm` 指定のためPodは自動削除されます）。

```bash
exit
```

### NodePort

```bash
kubectl apply -f restaurant-service-nodeport.yaml
```

```bash
kubectl get svc restaurant-service-nodeport
```

ノードのIPアドレスを確認します。

```bash
kubectl get nodes -o wide
```

kindクラスタが使うDockerネットワークを確認します。

```bash
docker network ls | grep kind
```

同じDockerネットワーク内のコンテナからアクセスします（`172.19.0.7` は実際のノードIPに置き換えてください）。

```bash
docker run --rm --network kind curlimages/curl:latest curl http://172.19.0.7:30080/menu
```

インタラクティブに確認する場合。

```bash
docker run --rm -it --network kind curlimages/curl:latest sh
```

```bash
# コンテナ内で実行
curl http://172.19.0.7:30080/menu
```

### LoadBalancer（MetalLB）

#### MetalLBのインストール

MetalLBのマニフェストを適用します（本書では `v0.15.3`。最新版は公式リリースページで確認してください）。

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.3/config/manifests/metallb-native.yaml
```

Podが起動するまで待機します。

```bash
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=90s
```

> 上記2コマンドは、`samples/chapter4/install-metallb.sh` で一括実行できます。
> ```bash
> cd samples/chapter4
> ./install-metallb.sh
> ```

```bash
kubectl get pods -n metallb-system
```

#### IPアドレスプールの設定

DockerネットワークのIPレンジを確認します。

```bash
docker network inspect kind | grep -A 5 "Subnet"
```

IPアドレスプール（`metallb-ip-pool.yaml`）を適用します。

```bash
kubectl apply -f metallb-ip-pool.yaml
```

#### LoadBalancer Serviceの作成

```bash
kubectl apply -f restaurant-service-loadbalancer.yaml
```

```bash
kubectl get svc restaurant-service-loadbalancer
```

外部IPアドレスにアクセスします（`172.19.255.200` は実際のEXTERNAL-IPに置き換えてください）。

```bash
docker run --rm --network kind curlimages/curl:latest curl http://172.19.255.200/menu
```

---

## データを永続化する方法

### データが消えることを確認する

volumeマウントなしのDeploymentを適用します。

```bash
kubectl apply -f restaurant-deployment-temp.yaml
```

Pod内にレシピファイルを作成します。

```bash
kubectl exec -it deploy/restaurant-demo-temp -- sh -c "mkdir -p /app/recipes && echo '一時保存のシーフードピザのレシピ' > /app/recipes/recipe.txt"
```

レシピを確認します。

```bash
# 【ターミナル1】
kubectl port-forward deploy/restaurant-demo-temp 8000:8000
```

```bash
# 【ターミナル2】
curl http://127.0.0.1:8000/recipe
```

Podを削除してデータが消えることを確認します（port-forwardは先に `Ctrl+C`）。

```bash
kubectl delete pod -l app=restaurant-demo-temp
```

```bash
# 【ターミナル1】新しいPod起動後に再度実行
kubectl port-forward deploy/restaurant-demo-temp 8000:8000
```

```bash
# 【ターミナル2】"レシピファイルが見つかりません" になる
curl http://127.0.0.1:8000/recipe
```

### PersistentVolumeClaimでデータを永続化する

PVCを適用します。

```bash
kubectl apply -f recipe-pvc.yaml
```

```bash
kubectl get pvc recipe-pvc
```

デモで使ったDeploymentを削除します。

```bash
kubectl delete deploy restaurant-demo-temp
```

PVCを使うDeploymentを適用します。

```bash
kubectl apply -f restaurant-deployment-with-pvc.yaml
```

PVCが `Bound` になり、PVが自動作成されたことを確認します。

```bash
kubectl get pvc recipe-pvc
```

レシピファイルを作成します。

```bash
kubectl exec -it deploy/restaurant-demo-deploy -- sh -c "echo '永久保存版シーフードピザのレシピ' > /app/recipes/recipe.txt"
```

レシピを確認します。

```bash
# 【ターミナル1】
kubectl port-forward deploy/restaurant-demo-deploy 8000:8000
```

```bash
# 【ターミナル2】
curl http://127.0.0.1:8000/recipe
```

Podを削除してもデータが残ることを確認します。

```bash
kubectl delete pod -l app=restaurant-demo
```

```bash
# 【ターミナル1】新しいPod起動後に再度実行
kubectl port-forward deploy/restaurant-demo-deploy 8000:8000
```

```bash
# 【ターミナル2】レシピが残っている
curl http://127.0.0.1:8000/recipe
```

---

## StatefulSet、DaemonSet、CronJob

### StatefulSet

Headless Service → StatefulSet の順で適用します。

```bash
kubectl apply -f nginx-statefulset-service.yaml
kubectl apply -f nginx-statefulset.yaml
```

固定の名前でPodが作成されていることを確認します。

```bash
kubectl get pods -l app=nginx-statefulset
```

各Podに専用のPVCが作成されていることを確認します。

```bash
kubectl get pvc
```

DNS名で名前解決できることを確認します（`busybox` の一時Podを使用）。

```bash
kubectl run -it --rm dns-check --image=busybox:1.36 --restart=Never -- \
  nslookup nginx-statefulset-1.nginx-statefulset.default.svc.cluster.local
```

各Podに異なるHTMLコンテンツを配置します。

```bash
# Pod 0
kubectl exec -it nginx-statefulset-0 -- sh -c 'echo "Chef 1 Kitchen - Pod 0" > /usr/share/nginx/html/index.html'

# Pod 1
kubectl exec -it nginx-statefulset-1 -- sh -c 'echo "Chef 2 Kitchen - Pod 1" > /usr/share/nginx/html/index.html'

# Pod 2
kubectl exec -it nginx-statefulset-2 -- sh -c 'echo "Chef 3 Kitchen - Pod 2" > /usr/share/nginx/html/index.html'
```

各Podにアクセスして、異なるコンテンツが表示されることを確認します（それぞれ別のターミナルで実行）。

```bash
# 【ターミナル1】ブラウザで http://localhost:8080
kubectl port-forward nginx-statefulset-0 8080:80
```

```bash
# 【ターミナル2】ブラウザで http://localhost:8081
kubectl port-forward nginx-statefulset-1 8081:80
```

```bash
# 【ターミナル3】ブラウザで http://localhost:8082
kubectl port-forward nginx-statefulset-2 8082:80
```

Podを再作成してもコンテンツが保持されることを確認します。

```bash
kubectl delete pod nginx-statefulset-0
```

```bash
# Podが再作成される様子を監視（確認後 Ctrl+C）
kubectl get pods -l app=nginx-statefulset -w
```

#### 後片付け（StatefulSet）

StatefulSetを削除してもPVCは残るため、個別に削除します。

```bash
kubectl delete statefulset nginx-statefulset
kubectl delete service nginx-statefulset
kubectl delete pvc -l app=nginx-statefulset
```

### DaemonSet

```bash
kubectl apply -f node-info-daemonset.yaml
```

```bash
kubectl get daemonset
```

各ノードにPodが1つずつ配置されていることを確認します。

```bash
kubectl get pods -l app=node-info -o wide
```

各Podのログを確認します。

```bash
kubectl logs -l app=node-info --tail=5 | head -2
```

#### Deploymentとの違いを比較する

比較用にnginxのDeploymentを適用します。

```bash
kubectl apply -f nginx-deployment.yaml
```

```bash
# Deployment: 指定したreplicas数（3）。配置ノードはKubernetesが決定
kubectl get pods -l app=nginx-deployment -o wide
```

```bash
# DaemonSet: 各ノードに1つずつ
kubectl get pods -l app=node-info -o wide
```

#### 後片付け（DaemonSet）

```bash
kubectl delete daemonset node-info
kubectl delete deployment nginx-deployment
```

### CronJob

```bash
kubectl apply -f inventory-check-cronjob.yaml
```

```bash
kubectl get cronjob
```

スケジュールに従ってJobが作成されることを確認します。

```bash
kubectl get jobs
```

Jobが作成したPodを確認します。

```bash
kubectl get pods -l job-name
```

実行結果（ログ）を確認します（`<Pod名>` は上記で確認した実際のPod名に置き換えてください）。

```bash
kubectl logs <Pod名>
```

#### 後片付け（CronJob）

```bash
kubectl delete cronjob inventory-check
```
