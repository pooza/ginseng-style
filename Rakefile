dir = File.expand_path(__dir__)
ENV['BUNDLE_GEMFILE'] = File.join(dir, 'Gemfile')

namespace :bundle do
  desc 'update gems'
  task :update do
    sh 'bundle update'
  end

  desc 'install bundler'
  task :install_bundler do
    sh 'gem install bundler'
  end
end

namespace :rubocop do
  desc 'rubocop'
  task :lint do
    sh 'rubocop'
  end
end

desc 'lint all'
task lint: ['rubocop:lint']

task default: [:lint]
