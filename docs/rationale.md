# なぜ正本化したか

2026-08-19、「RuboCop の設定と、RuboCop に落とせない規約を 1 箇所に集めたい」という相談からこの gem を起こした。**設定を配るのは手段で、目的は「配った変更が全員に届いたかを見られる状態」を作ること。**

⚠ **このページは判断の記録。** 「どう書くか」は [ruby.md](ruby.md)、「どう配るか」は [workflow.md](workflow.md) と [CLAUDE.md](CLAUDE.md) にある。

## 起こした理由（2026-08-19 実測）

`.rubocop.yml` を持つ **22 リポジトリ**を突き合わせた。

- **10 本が 153 行完全一致**だった
- 本質的な差は **3 つだけ** — `TargetRubyVersion` / `Style/FrozenStringLiteralComment` / プロジェクト固有プラグイン
- 実際に配り終えたあとも、固有差分として残ったのは同じ 3 種類だった（[#1](https://github.com/pooza/ginseng-style/issues/1)）。**見立てと実測が一致した**

### 🔴 drift の実害

**`Exclude: test/*` を `test/**/*` に直したのが 1 リポジトリだけだった。** 残り 17 リポジトリでは、入れ子のテスト（`test/unit/...`）に除外が効いていなかった。

⚠ **直した人は直っている。壊れたままの 17 本は誰にも見えていない。** これが手で複製する運用の壊れ方で、複製した瞬間ではなく、**そのうちの 1 本を直した瞬間**に壊れる。

## ⚠⚠ 壊れているのは「手間」ではなく「観測」

「各々が気づいたときに直す」は、直す手間が問題なのではない。**投げた変更が全員に届いたかを誰も見ていない**ことが問題で、届かなかった側は緑のまま気づけない。同じ構造の症状が、起票後の調査で 2 つ出た。

### ピン留めのばらけ

`Gemfile.lock` は git 参照のリビジョンを固定するので、**リポジトリごとに違う版が刺さったまま進む**。`ginseng-core` の HEAD が 2026-08-18 の時点で、刺さっている版は **8 種類**、最古は **2026-04-14（4 ヶ月前）** だった。

⚠ **security 修正が一部にしか届いていない状態になりやすい。** 実例: [pooza/makoto2#101](https://github.com/pooza/makoto2/issues/101)（`Gemfile.lock` が 1.15.28 で止まり、security 修正 6 件を取り込めていなかった）。棚卸しの手順は [workflow.md](workflow.md) の「ピン留めのばらけを放置しない」にある。

### 🔴 CI が 1 本もテストを走らせていなかった

`ginseng-*` 全 7 gem の `.github/workflows/test.yml` は、中身が `bundle install` → `rake bundle:check` → `bundle exec rubocop` だけで、**`rake test` を呼ぶ行がどこにも無かった**。実在するテストは計 366 件。一度も走っていなかった（[#2](https://github.com/pooza/ginseng-style/issues/2)）。

⚠ **緑は「lint が通った」以上の意味を持っていなかった。** さらに push 契機しか無かったので、更新が止まった gem は永遠に緑のまま赤に気づけない。実例: `ginseng-postgres` の CI は 4 ヶ月赤のままだった。

⚠ **観測されていないものは、壊れていないのではなく、壊れているかどうかが分からない。**

## ✅ 正本を持ったことで実際に効いた例

[#11](https://github.com/pooza/ginseng-style/issues/11) — `rubocop-minitest` の 4 つの cop が、**test-unit に存在しないメソッドへ自動修正する**（minitest は `assert_path_exists`、test-unit は `assert_path_exist` と単数形）。

- ⚠ **`rubocop` は緑のまま通る。テストを実行して初めて落ちる**
- 1 リポジトリが「そのプロジェクト固有の緩和」として個別に回避していた。**実際は test-unit を使う全プロジェクトに共通する問題だった**
- 正本側で切ったので、以後は配った先すべてに効く

⚠⚠ **「固有の緩和」に見えるものが横断の問題であることは、横断で見て初めて分かる。** 正本を持つ理由そのもの。

⚠ この件は #2 で CI にテストを足した直後だったので捕まえられた。**足していなければそのまま本流へ入っていた。**

## 設計の決定と理由

- ⚠⚠ **`ginseng-core` に依存させない。** ginseng-core もこの gem の規約に従う側なので、依存させると循環する
- **rubocop 本体とプラグインをこの gem の `add_dependency` に持つ。** 利用側の `Gemfile` / gemspec から rubocop 系を消せるようにするため。⚠ 版のばらけを持ち込まない置き場所がここしか無い
- **ライブラリとしての実装は持たない。** 設定と docs を配るだけ
- `docs/` を役割で割る — [ruby.md](ruby.md)（言語）/ [workflow.md](workflow.md)（運用）/ [writing.md](writing.md)（表記）
- **ルートに `CLAUDE.md` を置く。** ⚠ `docs/CLAUDE.md` は自動では読まれない。git 管理下の入口があれば全端末・全セッションで効く

### ⚠ 検証したこと（2026-08-19）

スクラッチのプロジェクトで `inherit_gem` の実挙動を確認してから配った。

- ✅ `inherit_gem` で解決される（⚠ `bundle exec` 前提。gem のパス解決に Bundler を使う）
- ✅ 継承した緩和が効く（`Style/RedundantReturn` が黙る）／設定も効く（`Style/StringLiterals` が発火）
- ✅ **`Exclude: test/**/*` が効く** — 110 桁の行を `test/unit/` に置いても `Layout/LineLength` が出ない（`test/*` のままだと出る＝今回直したかった drift）
- ✅ **利用側の `plugins` は継承分を潰さず合成される** — 利用側で `rubocop-sequel` だけを宣言した状態で、Minitest 55 / Performance 52 / Rake 5 / Sequel 6 の cop がすべてロードされた

## ⚠ 配るときの検証

**`bundle exec rubocop --show-cops` の差分がゼロ**（ロードされる cop の顔ぶれが移行前と完全一致）であることを確認してから配る。

⚠ **`ginseng-postgres` だけ 671 → 726 に増えた。** 旧 `.rubocop.yml` の `require:` に `rubocop-minitest` が無く、**Minitest 系 55 cop が一度もロードされていなかった**（gemspec には `add_development_dependency` として書かれていたのに）。⚠ **差分ゼロを期待して測ると、こういう「元が壊れていた」が拾える。**
