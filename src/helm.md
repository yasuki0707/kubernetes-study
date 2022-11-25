# Helm

## 背景

Kubernetes では、基本的には YAML 形式のマニフェストファイルを `kuberctl apply` していくことでクラスタの構成や管理を行う。  
しかし、システムが大規模になってくるとマニフェスト地獄になり、再利用や一括変更などが困難になる。  
そこで、これらマニフェストを汎用化し、マニフェストファイルの管理を容易にするためのツールの重要性が出てきた。
ここで紹介する Helm と Kustomize をうまく使うことで、この目的を達成できるようになる。

## Helm とは

Kubernetes の**パッケージマネージャ**。
アプリケーションの構築などをコマンド一発で実現可能だったりする。

## Helm の使用法

### [インストール](https://helm.sh/docs/intro/install/)

```sh title=""
$ curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
$ chmod 700 get_helm.sh
$ ./get_helm.sh
```

Helm はクライアント側で処理を行うため、kubectl と同じ認証情報を利用する(`~/.kube/config`)。  
`helm help` で Helm のさまざまなコマンドを確認できる。

### Helm リポジトリ追加

### Search

リポジトリや Helm Hub 上の Chart を検索する。

#### helm search repo

すでに追加されているリポジトリから Chart を検索する。

リポジトリの追加は以下コマンド

```sh title=""
helm repo add <name> <url> <flags>
```

追加したら そのリポジトリ上の Chart を検索する。  
`keyword` は、Chart 名及び Description の内容の部分一致検索。  
**デフォルトでは、最新の stable バージョンがヒットする。**

```sh title=""
helm search repo <keyword> <flags>
```

#### helm search hub

[Helm Hub](https://artifacthub.io/) 及び自分 Hub インスタンスから Chart を検索する。

```sh title=""
helm search hub <keyword> <flags>
```

### Chart

deb, rpm に相当するパッケージ。Kubernetes のマニフェストのテンプレートをまとめたもの。

#### インストール

色々パターンあるみたいです。

```sh title=""
helm install <release_name> <chart_nmae> \
--vetsion x.y.z \ # バージョン指定
--set username=fuga \ # 設定値を上書いてインストール
--set password=hoge \ # 設定値を上書いてインストール
```

コマンドで直接 set もできるし、あらかじめ設定項目を上書いたファイル(`values.yaml`)を用意してそれを適用することもできる。

```sh title=""
# values.yaml を吐き出す
helm show values <chart_name> > values.yaml

# values.yaml を適宜編集

helm install <release_name> <chart_nmae> \
--values values.yaml
```

もちろん、パスワードとかは values.yaml に記述しないでね ★

### Release

Chart をインストールした時のインスタンス? のようなイメージ?。  
Chart と 1:N の関係(1 つの Chart に対して複数の Release が存在しうる)。

```sh title=""
# インストール済みの Release の確認
helm list

# Release のアンインストール
helm uninstall <release_name>
```

### 独自 Chart の作成

単に Helm を利用してクラスターへのアプリケーション環境の構築を行うだけなら不要。  
自分で Chart を作成することで、自分好みの設定・環境を構築することが可能となる。

```sh title=""
helm create <chart_name>
```

新規作成時、デフォルトで、Deployment, Service, Ingress, HPA, ServiceAccount のリソーステンプレートが作成される。  
注意点として、Helm では Kubernetes のバージョンアップに追従する機能はないため、自分で Chart のマニフェストのメンテナンスを行う必要がある。

参考: [Helm の概要と Chart(チャート)の作り方](https://qiita.com/thinksphere/items/5f3e918015cf4e63a0bc)

### Chart のパッケージ化と Helm リポジトリの公開

```sh title=""
# requirement.yaml を元に Chart をパッケージ化する(.tgz)
helm package --dependency-update <package_name>
# <package_name.tgz> will be created

# 公開する Web サーバーのディレクトリに tgz を配置する

# Helm リポジトリの index を作成
helm repo index .
# あとは helm repo add でリポジトリの追加が行える状態になっている。
```
