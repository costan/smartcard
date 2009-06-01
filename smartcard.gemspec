# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{smartcard}
  s.version = "0.3.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Victor Costan"]
  s.date = %q{2009-05-31}
  s.description = %q{Interface with ISO 7816 smart cards.}
  s.email = %q{victor@costan.us}
  s.extensions = ["ext/smartcard_pcsc/extconf.rb"]
  s.extra_rdoc_files = ["BUILD", "CHANGELOG", "ext/smartcard_pcsc/extconf.rb", "ext/smartcard_pcsc/pcsc.h", "ext/smartcard_pcsc/pcsc_card.c", "ext/smartcard_pcsc/pcsc_constants.c", "ext/smartcard_pcsc/pcsc_context.c", "ext/smartcard_pcsc/pcsc_exception.c", "ext/smartcard_pcsc/pcsc_io_request.c", "ext/smartcard_pcsc/pcsc_main.c", "ext/smartcard_pcsc/pcsc_multi_strings.c", "ext/smartcard_pcsc/pcsc_namespace.c", "ext/smartcard_pcsc/pcsc_reader_states.c", "ext/smartcard_pcsc/pcsc_surrogate_reader.h", "ext/smartcard_pcsc/pcsc_surrogate_wintypes.h", "lib/smartcard/pcsc_exception.rb", "lib/smartcard.rb", "LICENSE", "README"]
  s.files = ["BUILD", "CHANGELOG", "ext/smartcard_pcsc/extconf.rb", "ext/smartcard_pcsc/pcsc.h", "ext/smartcard_pcsc/pcsc_card.c", "ext/smartcard_pcsc/pcsc_constants.c", "ext/smartcard_pcsc/pcsc_context.c", "ext/smartcard_pcsc/pcsc_exception.c", "ext/smartcard_pcsc/pcsc_io_request.c", "ext/smartcard_pcsc/pcsc_main.c", "ext/smartcard_pcsc/pcsc_multi_strings.c", "ext/smartcard_pcsc/pcsc_namespace.c", "ext/smartcard_pcsc/pcsc_reader_states.c", "ext/smartcard_pcsc/pcsc_surrogate_reader.h", "ext/smartcard_pcsc/pcsc_surrogate_wintypes.h", "lib/smartcard/pcsc_exception.rb", "lib/smartcard.rb", "LICENSE", "Manifest", "README", "test/test_containers.rb", "test/test_smoke.rb", "tests/ts_pcsc_ext.rb", "smartcard.gemspec", "Rakefile"]
  s.homepage = %q{http://www.costan.us/smartcard}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Smartcard", "--main", "README"]
  s.require_paths = ["lib", "ext"]
  s.rubyforge_project = %q{smartcard}
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{Interface with ISO 7816 smart cards.}
  s.test_files = ["test/test_containers.rb", "test/test_smoke.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
