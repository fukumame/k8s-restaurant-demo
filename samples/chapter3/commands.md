# 第3章 コマンド集（コピペ実行用）

第3章「Kubernetes環境構築」で実行するコマンドを、書籍の流れに沿ってまとめています。上から順にコピペして実行できます。
LensはGUIツールのため、コマンドはありません（本ファイルはCLI操作のみを掲載しています）。

## 補足
- Mac版とWindows版でコマンドが異なる箇所があります。お使いの環境に合わせて実行してください。
- 各ツール（kubectl・kindなど）のバージョン番号は、実行時点の最新版によって出力が異なります。

---

## 1. Docker Desktop のインストール確認

```bash
docker --version
```

---

## 2. kubectl のインストール

### Mac版

Homebrew が未導入の場合はインストールします（`samples/chapter3/install-homebrew.sh` を実行しても同じです）。

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

インストール後、ターミナルに表示される指示に従って PATH を通します（`(username)` の部分はご自身のユーザー名に置き換わります）。

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/(username)/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

kubectl をインストールします。

```bash
brew install kubectl
```

### Windows版

Chocolatey が未導入の場合は、管理者権限の PowerShell でインストールします（`samples/chapter3/install-chocolatey.ps1` を管理者権限で実行しても同じです）。

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

kubectl をインストールします。

```powershell
choco install kubernetes-cli
```

### インストール確認（Mac/Windows共通）

```bash
kubectl version --client
```

---

## 3. kind のインストール

### Mac版

```bash
brew install kind
```

### Windows版

```powershell
choco install kind
```

### インストール確認（Mac/Windows共通）

```bash
kind version
```

---

## 4. クラスタの構築

クラスタ設定ファイル `kind-config.yaml` はこのディレクトリ（`samples/chapter3/`）に用意されています。

```bash
cd samples/chapter3/
kind create cluster --config kind-config.yaml --name k8s-demo-cluster
```

---

## 5. クラスタ構築の確認

利用可能なクラスタ（context）の一覧を確認します。

```bash
kubectl config get-contexts
```

kindで作成したクラスタをcontextとして設定します。

```bash
kubectl config use-context kind-k8s-demo-cluster
```

ノードの状態を確認します（すべて `Ready` になっていれば成功です）。

```bash
kubectl get nodes
```
