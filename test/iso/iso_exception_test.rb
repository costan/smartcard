# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT

require 'smartcard'

require 'test/unit'

require 'rubygems'
require 'flexmock/test_unit'


class ApduErrorTest < Test::Unit::TestCase
  def setup
    @response = { :data => [0x31, 0x41, 0x59], :status => 0x6A88 }
  end
  
  def test_raise
    assert_raise Smartcard::Iso::ApduError do
      raise Smartcard::Iso::ApduError, @response
    end
  end
  
  def test_contents
    begin
      raise Smartcard::Iso::ApduError, @response
    rescue Smartcard::Iso::ApduError => e
      assert_equal @response[:status], e.status, 'Error status attribute'
      assert_equal @response[:data], e.data, 'APDU data attribute'
      golden_message =
          'ISO-7816 response APDU has error status 0x6a88 - 31 41 59'
      assert_equal golden_message, e.message, 'Exception message'
    end
  end
  IsoCardMixin = Smartcard::Iso::IsoCardMixin
end
