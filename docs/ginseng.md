# ginseng-*（Ruby）の運用

[workflow.md](workflow.md) の共通の運用のうち、**`ginseng-*` と Ruby に固有のもの**をここに置く（#145）。⚠ Node.js / PHP の共有設定（[gobou](https://github.com/pooza/gobou)）の運用は gobou の README と CLAUDE.md にある（#142）。

## タグの打ち方

### ⚠⚠ タグを手で打たない — 引き金はリポジトリで違う

🔴 **手で打つ運用は死ぬ。** ⚠ これは仮定ではない — 2026-08-27 の実測で、**4 gem に計 8 版ぶんの出荷が滞留**していた（`ginseng-core` は version 1.22.0 に対しタグが `v1.20.0` で **security 修正 2 件が未出荷**、`ginseng-web` は 3 版、`ginseng-redis` は 2 版、`ginseng-piefed` はタグが 1 本も無し）。

手順本体は [.github/actions/release-tag](../.github/actions/release-tag/action.yml)（composite action）に置き、各リポジトリの `.github/workflows/release.yml` から呼ぶ（下記「CI」の `ruby-check` と同じ形）。**タグの正本は `config/lib.yaml` の `package.version`**（8 本すべてこの形。gemspec の `spec.version` もここを読む）。

⚠⚠ **引き金は 2 通りある。揃えようとしないこと。** 着手時バンプをするかどうかで決まる。

| | `mode` | タグを打つ引き金 | 着手時バンプ |
| --- | --- | --- | --- |
| `ginseng-style` | `auto` | **`main` への push**（バンプ＝リリース） | しない |
| gem 側 7 本 | `manual` | 🔴 **`workflow_dispatch`**（人が押す） | する |

- ⚠⚠ **gem 側で push を引き金にしてはいけない。** 着手時バンプをする以上、`main` には「まだタグの無い version」が載っているのが正常で、そこで打つと**マイルストーンの 1 本目の PR が載った時点で出荷される**（＝ [workflow.md](workflow.md) の「タグは『マイルストーンを埋め切ってから』打つ」の `v1.8.29` の事故と同じ形）
- **押すのは「Issue を消化 → リリース前レビュー」の後。** ⚠ `gh workflow run release.yml -R pooza/<gem>` でよい
- ⚠ **どちらの mode でも、push のたびに「配布物を変えたのに `v<version>` のまま」を検査する。** 引っ掛かったら version を上げる（＝着手時バンプのし忘れ）
  - ⚠⚠ **比較の基点はタグそのもの**であって、その push の前ではない。`github.event.before` を基点にすると **1 push 分しか見ない**ので、配布物を変えた push と version を上げないまま重ねた push が分かれていると素通りする
  - ⚠⚠ **「配布物」は 2 系統ある。片方だけ見ると漏れる。** gem として配るもの（`ginseng-core` なら `bin/` `cert/` `config/` `images/` `lib/` `views/`）と、**タグ経由で参照されるもの**（`.github/actions/*`）
  - ⚠⚠ **だから `paths` に既定は置いていない。** リポジトリごとに中身が違うので、それらしい既定は**静かに取りこぼす**（＝この検査が一番効いてほしい場面で黙る）。列挙は [README](../README.md) の「`paths` に既定は無い」の表
- 🔴 **押し忘れは自動では直らない。** [gem-watch](../.github/workflows/gem-watch.yml) の `releases` ジョブが、version と最新タグのずれを**週次で一覧に出す**。⚠ 赤にはしない（着手時バンプをする以上ずれる期間は必ずあり、そこで赤くすると「赤は無視するもの」になる）

⚠ **gobou は例外で、タグを手で打つ**（2026-11-07 オーナー判断。規約の入れ物で gem の実装を持たないので、自動で打つ仕組みは作らない）。打ち忘れは [sync スキル](../.claude/skills/sync/SKILL.md) の「出荷」が 🟡 で出す（#143）。

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
  # ⚠⚠ @main でもタグでもなく SHA で固定する。理由は下の「参照は必ず SHA で固定する」。
  - uses: pooza/ginseng-style/.github/actions/ruby-check@7196764dca7628c3fd1226bcc08415f8bda2fd31 # v1.1.7
```

⚠ **`matrix` / `services` / `schedule` は呼び出し側に残す。** Ruby の対応版・必要なミドルウェアは gem ごとに違う。共通化するのは手順だけ。

### ⚠⚠ 参照は必ず SHA で固定する

`ginseng-style` は利用側から **3 経路**で参照される。⚠⚠ **どれも `@main` / `branch: 'main'` にしないこと。**

| 経路 | 何が入ってくるか | 書き方 |
| --- | --- | --- |
| `.github/workflows/test.yml` | CI の手順本体（composite action） | `...actions/ruby-check@7196764dca7628c3fd1226bcc08415f8bda2fd31 # v1.1.7` |
| `.github/workflows/release.yml` | タグを打つ手順（composite action。#65） | `...actions/release-tag@7196764dca7628c3fd1226bcc08415f8bda2fd31 # v1.1.7` |
| `Gemfile` | RuboCop の設定と rubocop 本体・プラグイン | `ref: '7196764dca7628c3fd1226bcc08415f8bda2fd31' # v1.1.7` |

🔴 **タグではなく SHA（#75）。** タグは付け替えられるので、`vX.Y.Z` は固定になっていない。⚠⚠ **`release-tag` は利用側の `contents: write` トークンを受け取る**ので、`ginseng-style` を取られた側が利用側の ref を作り替えられる。

- **末尾に `# vX.Y.Z` をコメントで添える。** ⚠ 人間が読むためのもので、**検査には使わない**
- ⚠⚠ **`gem-watch` の `pins` は SHA からタグを引いて突き合わせる。** コメントを信用すると、⚠ **規約に頼る ＝ ずれても気づけない**
- 🔴 **タグの無い SHA を刺していたら赤。** レビューを通っていないコミットを刺しているということ
- 🔴 **`vX.Y.Z`（タグ）での参照は赤。** 2026-08-27 に 8/8 が SHA へ移り終えた（#75）。⚠ 移行の最中だけ warning に留めていた

**固定しないと、利用側が 1 行もコミットしていないのに次の push で CI が赤くなる。** `config/rubocop.yml` に cop を足した瞬間、`NewCops: enable` があるので rubocop 本体の更新でも同じことが起きる。⚠ 「1 リポジトリで試してから配る」という手順（[docs/CLAUDE.md](CLAUDE.md) の「設定を変えるときの手順」）は、**配る前に全リポジトリへ届いてしまう**ので前提から崩れていた。

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

⚠ 動かすには `GEM_WATCH_DISPATCH_TOKEN`（fine-grained PAT・`pooza` 名義・対象 8 リポジトリ・Actions: Read and write / Contents: Read）を `ginseng-style` の secret に置く。`GITHUB_TOKEN` は他リポジトリを起動できない。

`consumers` ジョブ（アプリ側の `ginseng-*` 参照。#103）は、さらに次の 2 つを secret に置く。

| secret | 中身 |
| --- | --- |
| `GEM_WATCH_CONSUMERS` | 見張る利用側の `owner/repo` を空白区切りで。⚠⚠ **全リストはセッションメモリ側が正本** |
| `GEM_WATCH_READ_TOKEN` | `GEM_WATCH_DISPATCH_TOKEN` で読めない利用側を読むトークン（**Contents: Read のみ**）。⚠ fine-grained PAT は resource owner を 1 つしか持てないので、**他 org の private はこちら**。無ければ省略してよい（読めない利用側は error になる） |

- ⚠⚠ **トークンの名前は org ではなく「任せている仕事」で付ける。** 🔴 **`dispatch` のほうにだけ `Actions: Read and write` が要るのは、各 gem の `test.yml` を起こすから** — `read` のほうは `Gemfile` を読むだけで何も起動しない。⚠ **org の差ではなく仕事の差**なので、揃えると**使わない書き込み権限を public リポジトリの secret に置く**ことになる
  - 🔴 **名前を揃えなかった理由を書かないと「片方が設定を間違えている」と読まれる**（2026-09-13 に実際そう読まれた）

- 🔴🔴 **一覧は `vars` ではなく `secrets` に置く。** private と他 org の名前はこの public なリポジトリに書けないが、⚠⚠ **step の `env:` はログにそのまま出る** — `vars` は平文、`secrets` だけが `***` になる（2026-09-07 の実行ログで確認）
- 🔴 **ログとサマリにも名前を出さない。** 実名で出すのは **`pooza` の public リポジトリだけ**で、それ以外は `GEM_WATCH_CONSUMERS` の順番（伏せ字 #N）で示す。⚠ **`private` だけで判定しないこと** — 他 org にも public のリポジトリがあり、実名が出た（2026-09-11）
- ⚠ **見るブランチは「既定より進んでいる `develop`」、無ければ既定。** 「`develop` があればそちら」は誤り（置き去りの `develop` がある）
- ⚠ **未固定は warning で、error にしない**（#103）。`tomato-shrieker` / `loquat` / `shooby-do-bop` / `dqdai-anniv` は固定しないと決めた（2026-09-17）ので、warning からも外して一覧に `➖ 固定しない` と出す。追随は `tomato-shrieker` の同期手順のピン棚卸しで見る

- **週次の `schedule:` を必ず置く。** ⚠ push 契機だけだと、更新が止まった gem は永遠に緑のまま赤に気づけない。実例: `ginseng-postgres` の CI は 4 ヶ月赤のまま誰も気づかなかった
- ⚠ **`schedule:` はデフォルトブランチでしか動かない。** feature ブランチに置いても発火しない
- **`workflow_dispatch:` も必ず置く。** ⚠ 上記「週次 schedule は勝手に止まる」のとおり `schedule:` は止まるので、外から起こせる口が要る
- ⚠ ginseng-style を壊すと全 gem の CI が同時に止まる。この gem の CI が緑であることを先に確認してから配る

## ginseng-* の変更手順

⚠ **`ginseng-*` は複数のプロジェクトが同時に使う。** アプリ側の都合で gem を直すと、他の利用者に黙って影響が出る。

1. アプリ側で「gem を直せば済む」と分かったら、**該当 gem のリポジトリへ、次のどちらか一方**を出す。⚠ **両方は要らない**
    - **直せるなら PR**（⚠ こちらが望ましい。**受け取った gem 側が Issue を起こして紐づける**。[workflow.md](workflow.md) の「着手順」参照）
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

### ⚠⚠ 上書きを書くときに、上流へ返すかを決めて印を残す

上の 2 節は、**不具合を踏んだとき**（アプリ→gem）と **gem を直したとき**（gem→アプリ）に動く規則。⚠ **どちらも、不具合ではない「一般化できる拡張」を利用側で作ったときには動かない。**放っておくと、上流にとっても有益な部品が利用側に溜まり、gem を読むだけでは見えなくなる。

⚠ **これは想像ではない。**2026-11-07 に `mulukhiya-toot-proxy` の上書きを洗い出したら（[pooza/mulukhiya-toot-proxy#4898](https://github.com/pooza/mulukhiya-toot-proxy/issues/4898)）、gem のメソッドの上書きが約 120 か所あり、大半は差し替え口（`prefix` / `dir` / `command` など）の正しい実装だったが、次の 3 つの形が混じっていた。

| 形 | 実例 |
| --- | --- |
| **上流に入ったのに写しが残っている** | `MisskeyService#oauth_server_metadata`。gem 側と同じ日に入り、利用側の写しが消されないまま 9 か月残っていた |
| **gem の作りのせいで写すしかなかった** | `Redis#initialize`。gem が `self.class.dsn` ではなく `Service.dsn` と決め打ちしているので、DSN を差し替えるには `initialize` を丸ごと写すしかない（`TagContainer.new` の決め打ちと同じ形） |
| **一般化できる拡張を抱えている** | Redis のロックの道具（`SET NX EX` / compare-and-delete）、JSON で読み書きする `get` / `set` の写しが約 12 本 |

**How to apply:**

1. ⚠⚠ **gem のメソッドを上書きするときは、その場で「一般化できるか」を決める。**後で棚卸しすると、上書きの理由を思い出すところからやり直しになる（⚠ 既にある分だけは下の手順で一度洗い出す）
2. **決めた結果を、上書きしたメソッドのコメントに残す。**どちらに決めたかが grep で拾えるようにする
    - **返す**: gem へたたき台の PR を出し、コメントに `pooza/ginseng-X#n` を書く。着地して `bundle update` したら、⚠ **利用側の写しを消すところまでが手順**（上の「消し方まで書かないと残り続ける」と同じ）
    - **返さない**: 理由を書く。⚠ **「相手の事情であって一般には成り立たない」と書ければ十分**。手本は `mulukhiya-toot-proxy` の `DictionaryHTTP#retryable?`（404 を再送するのは GAS の事情なので上流を変えにいかない）
3. ⚠ **「gem の作りのせいで写すしかない」と気づいたら、それは拡張ではなく gem の不具合として扱う。**上の「ginseng-* の変更手順」の 1 に戻る
4. ⚠ **差し替え口の実装には印は要らない。**gem が上書きされる前提で用意した面（`prefix` を返すだけ、など）は、上書きすること自体が正しい使い方
5. ⚠ **「いま他の利用者がいない」は返さない理由にならないが、急ぐ理由にもならない。**返すか決めかねるものは「返さない（理由: 利用者が 1 つだけ）」と書いておき、2 つ目の利用者が現れたときに見直す

#### ⚠⚠ すでにある上書きは、各プロジェクトで一度だけ洗い出す

上の規則は**これから書く上書き**に効く。⚠ **すでにある上書きには印が無いので、各プロジェクトで一度だけ洗い出して印を付ける。**`ginseng-*` を使っているプロジェクトごとに Issue を 1 本立てて着手する（手本: [pooza/mulukhiya-toot-proxy#4898](https://github.com/pooza/mulukhiya-toot-proxy/issues/4898)）。

1. **アプリを読み込み、gem のメソッドを上書きしている箇所を機械的に抜き出す。**⚠ `grep '< Ginseng::'` だけでは**継承しているクラス**しか分からず、**どのメソッドを上書きしているか**が出ない。読み込んだ上で、`instance_method(m).super_method&.owner` が `Ginseng::` の下にあるものを拾う

    ```ruby
    ObjectSpace.each_object(Class).select {|c| c.name&.start_with?('<アプリの名前空間>::')}.each do |c|
      [c, c.singleton_class].each do |k|
        (k.instance_methods(false) + k.private_instance_methods(false)).each do |m|
          next unless (sm = k.instance_method(m).super_method) && sm.owner.inspect.include?('Ginseng')
          puts [c.name, m, sm.owner.inspect, k.instance_method(m).source_location&.join(':')].join("\t")
        end
      end
    end
    ```

    ⚠ Zeitwerk などで遅延読み込みしているなら、先に全部読み込む（`eager_load`）。読まれていないクラスは出てこない
2. **差し替え口の実装を除く。**`prefix` / `dir` / `command` / `default_service` のように、gem が上書きされる前提で用意した面を返すだけのものは印が要らない（上の 4）。⚠ モロヘイヤでは約 120 か所のうち大半がこれだった
3. **残りを上の表の 3 つの形と「アプリ固有」に振り分け、上の 2 のとおり印を付ける。**写しは消し、gem の不具合は gem へ、拡張は返すか決める
4. ⚠ **一覧を Issue に貼っておく。**全部を一度に読めなくても、どこまで読んだかが残る


### ⚠ ピン留めのばらけを放置しない

`Gemfile.lock` は git 参照のリビジョンを固定するので、**リポジトリごとに違う版が刺さったまま何ヶ月も進む**。security 修正が一部にしか届いていない状態になりやすい。定期的に横断で棚卸しする。

⚠ **`ginseng-style` は別扱い**（上記「参照は必ず SHA で固定する」）。刺さっている版は `Gemfile` の `tag:` に書いてあり、古いものは週次の [gem-watch](../.github/workflows/gem-watch.yml) が出す。⚠⚠ **`ginseng-core` などライブラリ本体は #103 でアプリ側から `tag:` 固定へ移している途中**で、固定したものは `gem-watch` の `consumers` ジョブが週次で出す。🔴 **利用側の dependabot は 9 本中 7 本が `lockfile-only` で、`Gemfile` の `tag:` を書き換えない**（2026-09-11 実測）ので、⚠⚠ **固定した版の古さに気づく口は `consumers` だけ**。移り終わるまでは下の棚卸しも要る。

```sh
for d in ~/repos/*/; do
  printf '%-24s ' "$(basename "$d")"
  awk '/remote: https:\/\/github.com\/pooza\/ginseng-core/{f=1} f&&/revision:/{print substr($2,1,10); exit}' \
    "$d/Gemfile.lock" 2>/dev/null || echo -
done
```

## Ruby のパッチ版に追従する

**急がないが、放置もしない。** 起点は `ginseng-style` の追跡 Issue（`rollout` ラベル。4.0.7 は #114、4.0.9 は #131）。

- ⚠⚠ **リリース告知ではなく default gem の版差を見る。** 4.0.7 は告知に CVE が無かったが、同梱の resolv が CVE を直していた（#114）
- 🔴 **順番は「サーバー → アプリ側の `.ruby-version`」。** 逆にすると起動しない。サーバー側が終わったら追跡 Issue にコメントがあり、それを合図に PR を配る
- 🔴 **`.ruby-version` を上げる PR で、`Gemfile.lock` の `BUNDLED WITH` もその Ruby に同梱の bundler へそろえる** (#131)。同梱の版は `RBENV_VERSION=<版> gem list bundler` の `default:` の先頭で確かめ、`bundle update --bundler=<その版>` で書き換える
  - ⚠ **そろえないと、サーバーの `bundle install` の前に `gem install bundler -v <lock の版>` が要る。** 実例: mulukhiya-toot-proxy 5.43.0 は lock が 4.0.18 のまま 4.0.9（同梱は 4.0.20）へ上げ、ステージング・本番 8 台すべてで手で入れた
  - ⚠ **`BUNDLED WITH` は手元の bundler の版が書き込まれるだけで、Ruby の更新とは連動しない。** 2026-10-28 の実測で公開アプリ 7 本は 4.0.10 / 4.0.17 / 4.0.20 の 3 種類に分かれていた
  - ⚠ **Ruby を上げない回は `BUNDLED WITH` を動かさない**（動いていたら差分で気づく）
- ⚠ **`ginseng-style` の配布物（`TargetRubyVersion` / `required_ruby_version`）はパッチ版では動かない。** バンプしない。gem 側の CI は `4.0` の浮動指定なので作業は要らない
