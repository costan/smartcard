# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT

require 'smartcard'

require 'test/unit'

class Asn1BerTest < Test::Unit::TestCase
  Asn1Ber = Smartcard::Gp::Asn1Ber
  
  def test_tag
    prefix = [0x03, 0x14, 0x15]
    [
      [[0x82], {:primitive => true, :class => :context, :number => 2}],
      [[0x29], {:primitive => false, :class => :universal, :number => 9}],
      [[0xD9], {:primitive => true, :class => :private, :number => 0x19}],
      [[0x9F, 0x65], {:primitive => true, :class => :context, :number => 0x65}],
      [[0x5F, 0x81, 0x65], {:primitive => true, :class => :application,
                            :number => 0xE5}],
    ].each do |test_case|
      offset, tag = Asn1Ber.decode_tag prefix + test_case.first, prefix.length
      assert_equal((prefix + test_case.first).length, offset,
                   "Offset for #{test_case.inspect}")
      assert_equal test_case.last, tag,
                   "Decoded tag information for #{test_case.inspect}"
      assert_equal test_case.first, Asn1Ber.encode_tag(test_case.last),
                   "Encoded tag for #{test_case.inspect}"       
    end
  end
  
  def test_length
    prefix = [0x03, 0x14, 0x15]
    [
      [[0x12], 0x12],
      [[0x82, 0x05, 0x39], 0x539],
      [[0x80], :indefinite],
    ].each do |test_case|
      offset, length = Asn1Ber.decode_length prefix + test_case.first,
                                             prefix.length
      assert_equal((prefix + test_case.first).length, offset,
                   "Offset for #{test_case.inspect}")
      assert_equal test_case.last, length,
                   "Decoded length for #{test_case.inspect}"      
      assert_equal test_case.first, Asn1Ber.encode_length(test_case.last),
                   "Encoded length for #{test_case.inspect}"       
    end
  end
  
  def test_value
    data = (0...20).to_a
    offset, value = Asn1Ber.decode_value data, 7, 4
    assert_equal 7 + 4, offset, 'Offset with definite length'
    assert_equal [7, 8, 9, 10], value, 'Value with definite length'
    
    data = [0x03, 0x14, 0x15, 0x92, 0x65, 0x35, 0x00, 0x00, 0x01, 0x02, 0x03]
    offset, value = Asn1Ber.decode_value data, 4, :indefinite
    assert_equal 8, offset, 'Offset with indefinite length'
    assert_equal [0x65, 0x35], value, 'Value with definite length'
    offset, value = Asn1Ber.decode_value data, 6, :indefinite
    assert_equal 8, offset, 'Offset for empty value with  indefinite length'
    assert_equal [], value, 'Empty value with indefinite length'        
  end
  
  def test_tlv
    golden_tlv = {:primitive => true, :class => :context, :number => 4,
                  :value => [0xA0, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00]}
    prefix = [0x03, 0x14, 0x15]
    ber_tlv = [0x84, 0x08, 0xA0, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00]
    offset, tlv = Asn1Ber.decode_tlv prefix + ber_tlv, prefix.length
    assert_equal golden_tlv, tlv, 'Decoded TLV data'
    assert_equal((prefix + ber_tlv).length, offset, 'Offset')
    assert_equal ber_tlv, Asn1Ber.encode_tlv(golden_tlv), 'Encoded TLV data'
  end
  
  def test_tlv_sequence
    golden = [
        {:number => 0x0F, :class => :application, :primitive => false,
         :value => [
           {:number => 4, :class => :context, :primitive => true,
            :value => [0xA0, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00]},
           {:number => 5, :class => :context, :primitive => false,
            :value => [
              {:number => 0x65, :class => :context, :primitive => true,
               :value => [0xFF]}]}]}]
    ber = [0x6F, 16, 0x84, 8, 0xA0, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00,
           0xA5, 4, 0x9F, 0x65, 1, 0xFF]    
    assert_equal golden, Asn1Ber.decode(ber), 'Decoded sequence'
    assert_equal ber, Asn1Ber.encode(golden), 'Encoded sequence'
  end
  
  def test_visit
    tlvs = [
        {:number => 0x0F, :class => :application, :primitive => false,
         :value => [
           {:number => 4, :class => :context, :primitive => true,
            :value => [0xA0, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00]},
           {:number => 5, :class => :context, :primitive => false,
            :value => [
              {:number => 0x65, :class => :context, :primitive => true,
               :value => [0xFF]}]}]}]
    
    paths = []
    Asn1Ber.visit tlvs do |path, value|
      paths << path
      case path
      when [0x6F, 0xA5, 0x9F65]
        assert_equal [0xFF], value
      when [0x6F, 0x84]
        assert_equal [0xA0, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00], value
      end
    end
    assert_equal [[0x6F], [0x6F, 0x84], [0x6F, 0xA5], [0x6F, 0xA5, 0x9F65]],
                 paths, 'Visited paths'
  end
end
