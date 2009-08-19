# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT

require 'smartcard'

require 'test/unit'

require 'rubygems'
require 'flexmock/test_unit'


class GpCardMixinTest < Test::Unit::TestCase
  GpCardMixin = Smartcard::Gp::GpCardMixin
  
  # The sole purpose of this class is wrapping the mixin under test.
  class MixinWrapper
    include GpCardMixin
    include Smartcard::Iso::IsoCardMixin
  end
  
  def setup
  end
    
  def test_select_application
    mock = MixinWrapper.new
    flexmock(mock).should_receive(:exchange_apdu).
                   with([0x00, 0xA4, 0x04, 0x00, 0x05,
                         0x19, 0x83, 0x12, 0x29, 0x10]).
                   and_return([0x90, 0x00])
    mock.select_application([0x19, 0x83, 0x12, 0x29, 0x10])
  end
end
