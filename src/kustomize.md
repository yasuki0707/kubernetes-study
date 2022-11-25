# Kustomize

## Kustomize とは

Kubernetes マニフェストのテンプレーティングツール。  
環境ごとに作成するマニフェストを切り替えたり、特定のフィールドを上書きすることでマニフェストの作成を効率化する。

## Kustomize の使用法

### 複数マニフェストの結合

以下のような YAML ファイルを作成し、

```yaml title="res_dir/kustomization.yaml"
resources:
    - deployment.yaml
    - service.yaml
    - pvc.yaml
```

以下コマンドで、マニフェストファイルを一個に結合する。

```sh title=""
kubectl kustomize <res_dir>

# will generate:
#<deployment.yaml の内容>
#---
#<service.yaml の内容>
#---
#<pod.yaml の内容>
```

### Namespace の上書き

```yaml title="res_dir/kustomization.yaml" hl_lines="1"
namespace: <namespace_name>
resources:
    - deployment.yaml
    - service.yaml
    - pvc.yaml
```

`kubectl kustomize res_dir` により生成されるマニフェストファイルの中で、`metadata.namespace: <namespace_name>`が追加される。

### Prefix / Suffix の付与

```yaml title="res_dir/kustomization.yaml" hl_lines="1-2"
namePrefix: fuga-
nameSuffix: -hoge
resources:
    - deployment.yaml
    - service.yaml
    - pvc.yaml
```

`kubectl kustomize res_dir` により生成されるマニフェストファイルの中で、`metadata.name`が それぞれ`fuga-deployment-hoge`, `fuga-service-hoge`, `fuga-pvc-hoge`となる。

### 共通メタデータ(ラベル/アノテーション)の付与

全てのリソースに共通のラベル/アノテーションを付与する。

```yaml title="res_dir/kustomization.yaml" hl_lines="1-4"
commonLabels:
    label1: fancy-label
commonAnnotations:
    annotation1: cool-annotation
resources:
    - deployment.yaml
    - service.yaml
```

`kubectl kustomize res_dir` により生成されるマニフェストファイルの中で、`metadata.annotations.annotation1: cool-annotation`が追加される。  
また、ラベルに関しては、以下のように必要なところに追加される。

-   [Service]
    -   `metadata.labels.label1: fancy-label`
    -   `spec.selector.label1: fancy-label`
-   [Deployment]
    -   `metadata.labels.label1: fancy-label`
    -   `spec.selector.matchLabels.label1: fancy-label`
    -   `spec.template.metadata.labels.label1: fancy-label`

### images によるイメージの上書き

```yaml title="res_dir/kustomization.yaml" hl_lines="1-4"
images:
    - name: <image_name>
    - newName: <image_new_name> # newName と newTag のどちらか一方の指定で良い
    - newTag: <image_new_tag> # newName と newTag のどちらか一方の指定で良い
resources:
    - deployment.yaml
    - service.yaml
```

`kubectl kustomize res_dir` により生成されるマニフェストファイル(Deployment)の中で、`spec.tamplate.spec.containers.image` が `<image_new_name>:<image_new_tag>` に上書きされる。

### Overlay による値の上書き

メタデータ系データ以外の設定を実現する。

```yaml title="prd_res_dir/kustomization.yaml" hl_lines="1-4"
bases:
    - ../<res_dir>/ # ベースとなるマニフェスト
patchesStrategicMerge:
    - ./patch-replicas.yaml
```

```yaml title="prd_res_dir/patch-replicas.yaml" hl_lines="4-5"
apiVersion: apps/v1
kind: Deployment
..
spec:
    replicas: 100
```

`kubectl kustomize prd_res_dir` により生成されるマニフェストファイル(Deployment)の中で、`spec.replicas` が `100` に上書きされる。

### ConfigMap と Secret の動的な生成

```yaml title="config-map/kustomization.yaml" hl_lines="3-8"
resources:
    - deployment.yaml
configMapGenerator:
- name: <cm_name>
    literals:
    - KEY1=VAL1 # 直接記述
    files:
    - ./sample.txt # ファイルに記述
```

`kubectl kustomize config_map` により、

-   kind: ConfigMap に対して
    -   `data` の設定と、`metadata.name: <cm_name>-<hash>` // ハッシュ値がサフィックスとして付与される
-   kind: Deployment に対して
    .-   `spec.template.spec.containers.envFrom.configMapRef.name` が `metadata.name: <cm_name>-<hash>` に置換される

### Kustomize に関連する kubectl サブコマンド

割愛
