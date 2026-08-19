# ginseng-style

pooza の Ruby プロジェクト共通の **RuboCop 設定と規約の正本**。

これまで各リポジトリの `.rubocop.yml` を手で複製していたため、22 リポジトリに実質同一のファイルが散り、少しずつ drift していた（例: `Exclude: test/*` を `test/**/*` に直したのが 1 リポジトリだけで、残りでは入れ子のテストに除外が効いていなかった）。設定と、RuboCop に落とせない規約の両方をここに集める。

⚠ **なぜ正本化したか、何を実測してそう決めたかは [docs/rationale.md](docs/rationale.md) にある。**

## 導入

`Gemfile` の development group に足す。

```ruby
group :development do
  gem 'ginseng-style', github: 'pooza/ginseng-style', require: false
end
```

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
