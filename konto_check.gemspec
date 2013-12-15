# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "konto_check"
  s.version = "5.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Provideal Systems GmbH", "Jan Schwenzien", "Michael Plugge"]
  s.date = "2013-12-15"
  s.description = "Checking german BICs/Bank account numbers and IBANs, generate IBANs, retrieve information about german Banks, search for Banks matching certain criteria, check IBAN or BIC, convert bic/account to IBAN and BIC"
  s.email = "m.plugge@hs-mannheim.de"
  s.extensions = ["ext/konto_check_raw/extconf.rb"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.textile",
    "ext/konto_check_raw/konto_check_raw_ruby.c"
  ]
  s.files = [
    "ext/konto_check_raw/extconf.rb",
    "ext/konto_check_raw/konto_check.c",
    "ext/konto_check_raw/konto_check.h",
    "ext/konto_check_raw/konto_check_raw_ruby.c",
    "lib/konto_check.rb"
  ]
  s.homepage = "http://kontocheck.sourceforge.net"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.25"
  s.summary = "Checking german BICs/Bank account numbers and IBANs, generate IBANs, retrieve information about german Banks, search for Banks matching certain criteria"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    else
      s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    end
  else
    s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
  end
end

