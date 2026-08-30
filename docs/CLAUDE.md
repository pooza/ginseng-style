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
   - ⚠⚠ **このリポジトリは [workflow.md](workflow.md) の「着手時バンプ」の例外。** ここでは `release.yml` が version からタグを打つので**バンプ＝リリース**であり、**配布物を触る PR ごとに上げる（＝ 1 PR 1 リリース）。マイルストーンは待たない** (#84)
   - ⚠⚠ **待つと `main` が赤くなる。** 配布物を触る PR が 2 本あると、**1 本目をマージした時点で**「`v<version>` があるのに配布物に差分がある」で落ちる（[release-tag](../.github/actions/release-tag/action.yml)）。⚠ 赤を避けてバンプすればそこでタグが出るので、**「埋め切ってから」はどちらへ倒しても成立しない**
   - 🔴 **並行する 2 本は、同じ版へバンプできてしまう（Codex P2）。** どちらも `1.1.10` を見て `1.1.11` へ上げると、**同じ 1 行なので git は衝突と読まない**。1 本目のマージで `v1.1.11` が打たれ、⚠⚠ **2 本目のマージは「配布物を変えたのに `v1.1.11` のまま」で `main` を赤にする**
     - ⚠ **バンプは「上げ忘れ」だけでなく「上げ被り」でも落ちる。** 検査はタグとの差分を見ているので、**版が動いていないこと**しか区別しない
     - **マージの直前に `main` を取り込み、まだタグの無い版へ上げ直す。** ⚠⚠ **配布物を触る PR は直列化する** — 並べて出してよいが、**マージは 1 本ずつ、そのつど版を取り直す**
   - ⚠ **配布物を触らない PR ではバンプしない。** `docs/` は #82 で `spec.files` と `paths` の両方から外したので、**docs だけの変更は版を動かさない**（それでも緑）。⚠ **直列化が要るのも配布物を触る PR だけ**
   - 🔴 **`README.md` は `docs/` ではない (#93)。** `spec.files` にも `release.yml` の `paths` にも入っている**配布物**なので、⚠⚠ **1 行でも触ればバンプが要る**。⚠ 実例: #91 は自分で「docs の PR」と呼んでいたが `README.md` を 1 行含んでおり、**`main` が 1 日赤いままだった**（`CLAUDE.md` は配布物ではないので動かない — 並べて覚えないと取り違える）
   - ⚠⚠ **マージしたら `release` の実行を見る。** バンプ検査は push で回るので、**PR の CI が全部緑でも `main` が赤くなりうる**
3. `main` にマージする。**タグ `v<version>` は [release.yml](../.github/workflows/release.yml) が自動で打つ**。⚠ 手で打たない
4. **利用側 1 リポジトリで試す**。`Gemfile` のタグを新しい版へ上げ、`bundle install && bundle exec rubocop` が緑になることを確認する。⚠ `NewCops: enable` と利用側の `TargetRubyVersion` の組み合わせで、いま緑のものが赤くなりうる
   - ⚠⚠ **手元で緑になっても終わりではない。CI が回るまでが手順** (#63)。手元の Ruby は 1 版だけで、**matrix を持っているのは CI だけ**。`required_ruby_version` を 3.4 へ上げた `v1.1.3` は、手元（4.0.6）では緑のまま **3.3 を残した利用側の CI で落ちた**
5. 問題なければ残りへ配る。1 リポジトリ 1 PR、`rake lint` が緑になったところまで。⚠ **参照 3 経路（`Gemfile` の `ref:` / `test.yml` の `ruby-check@` / `release.yml` の `release-tag@`）を同じタグの SHA に揃える**。⚠⚠ **`--show-cops` と `--list-target-files` の差分がどちらもゼロであることを確認する**（[README](../README.md) の `Include` / `Exclude` の置換）
   - 🔴 **`Include` に足した版を配るときは、`AllCops/Include` を上書きしている利用側を洗い出して同じ分を足す (#95)。** ⚠⚠ **正本に足しただけでは届かない**（置換されるので、その利用側の対象は 1 つも増えない）
   - ⚠⚠ **確認は件数ではなく `--list-target-files` の中身。** 「offense が出なかった」は**対象になっていないとき**も同じ見え方になる — 実例: `makoto2` は「89 files inspected, no offenses」のまま `Gemfile` が検査されておらず、Codex の指摘で気づいた
   - ⚠ **結果は 3 通りに分かれる。** ①そのまま増える ②`Include` を上書きしていて増えない（**足しに行く**）③`Exclude` で意図的に外している（**増えないのが正しい**）
6. 破壊的な変更（既存コードの書き換えを要求するもの）は、配る前に Issue で予告する

⚠ **緩和を足す方向の変更は特に慎重に。** 1 リポジトリの都合を全体に配ることになる。

### ⚠⚠ 固定した以上、配り忘れは自動では直らない

版で固定すると「勝手に赤くなる」は止まるが、代わりに **配り忘れが永久に残る**。⚠ **これは仮定ではない** — `ginseng-core` は最後のタグ `v1.15.26` が **2026-06-10** で、以降 **88 コミット**・`bump version` は 20 回以上あるのにタグがひとつも増えていない。**手で打つ運用は死ぬ。**

- タグは [release.yml](../.github/workflows/release.yml) が打つ（`config/lib.yaml` の `package.version` が正本）。⚠⚠ **手順本体は [release-tag](../.github/actions/release-tag/action.yml) にあり、gem 側 7 本も同じものを `@<SHA>` で呼ぶ**（#65 / #75。⚠ タグは付け替えられるので SHA で固定する）
  - ⚠⚠ **引き金はリポジトリで違う。** このリポジトリは `mode: auto`（push＝出荷）、**gem 側 7 本は `mode: manual`（`workflow_dispatch` を人が押す）**。着手時バンプをするかどうかで決まる（[workflow.md](workflow.md) の「タグを手で打たない」）
  - 🔴 **押し忘れは [gem-watch](../.github/workflows/gem-watch.yml) の `releases` ジョブが週次で一覧に出す**（赤にはしない）
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
- ⚠⚠ **Ruby の版は 3 箇所あり、決め方が違う (#61 / #63)。同じ数字で揃えようとしない。**

| | 意味 | 決め方 |
| --- | --- | --- |
| CI の matrix | どの版でテストするか | 揃えたい版 |
| `TargetRubyVersion` | どの版向けに lint するか | 揃えたい版（⚠ 利用側は上書きできる） |
| 🔴 `required_ruby_version` | **どの版に入るか** | ⚠⚠ **利用側の最低版**。この gem は配る側なので、**利用側の版の和集合**を飲む |

## 規約そのものについて

⚠ **このリポジトリの docs は「自分たちがどう書くか」の記録であって、上流への要求ではない。** RuboCop 本体の挙動が規約と食い違う場合も、上流に不具合として持ち込まない（[ruby.md](ruby.md) の「`return` に多行のチェインを繋がない」参照）。⚠ 自分たちの gem（`ginseng-*`）への起票は別扱いで、そちらは遠慮なく直す。
