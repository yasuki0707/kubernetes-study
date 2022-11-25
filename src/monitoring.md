# Monitoring

## Kubernetes におけるモニタリング

一般的な Kubernetes モニタリングツールはホストを中心に監視するように設計されているため、コンテナの複雑な挙動を追跡するのが困難。  
以下の二つのツールは、監視対象をクエリすることでコンテナベースのモニタリングが可能になる。

-   Datadog
-   Prometheus

**運用管理コスト**

| | Datadog | Prometheus |
| | :-----------------: | :-----------------------------------: |
| メトリクスデータの管理コスト | 低(Datadog 側管理) |高 |
| ホスト/コンテナに対する課金 | 高 |なし |

## Datadog

DaemonSet で各ノードに Agent を起動する。  
各 Agent は、ホストの CPU 使用率/ディスク使用率や各ノード上のコンテナ CPU 使用率などのメトリクスを取得する。

### インストール

[3 パターン](https://docs.datadoghq.com/ja/containers/kubernetes/installation/?tab=operator)のインストール方法がある:

-   Datadog Operator
-   Helm チャート
-   DaemonSet

Helm を利用したインストールが簡潔なので、ここではその方法を紹介する。

以下のような values.yaml を用意する。

```yaml title="" hl_lines="2-4"
datadog:
    apiKey: <XXXXXXXXXXXX>
    appKey: <YYYYYYYYYYYY>
    tags: <tag1, tag2,..>
    clusterAgent:
        enabled: true
        metricsProvider:
            enabled: true
    processAgent:
        enabled: true
        processCollection: true
    collectEvents: true
    leaderElection: true
```

これを適用する。

```sh title=""
helm install <release_name> stable/datadog \
--version x.y.z \
-f values.yaml
```

### メトリクス

各コンテナの CPU 使用率/メモリ消費量/起動時間など 2 秒おきに送られてくる。

**メトリクスの種類**

|   メトリクスキー    |                 概要                  |
| :-----------------: | :-----------------------------------: |
|      docker.\*      |   Docker コンテナに関するメトリクス   |
|    kubernetes.\*    |     Kubernetes に関するメトリクス     |
| kubernetes_state.\* | Kubernetes クラスタレベルのメトリクス |

### コンテナマップ

タグによってグルーピングした内容を色分けして可視化する機能。

### さまざまなモニタリング方法

-   Anomaly モニタリング: 異常検知
-   Forecast モニタリング: 予兆検知
-   Outlier モニタリング: 外れ検知

---

## Prometheus

CNCF による OSS。  
以下の構成要素からなる

-   Prometheus Server
-   Exporter
-   Alert Manage
-   Push Gateway

### アーキテクチャ

Prometheus Server が各データソースに収集しにいく **Pull** 型。  
Prometheus Server が各種メトリクスに対して閾値を超えたと判断した場合、Alert Manager に対して発砲のリクエスト(メール、Slack, PagerDuty etc.)を行う。  
メトリクスの可視化には、[Grafana](https://grafana.com/) を利用することが多い。
