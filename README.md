# ginseng-style

pooza の Ruby プロジェクト共通の **RuboCop 設定と規約の正本**。

これまで各リポジトリの `.rubocop.yml` を手で複製していたため、22 リポジトリに実質同一のファイルが散り、少しずつ drift していた（例: `Exclude: test/*` を `test/**/*` に直したのが 1 リポジトリだけで、残りでは入れ子のテストに除外が効いていなかった）。設定と、RuboCop に落とせない規約の両方をここに集める。

⚠ **なぜ正本化したか、何を実測してそう決めたかは [docs/rationale.md](docs/rationale.md) にある。**

## 導入

`Gemfile` の development group に足す。

```ruby
group :development do
  # ⚠⚠ ref: に SHA を書く。理由は下の「⚠⚠ SHA で固定する」。
  gem 'ginseng-style', github: 'pooza/ginseng-style',
      ref: '7196764dca7628c3fd1226bcc08415f8bda2fd31', require: false # v1.1.7
end
```

### ⚠⚠ SHA で固定する

**固定せずに（＝ `main` を追って）参照すると、利用側が 1 行もコミットしていないのに、こちらが cop を足した次の push で CI が赤くなる。** `NewCops: enable` があるので、rubocop 本体の更新でも同じことが起きる。

⚠⚠ **タグではなく SHA で固定する（[#75](https://github.com/pooza/ginseng-style/issues/75)）。** タグは付け替えられるので、動く ref のままだと**このリポジトリを取られた側が利用側のワークフローを差し替えられる**。⚠ 特に [release-tag](.github/actions/release-tag/action.yml) は利用側の `contents: write` トークンを受け取る。

- **末尾に `# vX.Y.Z` をコメントで添える。** ⚠ 人間が読むためのもの
- ⚠⚠ **コメントは検査に使わない。** 週次の [gem-watch](.github/workflows/gem-watch.yml) は **SHA からタグを引いて突き合わせる**。⚠ **タグの無い SHA を刺していたら赤にする**（レビューを通っていないコミットを刺している）

⚠⚠ **`Gemfile.lock` は代わりにならない。** gem 側は `Gemfile.lock` を `.gitignore` しているので、**CI のチェックアウトには lock が存在せず**、毎回 `main` の HEAD が解決される。実測（2026-08-23）では、gem 側 7 本の手元と CI で **45〜48 コミット違う `ginseng-style`** を見ていた（[#53](https://github.com/pooza/ginseng-style/issues/53)）。

CI の composite action を使っている場合は、**そちらも同じ版に揃える**。

```yaml
- uses: pooza/ginseng-style/.github/actions/ruby-check@7196764dca7628c3fd1226bcc08415f8bda2fd31 # v1.1.7
```

版を上げるのは `Gemfile` / `test.yml` / `release.yml` の **3 行**を書き換える**明示的な操作**にする。⚠ **古い版で止まっているリポジトリは週次の [gem-watch](.github/workflows/gem-watch.yml) が知らせる**ので、放置には気付ける。

`.rubocop.yml` は差分だけにする。

```yaml
inherit_gem:
  ginseng-style: config/rubocop.yml

AllCops:
  TargetRubyVersion: 4.0
```

- ⚠ **`bundle exec rubocop` で実行すること。** `inherit_gem` は gem のパス解決に Bundler を使う
- rubocop 本体と `rubocop-minitest` / `rubocop-performance` / `rubocop-rake` はこの gem が依存として持つので、利用側の `development_dependency` から外せる
- プロジェクト固有のプラグイン（`rubocop-sequel` など）と cop は、利用側の `.rubocop.yml` に書く

### タグを打つワークフロー（`ginseng-*` の gem 側）

🔴 **手で打つ運用は死ぬ。** 2026-08-27 の実測で、`ginseng-*` 4 gem に**計 8 版ぶんの出荷が滞留**していた（うち 1 本は security 修正 2 件が未出荷）。手順本体はこの gem の composite action にある（#65）。

```yaml
# .github/workflows/release.yml
on:
  push:
    branches:
      - main
  workflow_dispatch:

permissions:
  contents: write        # ⚠ タグを作るので要る

jobs:
  tag:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
        with:
          fetch-depth: 0   # ⚠ 判定にタグとの差分が要る。浅いと届かない
          persist-credentials: false
      - uses: pooza/ginseng-style/.github/actions/release-tag@7196764dca7628c3fd1226bcc08415f8bda2fd31 # v1.1.7
        with:
          mode: manual     # ⚠⚠ gem 側は manual
          # ⚠⚠ 既定は無い。**このリポジトリが配る中身**を列挙する（下表）
          paths: bin cert config images lib views ginseng-core.gemspec
          token: ${{ github.token }}
```

**タグの正本は `config/lib.yaml` の `package.version`。** ⚠⚠ **`mode` を間違えないこと。**

| `mode` | タグを打つ引き金 | 使うリポジトリ |
| --- | --- | --- |
| `manual` | **`workflow_dispatch`**（人が押す） | 着手時バンプをするリポジトリ（`ginseng-*` の gem 側） |
| `auto` | `main` への push | バンプ＝リリースのリポジトリ（`ginseng-style` 自身） |

- ⚠⚠ **着手時バンプをするなら `manual`。** `auto` にすると **マイルストーンの 1 本目の PR が載った時点で出荷される**
- **出荷は `gh workflow run release.yml -R pooza/<gem>`。** ⚠ 押すのは「Issue を消化 → リリース前レビュー」の後
- ⚠ どちらの mode でも、push のたびに**「配布物を変えたのに `v<version>` のまま」を検査して赤で教える**。引っ掛かったら version を上げる

#### ⚠⚠ `paths` に既定は無い

**リポジトリごとに配る中身が違うので、それらしい既定を置くと静かに取りこぼす** — つまりこの検査が一番効いてほしい場面で黙る。`git` 参照で使う以上、**`lib/` と `config/` だけではない**。2026-08-27 の実測:

| リポジトリ | `paths` |
| --- | --- |
| `ginseng-style` | `config lib LICENSE.txt README.md ginseng-style.gemspec .github/actions` |
| `ginseng-core` | `bin cert config images lib views ginseng-core.gemspec` |
| `ginseng-fediverse` | `bin config images lib ginseng-fediverse.gemspec` |
| `ginseng-web` | `bin config lib public views ginseng-web.gemspec` |
| `ginseng-postgres` | `bin config lib query ginseng-postgres.gemspec` |
| `ginseng-redis` / `ginseng-youtube` | `bin config lib <name>.gemspec` |
| `ginseng-piefed` | `config lib ginseng-piefed.gemspec` |

⚠⚠ **`*.gemspec` を必ず入れること。** 依存と `required_ruby_version` はここにあり、**版を上げずに変えると利用側へ永久に届かない**。⚠ `required_ruby_version` を上げた `v1.1.3` が利用側の CI を落とした（[#63](https://github.com/pooza/ginseng-style/issues/63)）ように、**gemspec の 1 行が利用側を壊しうる**。

⚠ **`spec.files` に並んでいるものも入れる。** `ginseng-style` は `LICENSE.txt` / `README.md` を gem として配っている。

⚠⚠ **`docs/` は配らない（[#82](https://github.com/pooza/ginseng-style/issues/82)）。** 規約は GitHub の `main` を読む前提で、**同梱された docs を読むものが何も無い**（`lib/` からも読んでいない／利用側の参照も `blob/main` の URL）。一方で `paths` に入れると**文章を 1 行直すだけでリリースが要り**、そのたびに利用側 7 本 × 3 経路が古くなる — 2026-08-27 は 5 リリース中 3 本が docs のみで、⚠ **warning が 21 件**立った。

🔴 **`spec.files` と `paths` の両方から外すこと。** 片方だけ外すと、上の「`spec.files` に並んでいるものも入れる」と食い違う。

⚠ **`test/` は入れない。** 配る中身ではないので、テストを足すたびに版を上げることになる。

### プロジェクト固有として残してよいもの

- `AllCops/TargetRubyVersion`
- `AllCops/Include` / `Exclude` のプロジェクト固有パス（`seed/**/*`、`var/**/*`、`bin/<name>` など）
- 追加プラグインとその cop（`Sequel/*` など）
- そのプロジェクトでしか意味を持たない緩和（`Minitest/RefutePathExists` など）

⚠ **共通に見える緩和を勝手に足さないこと。** 1 リポジトリの都合を全体に配ることになる。共通化したい場合は Issue を立てる。

### ⚠⚠ `Include` / `Exclude` は継承した配列を「置換」する

`inherit_gem` した先で `AllCops/Include` や `AllCops/Exclude` を書くと、**マージされずに置換される**。⚠ **`rubocop` は緑のまま通る**ので気づけない（`Include: [bin/foo]` とだけ書くと「1 file inspected, no offenses」になる）。

- **`Exclude` は `inherit_mode` で足す**
- ⚠ **`Include` は `inherit_mode` に入れない。** 入れると rubocop 既定の Include（`Gemfile` など）まで戻ってきて、他のリポジトリと lint 対象がずれる。**必要な分を全部書く**

🔴 **正本自身がこの罠を踏んでいた (#80)。** `Include` に 3 つしか書いていなかったので、rubocop 既定に入っている **`Gemfile` と `*.gemspec` が全リポジトリで lint されていなかった**（`ginseng-core` の `Gemfile` に 10 スペース字下げの行が残っていた）。⚠⚠ **`Include` に足すときは「rubocop 既定にあるか」を確かめる** — 既定にあるものを書き漏らすのは**取りこぼし**で、既定に無いものを足すのは別の判断。

```yaml
inherit_gem:
  ginseng-style: config/rubocop.yml

inherit_mode:
  merge:
    - Exclude

AllCops:
  Exclude:
    - seed/**/*      # 継承した Exclude に足される
  Include:
    # ⚠ 置換されるので、継承分（config/rubocop.yml の 5 つ）も含めて全部書く。
    #   1 つでも落とすと、そのパターンのファイルが黙って lint 対象から外れる。
    - '**/*.rb'
    - '**/*.gemspec'
    - '**/Gemfile'
    - '**/Rakefile'
    - '**/config.ru'
    - bin/makoto     # ここから下がプロジェクト固有
```

⚠⚠ **配る前に `bundle exec rubocop --list-target-files` の差分がゼロであることを確認する。** `--show-cops` の差分ゼロだけでは**この事故を検出できない**（cop の顔ぶれは変わらないため）。

## 規約

RuboCop で機械的に守れないものはこちら。

| ドキュメント | 内容 |
| --- | --- |
| [docs/ruby.md](docs/ruby.md) | Ruby の書き方。暗黙の return を使わない、2 スペース、`return` に多行チェインを繋がない理由、テストの `disable?` パターン、文字列のエンコーディング |
| [docs/workflow.md](docs/workflow.md) | Issue 駆動・ブランチ・マイルストーンとサイズラベル・リリース前レビュー・**依存の制約**・**`ginseng-*` の変更手順** |
| [docs/writing.md](docs/writing.md) | 表記規約。用語・パスとキーの書き方・⚠ マーカーの使い方 |
| [docs/rationale.md](docs/rationale.md) | なぜ正本化したか。drift の実測とその実害、設計の決定の理由 |

各プロジェクトの `docs/CLAUDE.md` からは、ここを正本として参照する。プロジェクト固有の事情だけをローカルに残す。

## 変更するとき

⚠ **`config/rubocop.yml` の変更は inherit している全プロジェクトに波及する。** 1 リポジトリで通してから配ること。手順は [docs/CLAUDE.md](docs/CLAUDE.md) にある。

⚠⚠ **`main` にマージしただけでは誰にも届かない。** 利用側は SHA で固定しているので、`config/lib.yaml` の `package.version` を上げ（タグは [release.yml](.github/workflows/release.yml) が自動で打つ）、**各リポジトリの参照 3 経路を新しいタグの SHA へ上げる PR を出すところまでが手順**。
