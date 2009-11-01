# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT

require 'smartcard'

require 'test/unit'

class CapLoaderTest < Test::Unit::TestCase
  CapLoader = Smartcard::Gp::CapLoader
  
  def setup
    @cap_file = File.join(File.dirname(__FILE__), 'hello.cap')
    @apdu_file = File.join(File.dirname(__FILE__), 'hello.apdu')
  end
  
  def test_load_data
    load_data = CapLoader.cap_load_data(@cap_file)
    assert_equal File.read(@apdu_file),
        load_data[:data].map { |ch| "%02x" % ch }.join(' ')
    assert_equal [{:aid => [0x19, 0x83, 0x12, 0x29, 0x10, 0xDE, 0xAD],
                   :install_method => 8}], load_data[:applets]
    golden_header = { :version => { :major => 2, :minor => 1 },
        :magic => 0xDECAFFED, :flags => Set.new([:has_applets]),
        :package => { :aid => [0x19, 0x83, 0x12, 0x29, 0x10, 0xDE, 0xAE],
                      :version => { :major => 1, :minor => 0 } } }
    assert_equal golden_header, load_data[:header]
  end
end
