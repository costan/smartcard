# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT


require 'rubygems'
require 'smartcard'

require 'test/unit'


class ExceptionTest < Test::Unit::TestCase
  def test_exception_with_known_status
    status = 0x8010002E
    win32_status = status - 2 ** 32
    
    exception = Smartcard::PCSC::Exception.new win32_status
    assert_equal status, exception.pcsc_status_code
    assert_equal :no_readers_available, exception.pcsc_status
  end

  def test_exception_with_bogus_status
    status = 0x88888888
    win32_status = status - 2 ** 32
    
    exception = Smartcard::PCSC::Exception.new win32_status
    assert_equal status, exception.pcsc_status_code
    assert_nil exception.pcsc_status
  end
end
