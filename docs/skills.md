# スキルの置き方と配り方

`docs/` に書いてきた「名前のついた手順書」を Claude Code のスキルへ移し、**プラグインとして配る**ための取り決め (#104)。⚠ **rubocop の配布（`inherit_gem`）とは別の経路**で、固定の単位も違う。

## 決めたこと

### 1. 正本はスキル、docs はポインタ

⚠⚠ **二重に持たない。** 手順を足すときはスキルの側だけを直し、`docs/` からはリンクする。

- 🔴 **技術的にもこの向きしか採れない。** **プラグインはインストール時にキャッシュへコピーされ、プラグインのディレクトリの外にあるファイルは付いてこない** — `docs/` を参照するスキルは、配った先で読めない
- ⚠ **「人間も GitHub で docs を読む」は失われない。** スキルの本体はこのリポジトリの普通のファイル（`plugins/ginseng/skills/<name>/SKILL.md`）なので、**入れていない環境からもリンクで全文が読める**
- ⚠ スキルの中からリンクを張るときは **GitHub の絶対 URL** にする。相対パスはキャッシュされた先で外れる

### 2. 起動のさせ方（⚠ 暫定）

**外向きの操作を含む手順は明示呼び出しに限る**（`disable-model-invocation: true`）。⚠ **読むだけの手順は自動でよい。** 🔴 **#104 の 2. は未決なので、これは最初の 1 本に当てた暫定の線。**

### 3. 版の系列は gem と分ける

**プラグインの版は [plugin.json](../plugins/ginseng/.claude-plugin/plugin.json) の `version`、gem の版は [config/lib.yaml](../config/lib.yaml) の `package.version`。別々に動かす。**

- ⚠ **プラグインは配布物ではない。** `spec.files` にも `release.yml` の `paths` にも入っていないので、**スキルを直してもバンプもタグも要らない**（[CLAUDE.md](CLAUDE.md) の「設定を変えるときの手順」の対象外）
- 🔴🔴 **代わりに `version` を上げないと利用側へ届かない。** ⚠⚠ **利用側は `version` が変わったときだけ更新を受け取る** — 固定した以上、配り忘れが自動では直らないのは gem と同じ形

## 入れ方

⚠ **マシンごとに 1 回ずつ、手で入れる。** 🔴 **外部ソースのプラグインは自動では入らない**（Claude Code v2.1.195 以降）。

```
/plugin marketplace add pooza/ginseng-style
/plugin install ginseng@ginseng-style
```

呼ぶときは**プラグイン名の名前空間が付く**。

```
/ginseng:codex-review
```

更新は `/plugin marketplace update ginseng-style` のあと `/plugin update ginseng`。

## ⚠⚠ 固定の単位がリポジトリではなくマシン

🔴 **同じマーケットプレイスを、プロジェクトごとに違う版で入れることはできない**（2026-09-11 実測。別の `ref` で追加しようとすると拒否される）。

```
✘ Cannot add marketplace "...": its network source differs from the one declared
  for it in settings (kind, target, or a fetch-shaping field such as headers / ref / path / sparsePaths)
```

- ⚠ **利用者が 1 人なので、これは都合がよい** — 全プロジェクトが自動的に同じ版に揃う
- ⚠⚠ **`inherit_gem` の「リポジトリごとにタグで固定」と混ぜて考えない。** ずれの見張り方（`gem-watch`）もそのままでは当たらない（🔴 未決）

## 測ったこと（2026-09-12）

`claude plugin details ginseng` の見積もり。⚠ **「手順書をスキルにすると軽くなる」は自動的には成り立たない** — 手順書はもともと必要なときにしか読まれていないので、比べるのは**常に載る分**と**呼んだときの分**。

| | 量 |
| --- | --- |
| 常に載る（説明文だけ） | **約 29 トークン** |
| 呼んだとき | 約 2.6k トークン |

## いま入っているスキル

| スキル | 中身 |
| --- | --- |
| [codex-review](../plugins/ginseng/skills/codex-review/SKILL.md) | Codex（自動レビュー）の指摘の採否・返信と 👍 / 👎・取り残しの走査。⚠ 正本はこちら（[workflow.md](workflow.md) はポインタ） |
