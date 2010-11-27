# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT

require 'smartcard'

require 'test/unit'

require 'rubygems'
require 'flexmock/test_unit'


class CardTest < Test::Unit::TestCase
  def setup
    @context = Smartcard::PCSC::Context.new
    @reader = @context.readers.first
    @card = @context.card @reader, :shared
  end
  
  def teardown
    @card.disconnect    
    @context.release    
  end
  
  def test_sharing_mode
    assert_equal :shared, @card.sharing_mode
  end

  def test_reconnect
    @card.reconnect :shared
    assert_equal :shared, @card.sharing_mode
  end
  
  def test_transaction
    @card.begin_transaction
    @card.end_transaction
    
    @card.transaction { }
  end
  
  def test_transmit
    response = @card.transmit [0x00, 0xA4, 0x04, 0x00, 0x00].pack('C*')
    assert_equal [0x90, 0x00], response[-2, 2].unpack('C*'),
                 'In transmit: SELECT with no AID should always return OK'    
  end
  
  def test_info
    info = @card.info
    assert_operator info[:atr], :kind_of?, String,
                    "The card's ATR should be a string"
    assert_operator info[:readers], :include?, @reader,
                    "The card's readers list should have the canonical reader"
    assert_operator info[:protocol], :kind_of?, Symbol, "The card's protocol"    
    assert_operator info[:state], :include?, :present,
                    "The card's state should reflect the card's presence"
  end
  
  def test_get_attribute
    vendor_name = @card[:vendor_name]
    assert_operator vendor_name, :kind_of?, String,
                    'IFD attributes should be strings'        
  end
  
  def test_set_attribute
    assert_raise Smartcard::PCSC::Exception do
      @card[:atr_string] = "\0"
    end
  end
  
  def test_control
    # This only works with GemPlus readers... any other suggestions?
    assert_raise(Smartcard::PCSC::Exception, 'Control sequence') do
      ctl_response = @card.control 0x42000001, [0x02].pack('C*')
    end
  end
  
  def test_set_protocol_guesses
    flexmock(@card).should_receive(:guess_protocol_from_atr).and_return(:t0)
    flexmock(@card).should_receive(:reconnect).with(:shared, :t0, :leave)
    @card.send :set_protocol, :unset
  end

  def test_guess_protocol_t0_from_atr
    flexmock(@card).should_receive(:info).and_return(:atr => 
        ";\026\224q\001\001\005\002\000")    
    assert_equal :t0, @card.send(:guess_protocol_from_atr)    
  end
  
  def test_guess_protocol_t1_from_atr
    flexmock(@card).should_receive(:info).and_return(:atr => 
        ";\212\001JCOP41V221\377")    
    assert_equal :t1, @card.send(:guess_protocol_from_atr)    
  end
end
