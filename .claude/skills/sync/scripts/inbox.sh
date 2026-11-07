#!/usr/bin/env bash
# ginseng-* と gobou に届いている Issue / PR / コメントと、出荷・CI の状態を集める（読むだけ）。
# 使い方: inbox.sh [YYYY-MM-DD]   この日以降のコメントと参照を出す。省略すると 7 日前から
# GINSENG_SYNC_EXTRA_REPOS（owner/repo を空白区切り）があれば、参照の検索に足す。
# ⚠ public リポジトリなので、private と他 org の名前はこのファイルに書かない。
# ⚠⚠ 取得の失敗を「0 件」に見せない。失敗は行に出し、終了コードを 1 にする。
set -uo pipefail

since=${1:-$(date -d '7 days ago' +%F)}
gems=(ginseng-style ginseng-core ginseng-fediverse ginseng-web ginseng-redis ginseng-postgres ginseng-piefed ginseng-youtube)
# ⚠ gobou（Node.js / PHP の共有設定・ginseng-style#142）も依頼を受けるので、集める対象に入れる。
# 版の正本が package.json で、タグは手で打つ（自動の release-tag を持たない）ので、出荷の判定だけ分ける
repos=("${gems[@]}" gobou)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# ⚠ サブシェルやコマンド置換の中でも失敗を残すので、変数ではなくファイルに記録する。
# ⚠ 文言は stderr へ。stdout だとコマンド置換の値に混ざる
q() {
  if ! timeout -k 5 60 gh "$@"; then
    echo "🔴 取得失敗: gh $*" >&2
    : > "$tmp/failed"
  fi
}

echo "## open PR"
for g in "${repos[@]}"; do
  q pr list -R "pooza/$g" --state open --limit 50 --json number,title,updatedAt,author,isDraft,statusCheckRollup \
    --jq ".[]|\"$g#\(.number) draft=\(.isDraft) \(.updatedAt[:10]) @\(.author.login) checks=\([.statusCheckRollup[]?|(.conclusion // .state)]|unique|join(\"/\")) \(.title)\""
done

echo
echo "## open Issue"
for g in "${repos[@]}"; do
  q issue list -R "pooza/$g" --state open --limit 100 --json number,title,labels,updatedAt \
    --jq ".[]|\"$g#\(.number) [\(.labels|map(.name)|join(\",\"))] \(.updatedAt[:10]) \(.title)\""
done

# ⚠ ラベルの付いていない依頼があるので、本文の文言でも拾う（中身は読んで判断する）
echo
echo "## 依頼の候補（request ラベルなし・本文の文言）"
for g in "${repos[@]}"; do
  q issue list -R "pooza/$g" --state open --limit 100 --json number,title,labels,body \
    --jq ".[]|select(.labels|map(.name)|index(\"request\")|not)|select(.body|test(\"依頼|お願いします|お願いしたい\"))|\"$g#\(.number) \(.title)\""
done

echo
echo "## $since 以降のコメント（bot を除く）"
for g in "${repos[@]}"; do
  q api --paginate "repos/pooza/$g/issues/comments?since=${since}T00:00:00Z&per_page=100" \
    --jq ".[]|select(.user.type!=\"Bot\")|\"$g#\(.issue_url|split(\"/\")|last) \(.created_at[:10]) @\(.user.login): \(.body[:300]|gsub(\"\\\\s+\";\" \"))\""
done

# ⚠ 依頼は相手のリポジトリから参照の形で来ることがある。gem の名前で探すので、自分の告知も混ざる
echo
echo "## $since 以降に更新された、ginseng-* / gobou を参照する open Issue（gem 側と gobou を除く）"
{
  for term in pooza/ginseng pooza/gobou; do
    q search issues "$term" --owner pooza --state open --updated ">=$since" --limit 100 --json repository,number,title,updatedAt \
      --jq '.[]|select(.repository.name|(startswith("ginseng") or .=="gobou")|not)|"\(.repository.nameWithOwner)#\(.number) \(.updatedAt[:10]) \(.title)"'
    for r in ${GINSENG_SYNC_EXTRA_REPOS:-}; do
      q search issues "$term" --repo "$r" --state open --updated ">=$since" --limit 100 --json repository,number,title,updatedAt \
        --jq '.[]|"\(.repository.nameWithOwner)#\(.number) \(.updatedAt[:10]) \(.title)"'
    done
  done
} | sort -u

echo
echo "## 出荷（version ＝ 最新タグか）"
for g in "${gems[@]}"; do
  version=$(q api "repos/pooza/$g/contents/config/lib.yaml" -H 'Accept: application/vnd.github.raw' | sed -nE 's/^ +version: *//p' | head -1)
  tag=$(q api "repos/pooza/$g/tags?per_page=100" --jq '.[].name' | sort -V | tail -1)
  if [ -z "$version" ] || [ -z "$tag" ]; then
    echo "🔴 $g を判定できない（version=$version tag=$tag）"
    : > "$tmp/failed"
  elif [ "v$version" = "$tag" ]; then
    echo "$g v$version"
  else
    echo "🟡 $g version=$version tag=$tag"
  fi
done
# ⚠⚠ gobou はタグを手で打つので、打ち忘れはここでしか見えない（週次の見張りは持たない）
version=$(q api "repos/pooza/gobou/contents/package.json" -H 'Accept: application/vnd.github.raw' --jq .version)
tag=$(q api "repos/pooza/gobou/tags?per_page=100" --jq '.[].name' | sort -V | tail -1)
if [ -z "$version" ] || [ -z "$tag" ]; then
  echo "🔴 gobou を判定できない（version=$version tag=$tag）"
  : > "$tmp/failed"
elif [ "v$version" = "$tag" ]; then
  echo "gobou v$version"
else
  echo "🟡 gobou version=$version tag=$tag（タグの打ち忘れ。手順は gobou の CLAUDE.md）"
fi

echo
echo "## main の失敗（直近 10 実行）"
for g in "${repos[@]}"; do
  q run list -R "pooza/$g" --branch main --limit 10 --json workflowName,conclusion,createdAt \
    --jq ".[]|select(.conclusion==\"failure\")|\"🔴 $g \(.workflowName) \(.createdAt[:10])\""
done

# ⚠⚠ ログでは ::warning:: が ##[warning] に変わる。`gh run view --log` は 0 バイトを黙って返すので zip で取る
echo
echo "## gem-watch の最新実行"
run=$(q run list -R pooza/ginseng-style --workflow gem-watch.yml --limit 1 --json databaseId,conclusion,createdAt \
  --jq '.[0]|"\(.databaseId) \(.conclusion) \(.createdAt[:10])"')
echo "$run"
if [[ $run =~ ^[0-9]+ ]] && q api "repos/pooza/ginseng-style/actions/runs/${BASH_REMATCH[0]}/logs" > "$tmp/logs.zip" && unzip -q "$tmp/logs.zip" -d "$tmp/logs"; then
  grep -rhE '##\[(warning|error)\]' "$tmp/logs" | sed -E 's/^[^ ]+ //' | sort -u
else
  echo "🔴 gem-watch のログを読めない"
  : > "$tmp/failed"
fi

[ ! -e "$tmp/failed" ]
