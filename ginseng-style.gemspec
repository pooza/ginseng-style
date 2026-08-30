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
  spec.add_dependency 'rubocop'
  spec.add_dependency 'rubocop-minitest'
  spec.add_dependency 'rubocop-performance'
  spec.add_dependency 'rubocop-rake'
end
