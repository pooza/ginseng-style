# Ruby の書き方

RuboCop の設定（[config/rubocop.yml](../config/rubocop.yml)）で機械的に守れるものはそちらに書いてある。ここは **RuboCop に落とせない規約と、設定の「なぜ」** を置く場所。

## 暗黙の return を使わない

メソッド末尾でも `return` を省略しない。

```ruby
# ✅
def name
  return @name
end

# ❌
def name
  @name
end
```

⚠ この方針のために `Style/RedundantReturn` を無効化してある。cop を有効に戻すと全コードが赤くなる。

## インデントは常に論理的な 2 スペース

見栄えのための位置揃えは使わない。代入の右辺に `case` / `if` 式を置いて深くインデントする書き方も避け、各分岐の中で個別に代入する。

```ruby
# ✅
def label
  case kind
  when :vocal
    label = '歌'
  when :bgm
    label = 'BGM'
  end
  return label
end

# ❌ 右辺に式を置いて位置を揃える
label = case kind
        when :vocal then '歌'
        when :bgm   then 'BGM'
        end
```

⚠ `Layout/EndAlignment: EnforcedStyleAlignWith: variable` はこれを検出するために入れてある。

## ⚠ `return` に多行のチェインを繋がない

受け皿の変数に置くか、1 行にする。

```ruby
# ⚠ これは 4 スペースを要求される
return stub_request(:get, url)
    .to_return(status:, body:)

# ✅
headers = {'Content-Type' => 'application/json'}
return stub_request(:get, url).to_return(status:, body:, headers:)
```

**理由**: `Layout/MultilineMethodCallIndentation`（と同じ mixin を使う `Layout/MultilineOperationIndentation`）は、前置キーワードの継続行に 4 スペースを要求する。

```ruby
while foo &&
    bar       # 4 ＝ 条件の続き
  baz         # 2 ＝ 本体
end
```

`if` / `while` / `until` / `for` では、条件の継続行と本体が同じ桁に並ぶので、これは妥当な区別。ところが RuboCop の `KEYWORD_ANCESTOR_TYPES` には `return` も入っている。

```ruby
# rubocop/cop/mixin/multiline_expression_indentation.rb
KEYWORD_ANCESTOR_TYPES = %i[for if while until return].freeze
```

⚠⚠ **`return` には本体が無いので、見分ける相手が存在しない。** 4 にする理由がそのまま消える。メッセージが `a condition in a return statement` と壊れているのが取り違えの裏返し（`return` に「条件」は無い）。

**実測**（rubocop 1.88.2 / `EnforcedStyle: indented`）:

| 形 | 要求 |
| --- | --- |
| `x = foo(1)` ＋ `.bar(2)` | 2（通る） |
| ⚠ `return foo(1)` ＋ `.bar(2)` | 🔴 4 |
| `while foo(1)` ＋ `.bar(2)` ＋ 本体 | 4（妥当） |

- ⚠⚠ **cop は切らない。** `if` / `while` の側では実際に効いている
- ⚠ **設定で `return` だけ外す口は無い**（`correct_indentation` が固定で足している）
- ⚠⚠ **上流（`rubocop-hq/rubocop`）には出さない。** あちらにはあちらの意図があるはずで、こちらの規約との食い違いを上流の不具合として持ち込まない。**自分たちの gem（`ginseng-*`）に対する起票とは扱いが違う**

出所: [pooza/makoto2#95](https://github.com/pooza/makoto2/issues/95)

## 例外変数は `e`

`Naming/RescuedExceptionsVariableName` で強制している。

## 設定へのアクセスはスラッシュ記法

ginseng の `Config` を使うプロジェクトでは `config['/path/to/key']` の形で書く。ドット記法やシンボルの入れ子で書かない。

## テスト

- test-unit を使う。基底クラスは各プロジェクトの `TestCase`（`Ginseng::TestCase` 継承）
- モックは WebMock（`require 'webmock/test_unit'`）。既定はネット許可で、モックを使うテストで `WebMock.disable_net_connect!` を明示的に呼ぶ
- 機能追加・バグ修正には対応するテストを書く。⚠ ただし DB 依存・外部 API 依存のテストは無理に書かなくてよい（CI で実行できる範囲で）

### ⚠ `disable?` パターン

test-unit のライフサイクルは `setup` → `run_test` → `teardown`。`disable?` が `true` を返すと `run_test` はスキップされるが、**`setup` は常に実行される**。DB 接続や外部サービスに依存する `setup` では、冒頭に `return if disable?` を必ず置く。

```ruby
def disable?
  return true unless Environment.dbms_class&.config?
  return true unless test_token
  return super
end

def setup
  return if disable?
  @model = SomeModel.new
end
```

### ⚠ 一見 DB 無関係なクラスが DB を要求することがある

初期化チェーンを辿ると DB に着くことがある。モロヘイヤの実例:

```
TagContainer.new → normalize → TaggingHandler → Handler#initialize
  → SNSService → account_class → Sequel::Model → DB 必須
```

この形は `disable?` に `Environment.dbms_class&.config?` を入れるか、`rescue` で捕まえて `true` を返す。

## 文字列のエンコーディング

⚠ **外から来た文字列が UTF-8 である保証は無い。** `JSON.parse` は不正な UTF-8 バイト列を弾かず、UTF-8 タグのまま返す。Rack の form パースも同じ。

- 不正バイト列に対して `sub` / `gsub` / `strip` / `scan` / `match?` は `ArgumentError` を上げる
- **バイト列は正しいが UTF-8 でない**場合（Shift_JIS / ASCII-8BIT）は上記が素通りし、`unicode_normalize` だけが `Encoding::CompatibilityError` を上げる ＝ **正規化を通らない経路では黙って壊れる**
- ⚠ `scrub` で黙って直さない。`"\xE3\x81ほげ".scrub` は `"�ほげ"` になり、化けた値が下流へ流れる。入力が壊れていることは呼び出し側に返す

関連: [pooza/ginseng-fediverse#248](https://github.com/pooza/ginseng-fediverse/issues/248) / [pooza/ginseng-core#518](https://github.com/pooza/ginseng-core/issues/518) / [pooza/mulukhiya-toot-proxy#4600](https://github.com/pooza/mulukhiya-toot-proxy/issues/4600)
