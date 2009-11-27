# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT

require 'smartcard'

require 'test/unit'


class ContextTest < Test::Unit::TestCase
  def setup
    @context = Smartcard::PCSC::Context.new :system
  end
  
  def teardown
    @context.release    
  end

  def test_reader_groups
    groups = @context.reader_groups
    assert_operator groups, :kind_of?, Enumerable,
                    'reader_groups should produce an array'
    assert_operator groups.length, :>=, 1, 'reader_groups should be non-empty'    
  end
  
  def test_readers_without_groups
    readers = @context.readers
    _check_readers readers
  end
  
  def test_readers_with_groups
    readers = @context.readers @context.reader_groups
    _check_readers readers
  end
  
  def _check_readers(readers)
    assert_operator readers, :kind_of?, Enumerable,
                    'readers (without argument) should produce an array'
    readers.each do |reader|
      assert_operator reader, :kind_of?, String,
                      'each reader name should be a string'
    end    
  end
  
  def test_wait_for_status_change
    readers = @context.readers
    queries = Smartcard::PCSC::ReaderStateQueries.new readers.length
    readers.each_with_index do |name, index|
      queries[index].reader_name = name
      queries[index].current_state = :unknown
    end
    
    @context.wait_for_status_change queries
  
    readers.each_with_index do |name, index|
      query = queries[index]
      assert_equal name, query.reader_name,
                   'Reader name changed during wait_for_status_change'
      assert_operator query.atr, :kind_of?, String, 'ATR should be a string'
      assert_operator query.event_state, :include?, :changed,
                      'event_state must have changed from :unknown'
    end
  end
end
