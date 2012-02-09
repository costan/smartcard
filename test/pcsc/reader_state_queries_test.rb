# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT

require 'rubygems'
require 'smartcard'

require 'test/unit'


class ReaderStatesTest < Test::Unit::TestCase
  def setup
    @queries = Smartcard::PCSC::ReaderStateQueries.new 2

    @queries[1].current_state = :atrmatch
    @queries[0].current_state = [:inuse, :exclusive]
    @queries[0].event_state = :ignore
    @queries[1].event_state = [:present, :unpowered]
    @queries[1].atr = "Ruby\0rocks!"
    @queries[0].atr = 'grreat success'
    @queries[0].reader_name = 'PC/SC Reader 0'
    @queries[1].reader_name = 'CCID Reader 1'
  end
  
  def teardown
  end

  def test_length
    assert_equal 2, @queries.length
  end

  def test_atr
    assert_equal "Ruby\0rocks!", @queries[1].atr
    assert_equal 'grreat success', @queries[0].atr     
  end
  
  def test_atr_reassign
    @queries[1].atr = 'even more success'
    assert_equal 'even more success', @queries[1].atr
  end
  
  def test_states
    assert_equal Set.new([:atrmatch]), @queries[1].current_state,
                 'current_state'
    assert_equal Set.new([:inuse, :exclusive]), @queries[0].current_state,
                 'current_state'

    assert_equal Set.new([:ignore]), @queries[0].event_state,
                 'event_state'
    assert_equal Set.new([:present, :unpowered]), @queries[1].event_state,
                 'event_state'
  end
  
  def test_high_order_bits_in_states
    packed_state = 0xFFFFFFFF
    unpacked_state = Smartcard::PCSC::FFILib::ReaderStateQuery.
        unpack_state packed_state
    repacked_state = Smartcard::PCSC::FFILib::ReaderStateQuery.
        pack_state unpacked_state
    assert_equal repacked_state, packed_state
    assert_operator unpacked_state, :include?, :atrmatch
  end
  
  def test_reader_names
    assert_equal 'PC/SC Reader 0', @queries[0].reader_name
    assert_equal 'CCID Reader 1', @queries[1].reader_name
  end
  
  def test_ack_changes
    @queries.ack_changes
    
    assert_equal Set.new([:ignore]), @queries[0].current_state
    assert_equal Set.new([:present, :unpowered]), @queries[1].current_state
  end
  
  def test_invalid_indexes    
    [[5, IndexError], [2, IndexError], [nil, TypeError]].each do |test_case|
      assert_raise test_case.last, test_case.inspect do
        @queries[test_case.first]
      end
    end
  end
end
