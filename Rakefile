require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run specs tests.'
task :default => :spec

begin
  require 'spec'
  require 'spec/rake/spectask'

  desc 'Run all specs'
  Spec::Rake::SpecTask.new 'spec' do |t|
    t.spec_files = FileList['spec']
    t.spec_opts = ["--colour"]
  end

  begin
    require 'rcov'

    desc 'Run all specs with rcov'
    Spec::Rake::SpecTask.new 'rcov' do |t|
      t.spec_files = FileList['spec']
      t.rcov = true
      t.rcov_opts = ['--exclude', 'spec,app/,config/,rubygems/']
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
    t.files   = ['lib/**/*.rb']
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

