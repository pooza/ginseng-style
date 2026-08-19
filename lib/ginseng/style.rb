require 'yaml'

module Ginseng
  # 設定ファイルと規約 docs を配るだけの gem。ライブラリとしての実装は持たない。
  #
  # ⚠ **ginseng-core に依存させないこと。** ginseng-core 側もこの gem の規約に
  # 従う側なので、依存させると循環する。
  module Style
    def self.dir
      return File.expand_path('../..', __dir__)
    end

    def self.version
      return YAML.load_file(File.join(dir, 'config/lib.yaml'))['package']['version']
    end

    # 利用側が `inherit_gem` に書くパス。
    def self.rubocop_config_path
      return File.join(dir, 'config/rubocop.yml')
    end

    def self.docs_dir
      return File.join(dir, 'docs')
    end
  end
end
