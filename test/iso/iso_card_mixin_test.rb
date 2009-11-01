# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT

require 'smartcard'

require 'test/unit'

require 'rubygems'
require 'flexmock/test_unit'


class IsoCardMixinTest < Test::Unit::TestCase
  IsoCardMixin = Smartcard::Iso::IsoCardMixin
  
  # The sole purpose of this class is wrapping the mixin under test.
  class MixinWrapper
    include IsoCardMixin
  end
  
  def setup
  end

  def test_serialize_apdu
    s = lambda { |apdu| IsoCardMixin.serialize_apdu apdu }

    assert_equal [0x00, 0x05, 0x00, 0x00, 0x00, 0x00], s[:ins => 0x05],
                 'Specified INS'
    assert_equal [0x00, 0x09, 0x00, 0x01, 0x00, 0x00],
                 s[:ins => 0x09, :p2 => 0x01],
                 'Specified INS and P2'
    assert_equal [0x00, 0xF9, 0xAC, 0xEF, 0x00, 0x00],
                 s[:ins => 0xF9, :p1 => 0xAC, :p2 => 0xEF],
                 'Specified INS, P1, P2'
    assert_equal [0x00, 0xFA, 0xAD, 0xEC, 0x00, 0x00],
                 s[:ins => 0xFA, :p12 => [0xAD, 0xEC]],
                 'Specified INS, P1+P2'
    assert_equal [0x00, 0x0E, 0x00, 0x00, 0x04, 0x33, 0x95, 0x81, 0x63, 0x00],
                 s[:ins => 0x0E, :data => [0x33, 0x95, 0x81, 0x63]],
                 'Specified INS and DATA'
    assert_equal [0x80, 0x0F, 0xBA, 0xBE, 0x03, 0x31, 0x41, 0x59, 0x00],
                 s[:cla => 0x80, :ins => 0x0F, :p1 => 0xBA, :p2 => 0xBE,
                   :data => [0x31, 0x41, 0x59]],
                 'Specified everything'
    assert_raise(RuntimeError, 'Did not specify INS') do
      s[:cla => 0x80, :p1 => 0xBA, :p2 => 0xBE, :data => [0x31, 0x41, 0x59]]
    end
  end
  
  def test_deserialize_response
    d = lambda { |response| IsoCardMixin.deserialize_response response }
    
    assert_equal({ :status => 0x9000, :data => [] }, d[[0x90, 0x00]])
    assert_equal({ :status => 0x8631, :data => [] }, d[[0x86, 0x31]])
    assert_equal({ :status => 0x9000, :data => [0x31, 0x41, 0x59, 0x26] },
                 d[[0x31, 0x41, 0x59, 0x26, 0x90, 0x00]])
    assert_equal({ :status => 0x7395, :data => [0x31, 0x41, 0x59, 0x26] },
                 d[[0x31, 0x41, 0x59, 0x26, 0x73, 0x95]])
  end
  
  def win_mock
    mock = MixinWrapper.new
    flexmock(mock).should_receive(:exchange_apdu).
                   with([0x00, 0xF9, 0xAC, 0x00, 0x02, 0x31, 0x41, 0x00]).
                   and_return([0x67, 0x31, 0x90, 0x00])
    mock
  end  
  def win_apdu
    {:ins => 0xF9, :p1 => 0xAC, :data => [0x31, 0x41]}
  end
  
  def lose_mock
    mock = MixinWrapper.new
    flexmock(mock).should_receive(:exchange_apdu).
                   with([0x00, 0xF9, 0xAC, 0x00, 0x02, 0x31, 0x41, 0x00]).
                   and_return([0x86, 0x31])
    mock
  end  
  def lose_apdu
    win_apdu
  end

  def test_iso_apdu
    assert_equal({:status => 0x9000, :data => [0x67, 0x31]},
                 win_mock.iso_apdu(win_apdu))
    assert_equal({:status => 0x8631, :data => []},
                 lose_mock.iso_apdu(lose_apdu))
  end
  
  def test_iso_apdu_bang
    assert_equal [0x67, 0x31], win_mock.iso_apdu!(win_apdu)
    assert_raise(RuntimeError) do
      lose_mock.iso_apdu!(lose_apdu)
    end
  end
end
