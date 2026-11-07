# ginseng-* のメソッドを上書きしている箇所を、読み込んだ上で抜き出す。
#
#   bundle exec ruby -I app/lib <このファイル> <入口の .rb> <アプリの名前空間>
#   例: bundle exec ruby -I app/lib overrides.rb app/lib/mulukhiya.rb Mulukhiya
#
# 標準出力に TSV（種類・クラス・メソッド・上書きされた側・定義の場所）、標準エラーに件数と
# 読めなかった定数を出す。
#
# - override: アプリの Class / Module が、Ginseng のメソッドを上書きしている
# - prepend:  アプリのモジュールを Ginseng のクラスへ prepend している
# - reopen:   Ginseng のクラスを開き直して、アプリのファイルでメソッドを定義している
#
# grep '< Ginseng::' では継承しているクラスしか分からず、どのメソッドを上書きしているか、
# 開き直し・prepend は出ない。

require File.expand_path(ARGV.fetch(0))
ns = ARGV.fetch(1)
root = Dir.pwd

# 遅延読み込み（Zeitwerk）の定数を 1 つずつ読む。eager_load は 1 つ落ちるとそこで止まるので使わない。
# 手元に DB が無いと Sequel のモデルは読めない — 読めなかった分は数えて出す。
failed = []
if defined?(Zeitwerk)
  Zeitwerk::Registry.loaders.each do |loader|
    loader.all_expected_cpaths.each_value do |cpath|
      next unless cpath == ns || cpath.start_with?("#{ns}::")
      Object.const_get(cpath)
    rescue StandardError, LoadError => e
      failed << "#{cpath} (#{e.class})"
    end
  end
end

# name / inspect を上書きしているモジュールがある（REXML::Functions.name など）ので、束縛し直して呼ぶ。
name_of = Module.instance_method(:name)
inspect_of = Module.instance_method(:inspect)
named = ->(mod, prefix) {name_of.bind_call(mod)&.start_with?(prefix)}
ginseng = /\A(#<Class:)?Ginseng::/
own_methods = ->(k) {k.instance_methods(false) + k.private_instance_methods(false)}

mods = ObjectSpace.each_object(Module).to_a
rows = []
mods.select {|c| named.call(c, "#{ns}::")}.each do |c|
  [c, c.singleton_class].each do |k|
    own_methods.call(k).each do |m|
      method = k.instance_method(m)
      next unless (sm = method.super_method) && inspect_of.bind_call(sm.owner).match?(ginseng)
      rows << ['override', name_of.bind_call(c), m, inspect_of.bind_call(sm.owner),
        method.source_location&.join(':')]
    end
  end
end
mods.select {|c| named.call(c, 'Ginseng::')}.each do |c|
  [c, c.singleton_class].each do |k|
    k.ancestors.take_while {|a| a != k}.select {|p| named.call(p, "#{ns}::")}.each do |p|
      rows << ['prepend', name_of.bind_call(c), '-', inspect_of.bind_call(p), '-']
    end
    own_methods.call(k).each do |m|
      method = k.instance_method(m)
      next unless method.owner == k && method.source_location&.first&.start_with?(root)
      rows << ['reopen', name_of.bind_call(c), m, '-', method.source_location.join(':')]
    end
  end
end

rows.uniq.each {|row| puts row.join("\t")}
warn rows.group_by(&:first).transform_values(&:size).inspect
warn "読めなかった定数: #{failed.size}"
failed.each {|f| warn "  #{f}"}

# 読み込んだファイルが test-unit を引くと、終了時に autorun が標準出力へ書く。
Test::Unit::AutoRunner.need_auto_run = false if defined?(Test::Unit::AutoRunner)
