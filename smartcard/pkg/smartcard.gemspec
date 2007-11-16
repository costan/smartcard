require 'rubygems'

spec = Gem::Specification.new do |s| 
	s.name = "smartcard" 
	s.version = "0.1.0" 
	s.author = "Victor Costan" 
	s.email = "victor@costan.us" 
	s.homepage = "http://www.costan.us/smartcard" 
	s.platform = Gem::Platform::RUBY 
	s.summary = "Interface with ISO 7816 smart cards." 
	candidates = Dir.glob("{lib,ext,doc,tests,bin}/**/*")
	s.files = candidates.delete_if do |item|
		['.svn', 'rdoc', 'Makefile', 'pcsc_include.h'].any? { |str| item.include?(str) }
	end
	s.require_path = "lib"
	s.autorequire = "smartcard"
	s.extensions = ["ext/smartcard_pcsc/extconf.rb"]
#	s.test_file = "tests/ts_smartcard.rb" 
	s.has_rdoc = true 
	s.extra_rdoc_files = []
end 

if $0 == __FILE__ 
Gem::manage_gems 
Gem::Builder.new(spec).build 
end 