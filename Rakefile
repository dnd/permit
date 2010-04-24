require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run specs tests.'
task :default => :spec

begin
  require 'rspec/core'
  require 'rspec/core/rake_task'

  desc 'Run all specs'
  Rspec::Core::RakeTask.new 'spec'

  begin
    require 'rcov'

    desc 'Run all specs with rcov'
    Rspec::Core::RakeTask.new 'rcov' do |t|
      #t.spec_files = FileList['spec']
      t.rcov = true
      t.rcov_opts = ['--rails', '--exclude \(^lib\){0}']
    end
  rescue LoadError
    warn "RCov is not available. To run specs with coverage `gem install rcov`."
  end
rescue LoadError
  warn "RSpec is not available. To run specs `gem install rspec`."
end

desc 'Generate documentation for the permit plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Permit'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'yard'

  desc 'Generate YARDocs'
  YARD::Rake::YardocTask.new do |t|
    t.files   = ['lib/models/**/*.rb', 'lib/permit/**/*.rb', 'lib/*.rb']
  end
rescue LoadError
  warn "YARD not available. To compile YARDocs `gem install yard`."
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "permit"
    gem.summary = "A flexible authorization plugin for Ruby on Rails."
    gem.email = "steve@digitalnothing.com"
    gem.homepage = "http://github.com/dnd/permit"
    gem.author = "Steve Valaitis"
    gem.files.exclude 'autotest'
    gem.extra_rdoc_files = ['README.mkd']
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  warn "Jeweler not available. To install `gem install jeweler`."
end

