# ginseng-style

pooza の Ruby プロジェクト共通の **RuboCop 設定と規約の正本**。

これまで各リポジトリの `.rubocop.yml` を手で複製していたため、22 リポジトリに実質同一のファイルが散り、少しずつ drift していた（例: `Exclude: test/*` を `test/**/*` に直したのが 1 リポジトリだけで、残りでは入れ子のテストに除外が効いていなかった）。設定と、RuboCop に落とせない規約の両方をここに集める。

⚠ **なぜ正本化したか、何を実測してそう決めたかは [docs/rationale.md](docs/rationale.md) にある。**

## 導入

`Gemfile` の development group に足す。

```ruby
group :development do
  # ⚠⚠ tag: を必ず付ける。理由は下の「⚠⚠ 版で固定する」。
  gem 'ginseng-style', github: 'pooza/ginseng-style', tag: 'v1.1.0', require: false
end
```

### ⚠⚠ 版で固定する

**`tag:` を付けずに（＝ `main` を追って）参照すると、利用側が 1 行もコミットしていないのに、こちらが cop を足した次の push で CI が赤くなる。** `NewCops: enable` があるので、rubocop 本体の更新でも同じことが起きる。

⚠⚠ **`Gemfile.lock` は代わりにならない。** gem 側は `Gemfile.lock` を `.gitignore` しているので、**CI のチェックアウトには lock が存在せず**、毎回 `main` の HEAD が解決される。実測（2026-08-23）では、gem 側 7 本の手元と CI で **45〜48 コミット違う `ginseng-style`** を見ていた（[#53](https://github.com/pooza/ginseng-style/issues/53)）。

CI の composite action を使っている場合は、**そちらも同じ版に揃える**。

```yaml
- uses: pooza/ginseng-style/.github/actions/ruby-check@v1.1.0
```

版を上げるのは `Gemfile` と `test.yml` の 2 行を書き換える**明示的な操作**にする。⚠ **古い版で止まっているリポジトリは週次の [gem-watch](.github/workflows/gem-watch.yml) が知らせる**ので、放置には気付ける。

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
    # ⚠ 置換されるので、継承分（config/rubocop.yml の 3 つ）も含めて全部書く。
    #   1 つでも落とすと、そのパターンのファイルが黙って lint 対象から外れる。
    - '**/*.rb'
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
| [docs/workflow.md](docs/workflow.md) | Issue 駆動・ブランチ・マイルストーンとサイズラベル・リリース前レビュー・**`ginseng-*` の変更手順** |
| [docs/writing.md](docs/writing.md) | 表記規約。用語・パスとキーの書き方・⚠ マーカーの使い方 |
| [docs/rationale.md](docs/rationale.md) | なぜ正本化したか。drift の実測とその実害、設計の決定の理由 |

各プロジェクトの `docs/CLAUDE.md` からは、ここを正本として参照する。プロジェクト固有の事情だけをローカルに残す。

## 変更するとき

⚠ **`config/rubocop.yml` の変更は inherit している全プロジェクトに波及する。** 1 リポジトリで通してから配ること。手順は [docs/CLAUDE.md](docs/CLAUDE.md) にある。

⚠⚠ **`main` にマージしただけでは誰にも届かない。** 利用側はタグで固定しているので、`config/lib.yaml` の `package.version` を上げ（タグは [release.yml](.github/workflows/release.yml) が自動で打つ）、**各リポジトリの `tag:` を上げる PR を出すところまでが手順**。
