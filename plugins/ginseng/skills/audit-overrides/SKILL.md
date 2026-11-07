---
name: audit-overrides
description: ginseng-* のメソッドを上書きしている箇所をアプリから機械的に抜き出し、上流へ返すか・写しを消すか・gem の不具合として出すかを振り分けて、上書きに印を付ける。各プロジェクトで一度だけ行う洗い出しの手順。
disable-model-invocation: true
---

# すでにある上書きを洗い出す

⚠⚠ **正本はこのファイル。** 規則（上書きを書くその場で返すかを決め、印を残す）は [docs/ginseng.md](https://github.com/pooza/ginseng-style/blob/main/docs/ginseng.md) の「上書きを書くときに、上流へ返すかを決めて印を残す」にある。ここは**規則ができる前に書かれた、印の無い上書き**を一度だけ片付ける手順。

⚠ **各プロジェクトのセッションが、そのプロジェクトで行う。** 当番（ginseng-style）からは起票しない。手本は [pooza/mulukhiya-toot-proxy#4898](https://github.com/pooza/mulukhiya-toot-proxy/issues/4898)。

## 手順

1. **Issue を 1 本立てる** — このプロジェクトの「ginseng-* 由来の上書きを見直す」。⚠ 一覧はそこに貼る（全部を一度に読めなくても、どこまで読んだかが残る）
2. **抜き出す** — 下の「抜き出し方」
3. **差し替え口の実装を除く** — `prefix` / `dir` / `command` / `default_service` のように、gem が上書きされる前提で用意した面を返すだけのもの。⚠ **印は要らない**。モロヘイヤでは 121 か所の大半がこれだった
4. **残りを振り分けて印を付ける** — 下の表。⚠ **印の書式は docs の規則のとおり**（`# ginseng-upstream:`）
5. **Issue を閉じる条件を書く** — 写しを消した／gem へ出した／返すかを決めて印を付けた、の 3 つ

## 抜き出し方

⚠ **`grep '< Ginseng::'` では足りない。** 継承しているクラスしか分からず、**どのメソッドを上書きしているか**も、**開き直し・`prepend`** も出ない。⚠ 読み込んだ上で調べる。

このスキルのディレクトリにある `scripts/overrides.rb` を、アプリのルートで実行する。

```sh
bundle exec ruby -I app/lib <スキルのディレクトリ>/scripts/overrides.rb <入口の .rb> <アプリの名前空間>
# 例: bundle exec ruby -I app/lib .../overrides.rb app/lib/mulukhiya.rb Mulukhiya > overrides.tsv
```

標準出力に TSV（種類・クラス・メソッド・上書きされた側・定義の場所）、標準エラーに件数と読めなかった定数が出る。

| 種類 | 意味 |
| --- | --- |
| `override` | アプリの Class / Module が Ginseng のメソッドを上書きしている |
| `prepend` | アプリのモジュールを Ginseng のクラスへ `prepend` している。⚠ **継承を見る方法では原理的に出ない**（モロヘイヤでは `HandlerProfile::HTTPProbe` → `Ginseng::HTTP#log` が 1 件） |
| `reopen` | Ginseng のクラスを開き直し、アプリのファイルでメソッドを定義している |

- ⚠⚠ **「読めなかった定数」を必ず見る。** 遅延読み込み（Zeitwerk）の定数を 1 つずつ読んでいて、読めなかったものは**一覧に出てこない**。手元に DB が無いと Sequel のモデルは読めない（モロヘイヤでは 24 個）。⚠ 読めなかった分は「未確認」として Issue に書く
- ⚠ `eager_load` を使わないのは、**1 つ落ちるとそこで止まる**から（Sequel のモデルで止まった実測がある）
- ⚠ Zeitwerk を使っていないアプリは、入口の `.rb` で全部 `require` されていれば足りる

## 振り分け

| 形 | すること | 実例（モロヘイヤ） |
| --- | --- | --- |
| **上流に入ったのに写しが残っている** | 消す | `MisskeyService#oauth_server_metadata` |
| **gem の作りのせいで写すしかなかった** | ⚠ **拡張ではなく gem の不具合。** gem へ出す（docs の「ginseng-* の変更手順」の 1）。着地したら写しを消す | `Redis#initialize`（gem が `Service.dsn` と決め打ち） |
| **一般化できる拡張** | 返すか決めて印を付ける（docs の規則の 2） | Redis のロックの道具、JSON の `get` / `set` の写し |
| **アプリ固有** | 理由を書いて印を付ける | `DictionaryHTTP#retryable?`（404 を再送するのは GAS の事情） |
