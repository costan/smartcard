# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{smartcard}
  s.version = "0.4.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Victor Costan"]
  s.date = %q{2009-11-01}
  s.description = %q{Interface with ISO 7816 smart cards.}
  s.email = %q{victor@costan.us}
  s.extensions = ["ext/smartcard_pcsc/extconf.rb"]
  s.extra_rdoc_files = ["BUILD", "CHANGELOG", "LICENSE", "README", "ext/smartcard_pcsc/extconf.rb", "ext/smartcard_pcsc/pcsc.h", "ext/smartcard_pcsc/pcsc_card.c", "ext/smartcard_pcsc/pcsc_constants.c", "ext/smartcard_pcsc/pcsc_context.c", "ext/smartcard_pcsc/pcsc_exception.c", "ext/smartcard_pcsc/pcsc_io_request.c", "ext/smartcard_pcsc/pcsc_main.c", "ext/smartcard_pcsc/pcsc_multi_strings.c", "ext/smartcard_pcsc/pcsc_namespace.c", "ext/smartcard_pcsc/pcsc_reader_states.c", "ext/smartcard_pcsc/pcsc_surrogate_reader.h", "ext/smartcard_pcsc/pcsc_surrogate_wintypes.h", "lib/smartcard.rb", "lib/smartcard/gp/asn1_ber.rb", "lib/smartcard/gp/cap_loader.rb", "lib/smartcard/gp/des.rb", "lib/smartcard/gp/gp_card_mixin.rb", "lib/smartcard/iso/auto_configurator.rb", "lib/smartcard/iso/iso_card_mixin.rb", "lib/smartcard/iso/jcop_remote_protocol.rb", "lib/smartcard/iso/jcop_remote_server.rb", "lib/smartcard/iso/jcop_remote_transport.rb", "lib/smartcard/iso/pcsc_transport.rb", "lib/smartcard/iso/transport.rb", "lib/smartcard/pcsc/pcsc_exception.rb"]
  s.files = ["BUILD", "CHANGELOG", "LICENSE", "Manifest", "README", "Rakefile", "ext/smartcard_pcsc/extconf.rb", "ext/smartcard_pcsc/pcsc.h", "ext/smartcard_pcsc/pcsc_card.c", "ext/smartcard_pcsc/pcsc_constants.c", "ext/smartcard_pcsc/pcsc_context.c", "ext/smartcard_pcsc/pcsc_exception.c", "ext/smartcard_pcsc/pcsc_io_request.c", "ext/smartcard_pcsc/pcsc_main.c", "ext/smartcard_pcsc/pcsc_multi_strings.c", "ext/smartcard_pcsc/pcsc_namespace.c", "ext/smartcard_pcsc/pcsc_reader_states.c", "ext/smartcard_pcsc/pcsc_surrogate_reader.h", "ext/smartcard_pcsc/pcsc_surrogate_wintypes.h", "lib/smartcard.rb", "lib/smartcard/gp/asn1_ber.rb", "lib/smartcard/gp/cap_loader.rb", "lib/smartcard/gp/des.rb", "lib/smartcard/gp/gp_card_mixin.rb", "lib/smartcard/iso/auto_configurator.rb", "lib/smartcard/iso/iso_card_mixin.rb", "lib/smartcard/iso/jcop_remote_protocol.rb", "lib/smartcard/iso/jcop_remote_server.rb", "lib/smartcard/iso/jcop_remote_transport.rb", "lib/smartcard/iso/pcsc_transport.rb", "lib/smartcard/iso/transport.rb", "lib/smartcard/pcsc/pcsc_exception.rb", "test/gp/asn1_ber_test.rb", "test/gp/cap_loader_test.rb", "test/gp/des_test.rb", "test/gp/gp_card_mixin_test.rb", "test/gp/hello.apdu", "test/gp/hello.cap", "test/iso/auto_configurator_test.rb", "test/iso/iso_card_mixin_test.rb", "test/iso/jcop_remote_test.rb", "test/pcsc/containers_test.rb", "test/pcsc/smoke_test.rb", "tests/ts_pcsc_ext.rb", "smartcard.gemspec"]
  s.homepage = %q{http://www.costan.us/smartcard}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Smartcard", "--main", "README"]
  s.require_paths = ["lib", "ext"]
  s.rubyforge_project = %q{smartcard}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Interface with ISO 7816 smart cards.}
  s.test_files = ["test/gp/asn1_ber_test.rb", "test/gp/cap_loader_test.rb", "test/gp/des_test.rb", "test/gp/gp_card_mixin_test.rb", "test/iso/auto_configurator_test.rb", "test/iso/iso_card_mixin_test.rb", "test/iso/jcop_remote_test.rb", "test/pcsc/containers_test.rb", "test/pcsc/smoke_test.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rubyzip>, [">= 0.9.1"])
    else
      s.add_dependency(%q<rubyzip>, [">= 0.9.1"])
    end
  else
    s.add_dependency(%q<rubyzip>, [">= 0.9.1"])
  end
end
