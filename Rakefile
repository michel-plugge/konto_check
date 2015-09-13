# Copyright (c) 2010 Peter Horn
# Copyright (c) 2011 Jan Schwenzien, Michael Plugge
# Copyright (c) 2013 Michael Plugge
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'rubygems'
require 'rake'
require 'rake/extensiontask'

Rake::ExtensionTask.new('konto_check')

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "konto_check"
    gem.summary = %Q{Checking german BICs/Bank account numbers and IBANs, generate IBANs, retrieve information about german Banks, search for Banks matching certain criteria, check IBAN or BIC, convert bic/account to IBAN and BIC}
    gem.description = %Q{Check whether a certain bic/account-no-combination or an IBAN can possibly be valid, generate IBANs, retrieve informations about a bank or search for BICs matching certain criteria. It uses the C library kontocheck (see http://sourceforge.net/projects/kontocheck/) by Michael Plugge.}
    gem.email = "m.plugge@hs-mannheim.de"
    gem.files=Dir.glob('lib/**/*.rb')+Dir.glob('ext/**/*.{c,h,rb}')
    gem.homepage = "http://kontocheck.sourceforge.net"
    gem.authors = ["Provideal Systems GmbH","Jan Schwenzien","Michael Plugge"]
    gem.add_development_dependency "thoughtbot-shoulda", ">= 0"
    gem.version = "5.8.0"
    gem.extra_rdoc_files = [
      "LICENSE",
      "README.textile",
      "ext/konto_check_raw/konto_check_raw_ruby.c",
    ]
    #gem.files.exclude "ext"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

#require 'rake/rdoctask'
require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
#  version = File.exist?('VERSION') ? File.read('VERSION') : ""
  version = "5.7.0"

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "konto_check #{version}"
  rdoc.rdoc_files.include('README.textile')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.include('ext/konto_check_raw/konto_check_raw_ruby.c')
end
