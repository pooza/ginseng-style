# ginseng-style プロジェクトルール

## このリポジトリの役割

pooza の Ruby プロジェクト共通の **RuboCop 設定と規約の正本**。加えて、**`ginseng-*` 全体の管理拠点**を兼ねる。

- 規約と設定の正本を持つ（[README.md](../README.md) 参照）。⚠ **なぜ正本化したかは [rationale.md](rationale.md)。** 配る PR の本文から参照する
- `ginseng-*` の横断的な話題（どの gem に入れるか、利用側への配り方、ピン留めの棚卸し）の Issue をここで受ける
- ⚠ **個々の gem の不具合は、その gem のリポジトリに起票する。** ここに集めるのは「横断でないと決められないこと」だけ

## ⚠ 設定を変えるときの手順

`config/rubocop.yml` の変更は inherit している全プロジェクトに波及する。⚠⚠ **利用側は版（タグ）で固定しているので、`main` に入れただけでは誰にも届かない。配るところまでが手順。**

1. このリポジトリで `bundle exec rubocop` を通す
2. **`config/lib.yaml` の `package.version` を上げる。** ⚠⚠ **忘れると `release` ワークフローが赤で教える**（配布物を変えたのに既存タグのまま、という状態を検出する）
3. `main` にマージする。**タグ `v<version>` は [release.yml](../.github/workflows/release.yml) が自動で打つ**。⚠ 手で打たない
4. **利用側 1 リポジトリで試す**。`Gemfile` のタグを新しい版へ上げ、`bundle install && bundle exec rubocop` が緑になることを確認する。⚠ `NewCops: enable` と利用側の `TargetRubyVersion` の組み合わせで、いま緑のものが赤くなりうる
5. 問題なければ残りへ配る。1 リポジトリ 1 PR、`rake lint` が緑になったところまで。⚠ **`Gemfile` の `tag:` と `test.yml` の `ruby-check@` を同じ版に揃える**。⚠⚠ **`--show-cops` と `--list-target-files` の差分がどちらもゼロであることを確認する**（[README](../README.md) の `Include` / `Exclude` の置換）
6. 破壊的な変更（既存コードの書き換えを要求するもの）は、配る前に Issue で予告する

⚠ **緩和を足す方向の変更は特に慎重に。** 1 リポジトリの都合を全体に配ることになる。

### ⚠⚠ 固定した以上、配り忘れは自動では直らない

版で固定すると「勝手に赤くなる」は止まるが、代わりに **配り忘れが永久に残る**。⚠ **これは仮定ではない** — `ginseng-core` は最後のタグ `v1.15.26` が **2026-06-10** で、以降 **88 コミット**・`bump version` は 20 回以上あるのにタグがひとつも増えていない。**手で打つ運用は死ぬ。**

- このリポジトリのタグは [release.yml](../.github/workflows/release.yml) が自動で打つ（`config/lib.yaml` が正本）
- 古い版で止まっている利用側は、[gem-watch](../.github/workflows/gem-watch.yml) の `pins` ジョブが週次で出す
- ⚠ **未固定（`@main` / `branch: 'main'`）は落とす。古いだけなら落とさない** — 配っている最中は必ず古い期間があり、そこで赤くすると「赤は無視するもの」になる

## ⚠ ginseng-* の利用者

`Gemfile` / `*.gemspec` で `ginseng` を参照しているリポジトリが対象。gem 側（`ginseng-fediverse` / `ginseng-web` / `ginseng-redis` / `ginseng-postgres` / `ginseng-piefed` / `ginseng-youtube`）とアプリ側（`mulukhiya-toot-proxy` / `makoto2` / `cure-api` / `tomato-shrieker` / `loquat` / `shooby-do-bop` / `dqdai-anniv` / `chubo-core`）、および **private リポジトリ数本**がある。

⚠ **このリポジトリは public。** private リポジトリと他 org のリポジトリの名前は書かない。⚠⚠ **全リストはセッションメモリ側が正本**（`ginseng-*` 管理セッションの `project_ginseng-consumers`）。

⚠ **`capsicum-relay` は `.rubocop.yml` を持つが ginseng に依存していない。** 配布対象に含めるかは別途判断する。

### ⚠⚠ ピン留めのばらけ（2026-08-19 時点の実測）

`Gemfile.lock` は git 参照のリビジョンを固定するので、**リポジトリごとに違う版が刺さったまま進む**。`ginseng-core` の HEAD が 2026-08-18 の時点で、刺さっている版は **8 種類**、最古は **2026-04-14（4 ヶ月前）** だった。

| 版 | 日付 | 備考 |
| --- | --- | --- |
| `ab02f5e36e` | 2026-08-16 | 最新に近い（2 リポジトリ） |
| `d1878f777f` | 2026-08-13 | 2 リポジトリ |
| `de82ea13eb` | 2026-08-06 | 1 リポジトリ |
| `edaa47a69e` | 2026-08-02 | 1 リポジトリ |
| `4b134cebaf` | 2026-07-30 | **5 リポジトリ**（最多） |
| `0a3a69c93c` | 2026-07-09 | 2 リポジトリ |
| `e510866901` | 2026-04-14 | 🔴 1 リポジトリ（4 ヶ月前） |

⚠ 内訳（どのリポジトリがどの版か）はセッションメモリ側にある。

⚠ **security 修正が一部にしか届いていない状態になりやすい。** 実例: [pooza/makoto2#101](https://github.com/pooza/makoto2/issues/101)（`Gemfile.lock` が 1.15.28 で止まり security 修正 6 件を取り込めていない）。棚卸しのワンライナーは [workflow.md](workflow.md) の「ピン留めのばらけを放置しない」にある。

## このリポジトリ自身の作り

- 設定と docs を配るだけの gem。**ライブラリとしての実装は持たない**
- ⚠⚠ **`ginseng-core` に依存させないこと。** ginseng-core 側もこの gem の規約に従う側なので、依存させると循環する
- rubocop 本体とプラグインをこの gem の `add_dependency` に持つ。利用側の Gemfile から rubocop 系を消せるようにするのが目的
- バージョンの正本は [config/lib.yaml](../config/lib.yaml) の `package.version`

## 規約そのものについて

⚠ **このリポジトリの docs は「自分たちがどう書くか」の記録であって、上流への要求ではない。** RuboCop 本体の挙動が規約と食い違う場合も、上流に不具合として持ち込まない（[ruby.md](ruby.md) の「`return` に多行のチェインを繋がない」参照）。⚠ 自分たちの gem（`ginseng-*`）への起票は別扱いで、そちらは遠慮なく直す。
