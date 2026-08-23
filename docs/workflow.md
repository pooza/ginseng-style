# 開発の進め方

プロジェクト横断の運用規約。⚠ **リリース手順やデプロイのようにプロジェクト固有のものは、各リポジトリの `docs/CLAUDE.md` に置く。** ここには共通の骨格だけを書く。

## Issue 駆動

- 課題・タスクは GitHub Issue で管理する。docs に書くだけでは管理されていない扱い。⚠ **利用側から PR だけが届いた場合は、受け取った側が Issue を起こす**（下記「着手順」）
- 「相談」の着地点は Issue 起票。議論の結論が Issue に残っていない状態で閉じない
- ⚠ **元の要件を先送りするときは、受け皿の後続 Issue を起票するまでクローズしない**
- インフラ面の課題は `pooza/chubo2` の Issue として起票する

## ⚠⚠ 着手順 — ライブラリ側は「依頼」を最優先にする

`ginseng-*` はライブラリなので、**着手順は緊急性・即効性だけでは決まらない。**

1. ⚠⚠ **利用側プロジェクトからの依頼が最優先。** 相手側の緊急性に配慮する。⚠ **こちらの都合で後回しにしない**
2. **ginseng 自身の品質向上（リファクタ・CI・テスト・規約）は、依頼の合間に進める**
3. 依頼が無い期間に品質向上を進め、依頼が来たら**そちらへ寄せる**

⚠ **依頼は `request` ラベルで識別する。** 起票・受け取りの時点で付ける。ラベル集合は `ginseng-*` 全リポジトリで揃えてある。

### ⚠ 依頼は Issue より PR で受けたい

**PR で来たほうが進行が早い。** 利用側は再現の文脈を持っているので、そこで書いたほうが往復が減る。

- ⚠ **アプリ側が gem の修正を自分のリポジトリで回避しない**（下記「`ginseng-*` の変更手順」）という分界は変わらない。**避けるのは回避策で、PR を出すことは歓迎する**
- ⚠⚠ **PR だけで送ってよい。Issue 駆動は崩さないが、依頼元に二度手間をさせない** — **PR で来たら、受け取った gem 側が Issue を起こして紐づける**。サイズ・マイルストーン・重み予算は Issue に載るので、**管理の単位は Issue のまま**
- PR を出せない場合は Issue で。⚠ **再現手順と、どのアプリのどの経路で踏んだか**を書く
- ⚠ gem 側が実装まで引き受けるかは、**依頼元が実装の主体を持てるかで決める**。持てるなら PR を待ち、こちらはレビューと配布に回る
- ⚠⚠ **待つと決めたら `waiting:pr` を付ける。** マイルストーンに載っているだけだと、**次のセッションが着手して同じものを 2 回作る**。⚠ マイルストーンからは外さない（PR が来れば入る）が、**来なければ待たずにその版を締める**

## ブランチ

⚠ **gem 側とアプリ側で違う。** 2026-08-22 の実測に合わせている。

- **gem 側（`ginseng-*`）は `main` だけ持つ。** feature ブランチを切って `main` へ直接 PR を出す。⚠ **`develop` は作らない**
- **アプリ側は `main`（リリース）と `develop`（開発）を持つ**
- 作業は feature ブランチを切る。命名は `fix/<issue>-<slug>` / `feat/<issue>-<slug>` / `docs/<issue>-<slug>`
- ⚠ `gh pr create` は `--base` を必ず明示する。省略すると default branch が宛先になり、**フォークでは upstream に向く**
- ⚠⚠ **`develop` を現行と決めてかからない。** 死んだ `develop` の CI 定義を現行と誤読して、composite action に不要な入力を足した実例がある（[pooza/ginseng-core#521](https://github.com/pooza/ginseng-core/pull/521) へ誤爆 → #5 → #7 で取り消し）
- ⚠ **`behind` の数では見ない。** 現役の `develop` も `main` より数コミット遅れる。実測（2026-08-22）では、生きているアプリ側 4 本はいずれも **behind 1〜3 かつ ahead 4〜57** だった
- ⚠⚠ **`ahead 0` だけでも死亡と判定しない。** リリース直後など、固有コミットを `main` に入れ切った現役の `develop` は一時的に ahead 0 になる。**最終コミット日時と、直近の PR がどこ宛に出ているか**まで見る
- 🔴 死んでいる例（`ginseng-core` の `develop`）: ahead 2 / behind 112、固有 2 件はどちらも `main` へ到達済み、最終コミットは 2026-08-19 で以降 `main` に 112 件入っていた。**ahead だけ見ても、最終更新だけ見ても足りない**

## マイルストーン

⚠ **スコープが確定したゴールは、GitHub マイルストーンを作って Issue を割り当てる。** docs に書いただけでは未確定扱い。省略しない。

- 新しいマイルストーンに着手したら、まずバージョンをバンプする（開発中のバージョンを常に識別できる状態に保つ。⚠ **動いているコードがどの版か分からないと、デプロイと検証で事故る**）
  - ⚠⚠ **バンプは「開発中の版の識別」であって、リリースの合図ではない。** 出荷を確定させるのは**タグ**（下記「タグは『マイルストーンを埋め切ってから』打つ」）
  - ⚠⚠ **例外: version からタグを自動で打つリポジトリでは、着手時にバンプしない。** そこでは**バンプ＝リリース**になる（`ginseng-style` 自身がそう。[release.yml](../.github/workflows/release.yml) が `config/lib.yaml` を正本にタグを打つ）
- マイルストーンの無い軽い課題は近接処理でよい。大きな設計案件は別扱い

### サイズラベル

| ラベル | 想定差分 | 重み |
| --- | --- | --- |
| `size:S` | 50 行未満 / 単発バリデーション・小バグ修正・docs 修正 | 1 |
| `size:M` | 50〜200 行 / 新メソッド・リファクタ単位・契約変更 | 3 |
| `size:L` | 200 行超 / 新エンドポイント・スキーマ変更・複数ファイル横断 | 8 |

新規 Issue 起票時にいずれかを付ける。既存 Issue にも遡及付与する。

### 重み予算

- 1 マイルストーンの目安は **20〜25 重み**
- 超えそうな Issue は次のマイナーバージョンへ送る
- 計画書は作らない。Issue ＋ マイルストーン ＋ 重み合計で管理する
- ⚠ **`request` と `security` を先の版へ寄せ、自身の品質向上を次の版へ送る。** 予算を切る向きはこの順

### ⚠ 共通のラベル集合

`ginseng-*` の全リポジトリで揃える。⚠ **貼れないリポジトリがあると、規約が要求している運用が成立しない。**

| ラベル | 意味 |
| --- | --- |
| `request` | ⚠⚠ **利用側プロジェクトからの依頼。最優先** |
| `waiting:pr` | ⚠ **依頼元の PR 待ち。こちらから着手しない** |
| `size:S` / `size:M` / `size:L` | 上記の重み |
| `security` | セキュリティに関わるもの |
| `breaking` | ⚠ 破壊的変更。利用側の書き換えが要る |
| `dependencies` | 依存の更新 |
| `bug` / `enhancement` / `documentation` / `refactor` | 種別 |

## リリース前レビュー

マイルストーンの Issue を消化し終え、**タグを打つ前**に実施する。⚠ バンプは着手時に済んでいるはず（上記「マイルストーン」）。済んでいなければここで済ませる。**単一のセキュリティレビューだけでは実用上の問題が取りこぼされる**ため、複数の観点を独立に走らせて指摘を合流させる。

観点はプロジェクトの性質で決めるが、最低限この 3 つは共通で置く。

| 観点 | 焦点 |
| --- | --- |
| セキュリティ | 認証・トークンの取り扱い・シークレットの scrub・入力検証 |
| エラー処理・観測性 | 例外の分類、ログの個人情報漏洩、ヘルスチェックの判定 |
| コーディングスタイル・規約整合性 | RuboCop、本ドキュメントの規約、廃止語 |

指摘は次の基準で分類し、**必要最小限のみ本リリースで対応**、残りは Issue 起票して次リリース以降へ送る。

- **赤（必修）**: データ破損・セキュリティ・ユーザー可視の機能不全
- **黄（余力があれば）**: 単一の edge case、観測性ギャップ
- **緑（送り）**: 将来の拡張時に顕在化しうる構造改善

⚠ **真の赤でも、機能が全環境で OFF ならライブ露出ゼロとして非ブロック化し、受け皿 Issue へ繰り越してよい。**

### ⚠⚠ タグは「マイルストーンを埋め切ってから」打つ

**版を先に打つと、マイルストーン名と実際に出荷された中身がずれる。** ⚠ 実例: `ginseng-fediverse` は緊急修正の PR が `1.8.29` へのバンプを含んでいたためそこで `v1.8.29` が打たれ、⚠⚠ **マイルストーン `1.8.29` は中身（2 件）を出荷しないまま open で残った**。次のリリースでその 2 件を `1.8.30` へ寄せて畳むまで、**どの版に何が入ったのかが追えない状態**だった。

- **順序は「Issue を消化 → リリース前レビュー → タグ」。** ⚠ バンプは着手時に済ませてある（上記「マイルストーン」）
- ⚠⚠ **バンプを出荷の合図と読まない。** 上の事故も、正確には「バンプが早かった」のではなく、**緊急修正 PR に混ざったバンプを見てタグを打った**こと。⚠ 個別の修正 PR にバンプを混ぜなければ、この誤読は起きにくい
- ⚠ **急ぎの利用側は `branch: 'main'` 参照や `bundle update` で取り込めるので、タグは待たせない理由にならない。** 「早く使わせたいから先に打つ」は不要
- ⚠ **タグの形を揃える。** annotated と lightweight が混在すると、`git describe` や一覧の見え方が版によって変わる

## ⚠ lint とテストを迂回しない

「環境が壊れている」を理由に lint / test を飛ばさない。`bundle install` 等で環境を作ってから必ず実行する。簡単な環境構築は確認を取らずに進めてよい。

⚠⚠ **CI も同じ。** 2026-08-19 まで `ginseng-*` 全 7 gem の CI は `rake test` を呼んでおらず、**計 366 件のテストが一度も走っていなかった**。ワークフロー名が `test` でも中身が lint だけなら、緑は「lint が通った」以上の意味を持たない（経緯は [rationale.md](rationale.md)）。

## CI

`ginseng-*` の CI は、手順本体を [.github/actions/ruby-check](../.github/actions/ruby-check/action.yml)（composite action）に置き、各 gem の `.github/workflows/test.yml` から呼ぶ。

```yaml
on:
  push:
  schedule:
    - cron: '25 0 * * 1'
  workflow_dispatch:

permissions:
  contents: read

steps:
  - uses: actions/checkout@v5
    with:
      persist-credentials: false
  # ⚠⚠ @main ではなく版で固定する。理由は下の「参照は必ず版で固定する」。
  - uses: pooza/ginseng-style/.github/actions/ruby-check@v1.1.0
```

⚠ **`matrix` / `services` / `schedule` は呼び出し側に残す。** Ruby の対応版・必要なミドルウェアは gem ごとに違う。共通化するのは手順だけ。

### ⚠⚠ 参照は必ず版で固定する

`ginseng-style` は利用側から **2 経路**で参照される。⚠⚠ **どちらも `@main` / `branch: 'main'` にしないこと。**

| 経路 | 何が入ってくるか | 書き方 |
| --- | --- | --- |
| `.github/workflows/test.yml` | CI の手順本体（composite action） | `pooza/ginseng-style/.github/actions/ruby-check@v1.1.0` |
| `Gemfile` | RuboCop の設定と rubocop 本体・プラグイン | `gem 'ginseng-style', github: 'pooza/ginseng-style', tag: 'v1.1.0', require: false` |

**固定しないと、利用側が 1 行もコミットしていないのに次の push で CI が赤くなる。** `config/rubocop.yml` に cop を足した瞬間、`NewCops: enable` があるので rubocop 本体の更新でも同じことが起きる。⚠ 「1 リポジトリで試してから配る」という下記の手順は、**配る前に全リポジトリへ届いてしまう**ので前提から崩れていた。

⚠⚠ **`Gemfile.lock` は固定の代わりにならない。** gem 側は `Gemfile.lock` を `.gitignore` していて、**CI のチェックアウトには lock がそもそも存在しない**。`bundle install` は毎回 `main` の HEAD を解決する。実測（2026-08-23、`ginseng-style` の main = `956e0a68e7`）:

| | 刺さっていた版 | main から |
| --- | --- | --- |
| gem 側 7 本の**手元** | `9422f76dba` ほか（2026-08-19） | 45〜48 遅れ |
| gem 側 7 本の **CI** | `main` | 0 |

🔴 **手元と CI が 48 コミット違う状態で「緑」と言っていた。** 実害の例: `ginseng-core` の手元だけ `Minitest/AssertPathExists` が出て、CI は同じコミットで緑だった（[#53](https://github.com/pooza/ginseng-style/issues/53)）。

### ⚠⚠ 呼び出し側で権限を絞る

手順本体は他リポジトリの composite action なので、**`ginseng-style` に入った変更が、各リポジトリの `GITHUB_TOKEN` を持って動く。** 止まるだけでなく任意のコードが走る側面がある。⚠⚠ **版で固定してもこの性質は消えない**（固定は「いつ変わるか」を選べるようにするだけで、「何が動くか」は変わらない）。権限を絞るのは固定とは別に必ずやる。

- **`permissions: contents: read` を workflow に必ず置く。** ⚠ リポジトリ既定に頼らない
- **`actions/checkout` に `persist-credentials: false` を置く。** ⚠ 既定では認証情報がワークツリーの `git config` に残り、後続のステップから使える。依存 gem は public な `github:` 参照なので、消しても `bundle install` に影響しない
- ⚠⚠ **リポジトリ設定側の既定も `read` に落とす。** Settings → Actions → General → Workflow permissions。ファイルの `permissions:` は**その workflow にしか効かない**ので、両方要る

⚠ 2026-08-22 実測で、**8 リポジトリ中 6 つが既定 `write`**（`can_approve_pull_request_reviews` も `true`）で、**7 gem のどれにも `permissions:` と `persist-credentials:` が無かった**。

### ⚠⚠ 週次 schedule は勝手に止まる

> In a public repository, scheduled workflows are automatically disabled when no repository activity has occurred in 60 days.
> — [GitHub Docs](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows)

⚠⚠ **`schedule:` の実行そのものは活動に数えられない。** 更新が止まった gem ほど止まりやすく、**いちばん必要な場面で監視が消える。**

⚠ **「repository activity」の定義は文書化されていない。** したがって空コミット等の keepalive で延命する案は採らない。**定義が変われば黙って壊れる。**

代わりに、[gem-watch](../.github/workflows/gem-watch.yml) で 2 つに分けて解く。

1. **無効化の検知** — 各リポジトリの `GET /repos/{owner}/{repo}/actions/workflows` を見て、`state` が `active` でなければ job を落とす。⚠ `disabled_inactivity` は API の定義済みの値なので、「活動」の定義に依存しない
2. **実行の担保** — 各 gem の `schedule:` に頼らず、`workflow_dispatch` で毎週起こす

⚠⚠ **`gem-watch` 自身が 60 日で止まる可能性は残る。** `ginseng-style` は管理拠点で活動が続く前提に乗っている。**完全に塞ぐには外部の cron から `gem-watch` の最終実行を見るしかない**ので、そこはリスクとして受け入れている。

⚠ 動かすには `GEM_WATCH_TOKEN`（fine-grained PAT・対象 8 リポジトリ・Actions: Read and write / Metadata: Read）を `ginseng-style` の secret に置く。`GITHUB_TOKEN` は他リポジトリを起動できない。

- **週次の `schedule:` を必ず置く。** ⚠ push 契機だけだと、更新が止まった gem は永遠に緑のまま赤に気づけない。実例: `ginseng-postgres` の CI は 4 ヶ月赤のまま誰も気づかなかった
- ⚠ **`schedule:` はデフォルトブランチでしか動かない。** feature ブランチに置いても発火しない
- **`workflow_dispatch:` も必ず置く。** ⚠ 下記のとおり `schedule:` は勝手に止まるので、外から起こせる口が要る
- ⚠ ginseng-style を壊すと全 gem の CI が同時に止まる。この gem の CI が緑であることを先に確認してから配る

## ginseng-* の変更手順

⚠ **`ginseng-*` は複数のプロジェクトが同時に使う。** アプリ側の都合で gem を直すと、他の利用者に黙って影響が出る。

1. アプリ側で「gem を直せば済む」と分かったら、**該当 gem のリポジトリへ、次のどちらか一方**を出す。⚠ **両方は要らない**
    - **直せるなら PR**（⚠ こちらが望ましい。**受け取った gem 側が Issue を起こして紐づける**。上記「着手順」参照）
    - **直せないなら Issue**（再現手順と、どのアプリのどの経路で踏んだかを書く）

    ⚠ いずれにせよ**アプリ側リポジトリで回避策を持たない**
2. gem を直したら、**利用しているリポジトリを横断で確認する**。誰が使っているかは `Gemfile` / `*.gemspec` の `ginseng` 参照で分かる
3. アプリ側は `bundle update <gem>` で取り込み、`Gemfile.lock` の更新をコミットする。⚠ **ルーチンの `Gemfile.lock` 最新化は PR 不要・`develop` 直コミットでよい**
4. ⚠ **アプリ側の修正だけで直ったと判断しない。** gem が値を捨てていて届かないことがある。`gem 修正` → `bundle update` → `アプリ側 PR` を同じサイクルで回す
5. ⚠⚠ **逆も同じ。gem を直しただけで「届いた」と判断しない。** 下記

### ⚠⚠ 利用側が同じ場所を上書き・回避していると、gem を直しても届かない

**修正した当のメソッドを利用側が上書きしていれば、修正は 1 行も効かない。** ⚠ これは想像ではなく、**1 回のリリースで 2 件**見つかった実例（`ginseng-fediverse` 1.8.30）。

| 形 | 実例 |
| --- | --- |
| **入口ごと上書きしている** | `TagContainer.self.scan` に入れた検査を、利用側が同名のクラスメソッドを上書きして丸ごと迂回していた（[pooza/mulukhiya-toot-proxy#4642](https://github.com/pooza/mulukhiya-toot-proxy/issues/4642)）。⚠ **タグ抽出の主経路がそれ** |
| **手前で回避策を掛けている** | gem に渡す前に `force_encoding(UTF_8).scrub` していたので、gem 側の検査に**壊れていない値しか届かない**（[pooza/makoto2#171](https://github.com/pooza/makoto2/issues/171)）。⚠⚠ **その回避策自体が、gem 側で「採らない」と決めた形だった** |

⚠ **どちらも「利用側が悪い」話ではない。** 上書きも回避策も、**当時の gem の作りがそれを強いていた**（前者は基底が `TagContainer.new` と決め打ちしていたので、サブクラスは上書きするしかなかった）。**直した側が、それが不要になったことを伝える。**

**How to apply:**

1. 直したメソッド名で**利用側を横断 grep する**。`def <名前>` と、それを呼ぶ手前の加工の両方を見る
2. 上書き・回避策が見つかったら、⚠ **「もう要らない」ことまで書いて起票する**。⚠⚠ **消し方まで書かないと残り続ける**
3. ⚠ **こちらではマージしない**（[docs/CLAUDE.md](CLAUDE.md) の分界）

### ⚠ ピン留めのばらけを放置しない

`Gemfile.lock` は git 参照のリビジョンを固定するので、**リポジトリごとに違う版が刺さったまま何ヶ月も進む**。security 修正が一部にしか届いていない状態になりやすい。定期的に横断で棚卸しする。

⚠ **`ginseng-style` は別扱い**（上記「参照は必ず版で固定する」）。刺さっている版は `Gemfile` の `tag:` に書いてあり、古いものは週次の [gem-watch](../.github/workflows/gem-watch.yml) が出す。⚠⚠ **`ginseng-core` などライブラリ本体は、いまも `Gemfile.lock` 頼りのまま**なので、下の棚卸しが要る。

```sh
for d in ~/repos/*/; do
  printf '%-24s ' "$(basename "$d")"
  awk '/remote: https:\/\/github.com\/pooza\/ginseng-core/{f=1} f&&/revision:/{print substr($2,1,10); exit}' \
    "$d/Gemfile.lock" 2>/dev/null || echo -
done
```

## Codex のレビューを取り残さない

PR には Codex（`chatgpt-codex-connector[bot]`）のレビューが遅れて届く。**返信と 👍 / 👎 の両方を付けて完了**とする。⚠ **両方が揃っていないもの ＝ 未処理**、という判定に使えるようにするため。

- ⚠⚠ **却下する指摘にも 👎 を付ける。** 何も付けずに残すと、**次のセッションが同じ検証をやり直す**
- 直せるものは修正 PR、直さない／後回しにするものは Issue を立ててから返信する
- ⚠⚠ **窓を件数で切らない。** Codex はマージ後に届くので、PR の流量が多い時期ほど新しい PR に押し出される。実例: モロヘイヤで **P1 が 2 件、4 日放置**された（「SSRF を塞いだ」という認識のまま、実際には塞げていなかった）
- ⚠⚠ **PR を出したセッションは、締める直前にもう一度走査する。** 走査したあとに着いたコメントがそのまま落ちる。「さっき棚卸しした」は理由にならない

**PR を列挙して回さない。** リポジトリ全体のレビューコメントを `--paginate` で取る。

```sh
repo=<owner>/<repo>
# ⚠⚠ gh を単独で走らせ、終了ステータスを見てから jq に渡す。パイプで繋ぐと
#   パイプ全体の状態が jq のものになり、ページングの途中で失敗しても
#   「出し終えた分だけ」を全履歴として走査してしまう ＝ 偽のゼロ。
gh api --paginate "repos/$repo/pulls/comments?per_page=100" > /tmp/codex-raw.json \
  || { echo '走査に失敗した。結果を信用しないこと' >&2; exit 1; }
jq -s add /tmp/codex-raw.json > /tmp/codex.json
jq -r '. as $all | $all[] | . as $c
  | select(.user.login == "chatgpt-codex-connector[bot]")
  | select(([$all[] | select(.in_reply_to_id == $c.id)] | length) == 0
           or ((.reactions["+1"] // 0) + (.reactions["-1"] // 0)) == 0)
  | "PR#\(.pull_request_url | split("/") | last) \(.id) \(.path)"' /tmp/codex.json
```

- ⚠⚠ **`gh pr list --limit N` で回す形にしない。** N 本より古い PR に遅れて届いたレビューへ永遠に到達しない ＝ **この節が防ごうとしている失敗そのもの**
- ⚠ **`gh api` は `--paginate` を付けないと 1 ページ目しか見ない**
- ⚠⚠ **`gh api ... | jq` と繋がない。** 失敗したページングを握り潰し、**部分的な結果を「全部見た」として扱う**
- ⚠⚠ **`reactions.total_count` を完了判定に使わない。** 👀 や ❤️ が 1 つ付いただけで非ゼロになり、**未処理のものが走査から消える**。**返信の有無**と **👍 / 👎 の数**を別々に見る

⚠ **`pulls/comments` は行に紐づくレビューコメントしか返さない。** PR 本体のコメントは `repos/$repo/issues/comments` で同じように取る。**他リポジトリを触っている別セッションからの申し送りはこちらに来る**（投稿者は bot ではなく人）。⚠ **open PR も対象に含める**（上の API はどちらも含む）。

🔴 **2026-08-20 に壊れた走査で「取り残しゼロ」と報告し、取り直したら `ginseng-*` 8 リポジトリで未処理 21 件（最古 2026-02-10）が出た。** 走査そのものを疑うこと。

## 表記

ドキュメントとコミットメッセージの表記規約は [writing.md](writing.md) にある。
