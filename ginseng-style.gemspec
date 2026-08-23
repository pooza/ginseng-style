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
  spec.files = Dir['config/**/*', 'docs/**/*', 'lib/**/*', 'LICENSE.txt', 'README.md']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>=3.4'

  # ⚠ linter 本体をこの gem が抱える。利用側の Gemfile から rubocop 系の
  # development_dependency を消せるようにするのが目的。
  spec.add_dependency 'rubocop'
  spec.add_dependency 'rubocop-minitest'
  spec.add_dependency 'rubocop-performance'
  spec.add_dependency 'rubocop-rake'

  # ⚠ このリポジトリの Rakefile を回すためだけに要る。他の gem は ginseng-core
  # 経由で rake が入るが、⚠⚠ この gem は ginseng-core に依存させられない（循環する）。
  spec.add_development_dependency 'rake'
end
