require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'spec/rake/spectask'
require 'yard'

desc 'Default: run specs tests.'
task :default => :spec

desc 'Run all specs'
Spec::Rake::SpecTask.new 'spec' do |t|
  t.spec_files = FileList['spec']
  t.spec_opts = ["--colour"]
end

desc 'Generate documentation for the permit plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Permit'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc 'Generate YARDocs'
YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb']
end

