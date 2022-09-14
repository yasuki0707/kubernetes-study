# Service

## Session のその他機能

### Session Affinity

Kubernetes Service では、Session Affinity という機能を有効化できる(デフォルトでは OFF)。この機能は、クラスター外部からのリクエストが各 Pod に送られるとき、同じリクエスト元に対してはその後のトラフィックもずっと同じ Pod に対して送られるようにするもの。

下の例は、ClusterIP Service で Session Affinity を有効化する設定である。
`sessionAffinityConfig.clientIP.timeoutSeconds` で何秒セッションを保持するかを指定できる。

```yaml title="" hl_lines="13-16"
apiVersion: v1
kind: Service
metadata:
    name: my-service
spec:
    type: ClusterIP
    selector:
        app.kubernetes.io/name: MyApp
    ports:
        - protocol: TCP
          port: 80
          targetPort: 9376
    sessionAffinity: ClientIP
    sessionAffinityConfig:
        clientIP:
            timeoutSeconds: 10
```

注意点として、他の種類の Service(NodePort, LoadBalancer) でも利用可能であるが、あまり有用ではない。例えば、NodePort Service では、どの NodePort にリクエストを転送するかによって、同じクライアント IP アドレスでも同じ Pod に転送されるとは限らない(クライアント →Node が固定でも、結局 Node → Pod ではランダムに振り分けられるため)。

### ノード間通信の排除と送信元 IP アドレスの保持

NodePort/LoadBalancer Service では、Node に到達したリクエストはさらに Node を跨いだ Pod にロードバランシングされる。不必要な二段階ロードバランシングが行われることになり、大きなレイテンシとなる場合がある。  
一方で DaemonSet では、`1 Node = 1 Pod` で配置されるため、他 Node の Pod に転送したくないことがある。その場合には、以下のようにして実現できる。

```yaml title="" hl_lines="13"
apiVersion: v1
kind: Service
metadata:
    name: my-service
spec:
    type: NodePort
    selector:
        app.kubernetes.io/name: MyApp
    ports:
        - protocol: TCP
          port: 80
          targetPort: 9376
    externalTrafficPolicy: Local
```

これにより、外部からのリクエストがある Node に到達すると、その Node の Pod のみに転送される。同一 Node 上に複数 Pod が存在する場合には、それらに均等に配分される。また、**NodePort Service において、リクエストを受けた Node 上に Pod が存在しない場合には、転送は行われず、リクエストが処理されないということになるため、これは避けた方が良いだろう。**

`spec.externalTrafficPolicy` のデフォルト値は `Cluster` で、その場合は他 Node へのロードバランシングが有効となっている。
また、本機能は ClusterIP Service では利用不可である。

#### ヘルスチェック用 NodePort

LoadBalancer Service の場合、その Node 上に Pod が存在するかどうかを確認する用の NodePort があり、**この機構により Pod が存在しない Node にはリクエストが転送されないようになっている。**  
このヘルスチェック用 NodePort を明示的に指定するには、以下のようにする。

```yaml title="" hl_lines="13-14"
apiVersion: v1
kind: Service
metadata:
    name: my-service
spec:
    type: LoadBalancer
    selector:
        app.kubernetes.io/name: MyApp
    ports:
        - protocol: TCP
          port: 80
          targetPort: 9376
    externalTrafficPolicy: Local
    healthCheckNodePort: 30088
```

### トボロジを意識した Service 転送

基本的(デフォルト)には、Service によるリクエストの転送先 Pod はリージョンやアベイラビリティゾーンを考慮しない。それによるパフォーマンスの低下を避けるために、以下のようにするとよい。

```yaml title="" hl_lines="13-15"
apiVersion: v1
kind: Service
metadata:
    name: my-service
spec:
    type: ClusterIP
    selector:
        app.kubernetes.io/name: MyApp
    ports:
        - protocol: TCP
          port: 80
          targetPort: 9376
    topologyKeys:
        - kubernetes.io/hostname #優先度1: 同一 Node
        - "*" #優先度2: 全ての Pod が対象
```

`spec.topologyKeys` にはどのトポロジの範囲に転送を試みるかを優先度順に指定する。上記例では、まず転送元 Pod と同一 Node にある Pod への転送を試み、それでも見つからなかった場合は、別の Node にある Pod への転送を試みる。

#### `spec.topologyKeys` に設定可能なラベル

|         ラベル         |      範囲       |
| :--------------------: | :-------------: |
| kubernetes.io/hostname |    同一 Node    |
|   kubernetes.io/zone   |   同一 ゾーン   |
|  kubernetes.io/region  | 同一 リージョン |
|           \*           | いずれかの Node |

※ 「\*」を指定する場合は、優先度を一番低くすること

## その他の Service

### Headless Service

対象となる個々の Pod の IP アドレスが直接返ってくる Service。  
ロードバランシングするための IP アドレスは提供されず、DNS Round Robin を使ったエンドポイントを提供。

```yaml title="" hl_lines="6-7"
apiVersion: v1
kind: Service
metadata:
    name: my-service
spec:
    type: ClusterIP
    clusterIP: None
    selector:
        app.kubernetes.io/name: MyApp
    ports:
        - protocol: TCP
          port: 80
          targetPort: 9376
```

#### Pod 名による名前解決

以下の条件を満たすとき、Pod 名からその IP アドレスを取得することができる。  
`[Pod 名].[Service 名].[Namespace 名].svc.cluster.local`

条件:

-   StatefulSet が Headless Service を利用している
-   Service の `metadata.name` が StatefulSet の `spec.serviceName` と同じ

#### StatefulSet 以外の Pod 名の名前解決

以下の設定を行うことで、StatefulSet 以外の Pod に対しても名前解決が可能となる。

-   Pod の `spec.hostname` の設定
-   Headless Service の `metadata.name` と同じ `spec.subdomain` の設定

```yaml title="" hl_lines="4 21-22"
apiVersion: v1
kind: Service
metadata:
    name: default-subdomain
spec:
    selector:
        name: busybox
    clusterIP: None
    ports:
        - name: foo
          port: 1234
          targetPort: 1234
---
apiVersion: v1
kind: Pod
metadata:
    name: busybox1
    labels:
        name: busybox
spec:
    hostname: busybox-1
    subdomain: default-subdomain
    containers:
        - image: busybox:1.28
          command:
              - sleep
              - "3600"
          name: busybox
```

### ExternalName Service

Service 名の名前解決に対して外部のドメイン宛の CNAME(エイリアス的な) を返す。  
サービスのホスト名に別名を当てる目的などで使用される。

```yaml title="" hl_lines="7"
apiVersion: v1
kind: Service
metadata:
    name: sample-externalname
spec:
    type: ExternalName
    externalName: thisis.externalname.com
```

### Non-Selector Service

Kubernetes 内に自由な宛先でロードバランシング機能を作成できる。  
例えば、リクエストをクラスタ外部のアプリケーションサーバに分散したり、環境によってクラスタ内部/外部を切り替えたりするのに有用。  
基本的には、`type=ClusterIP` とし、externalName および Selector を指定しないことで、`Non-Selector Service` を作成できる。

```yaml title="" hl_lines="6"
apiVersion: v1
kind: Service
metadata:
    name: sample-externalname
spec:
    type: ClusterIP
    ports:
        name: hoge
        protocol: TCP
        port: 80
        targetPort: 80
```
