require 'yaml'
package = YAML.load_file(File.join(__dir__, 'config/lib.yaml'))['package']

Gem::Specification.new do |spec|
  spec.name = 'ginseng-style'
  spec.version = package['version']
  spec.authors = package['authors']
  spec.email = package['email']
  spec.summary = package['description']
  spec.description = package['description']
  spec.homepage = package['url']
  spec.license = package['license']
  spec.metadata['homepage_uri'] = package['url']
  spec.metadata['rubygems_mfa_required'] = 'true'
  # ⚠⚠ **docs は同梱しない**（#82）。同梱された docs を読むものが何も無い一方で、
  # `docs/` が配布物に入っていると**文章を 1 行直すだけでリリースが要る**。
  # ⚠ 規約は GitHub の main を読む（利用側の参照も blob/main の URL）。
  spec.files = Dir['config/**/*', 'lib/**/*', 'LICENSE.txt', 'README.md']
  spec.require_paths = ['lib']
  # ⚠⚠ **ここは「揃えたい版」ではなく「利用側の最低版」(#63)。** この gem は
  # 規約を配る側なので、利用側の版の**和集合**を飲まないと入らない。3.4 へ
  # 上げた v1.1.3 で、3.3 を残している ginseng-core の CI が
  # `ginseng-style-1.1.3 requires ruby version >= 3.4` で落ちた。
  # ⚠ CI の matrix / TargetRubyVersion とは決め方が違う。
  spec.required_ruby_version = '>=3.3'

  # ⚠ linter 本体をこの gem が抱える。利用側の Gemfile から rubocop 系の
  # development_dependency を消せるようにするのが目的。
  #
  # 🔴 上限（悲観固定）: **linter の版を固定しないと、参照をタグで固定した意味が
  #   半分しか出ない (#55)。** gem 側 7 本は `Gemfile.lock` を追跡していないので、
  #   CI のチェックアウトに lock が無く、`bundle install` は毎回 rubocop の最新を引く。
  #   ⚠⚠ `config/rubocop.yml` は `NewCops: enable` なので、**こちらが 1 行も
  #   コミットしていないのに、rubocop のリリース翌日に 8 本の CI が赤くなりうる**。
  #   ⚠ 実測（2026-08-31）: 過去 12 か月に入った新 cop 27 個は**全部 `pending`**
  #   （＝ `NewCops: enable` が自動で有効にする）。新 cop が入るのは minor だけなので、
  #   `~> x.y.0` は cop の顔ぶれを凍らせたままパッチの修正だけ受け取る。
  #   ⚠⚠ **動かしてよい条件: 外すのではなく上げる。** 上げるのは、8 リポジトリで
  #   `bundle exec rubocop` を通して新しい offense を潰し、版を配るとき
  #   （docs/CLAUDE.md の「⚠ 設定を変えるときの手順」）。⚠ 上げ時の合図は
  #   gem-watch の `linters` ジョブが週次で一覧に出す（赤にはしない）。
  spec.add_dependency 'rubocop', '~> 1.90.0'
  spec.add_dependency 'rubocop-minitest', '~> 0.40.0'
  spec.add_dependency 'rubocop-performance', '~> 1.27.0'
  spec.add_dependency 'rubocop-rake', '~> 0.7.1'
end
