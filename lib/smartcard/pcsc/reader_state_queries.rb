# Connects Ruby to the PC/SC resource manager (wraps SCARDCONTEXT).
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2009 Massachusetts Institute of Technology
# License:: MIT

require 'set'

# :nodoc: namespace
module Smartcard::PCSC


# A continuous array of reader state queries.
class ReaderStateQueries
  include Enumerable

  # Creates an array of reader state queries.
  #
  # The states are unusable until they are assigned reader names by calling
  # set_reader_name_of.
  def initialize(num_states)
    @_buffer = FFI::MemoryPointer.new :char,
                                      FFILib::ReaderStateQuery.size * num_states
    @queries = (0...num_states).map do |i|
      FFILib::ReaderStateQuery.new @_buffer + FFILib::ReaderStateQuery.size * i
    end
  end

  # A query in the array.
  def [](index)
    raise TypeError unless index.kind_of? Numeric
    raise IndexError if index >= @queries.length
    @queries[index]
  end

  # Mandatory for Enumerable mixin
  def each(&block)
    @queries.each &block
  end

  # The number of queries in the array.
  def length
    @queries.length
  end

  # Updates all the queries to acknowledge status changes.
  #
  # This is a convenience method intended to be called after
  # Smartcard::PCSC::Context#wait_for_status_change.
  def ack_changes
    @queries.each { |query| query[:current_state] = query[:event_state] }
  end

  # Convenience method that selects queries that indicate reader state changes.
  #
  # Use this method to perform actions on the relevant readers after calling
  # Smartcard::PCSC::Context#wait_for_status_change.
  #
  #==== Examples
  #
  # queries.with_changes.each do |q|
  #   puts "changed: #{q.reader_name}"
  # end
  #
  def with_changes
    @queries.select { |query| query.changed? }
  end

  # Called by FFI::AutoPointer to release the reader states array.
  #
  # This should not be called by client code.
  def self._release_states(pointer)
    pointer.free
  end

  # The low-level _SCARD_READERSTATE_ data.
  #
  # This should not be used by client code.
  attr_reader :_buffer
end  # class Smartcard::PCSC::ReaderStates


# :nodoc: extends the reader states with nice accessors
class FFILib::ReaderStateQuery
  # The query's current state.
  #
  # Smartcard::PCSC::Context#wait_for_status_change blocks while the reader
  # state equals this.
  #
  # The value is a Set whose elements are FFILib::CardState members.
  def current_state
    FFILib::ReaderStateQuery.unpack_state self[:current_state]
  end

  # Changes the query's current state.
  #
  # Smartcard::PCSC::Context#wait_for_status_change blocks while the reader
  # state equals this.
  #
  # The new value can be a symbol in FFILib::CardState, or an Enumerable
  # containing such symbols.
  def current_state=(new_state)
    self[:current_state] = FFILib::ReaderStateQuery.pack_state new_state
  end

  # The query's event state.
  #
  # Smartcard::PCSC::Context#wait_for_status_change updates this value before it
  # returns.
  #
  # The value is a Set whose elements are FFILib::CardState members.
  def event_state
    FFILib::ReaderStateQuery.unpack_state self[:event_state]
  end

  # Changes the query's event state.
  #
  # Smartcard::PCSC::Context#wait_for_status_change updates this value before it
  # returns.
  #
  # The new value can be a symbol in FFILib::CardState, or an Enumerable
  # containing such symbols.
  def event_state=(new_state)
    self[:event_state] = FFILib::ReaderStateQuery.pack_state new_state
  end

  # Returns true if this query indicates that the reader's state has changed.
  def changed?
    self.event_state.include? :changed
  end

  # The ATR of the smart-card in the query's reader.
  #
  # Smartcard::PCSC::Context#wait_for_status_change updates this value before it
  # returns.
  #
  # The value is a string containing the ATR bytes.
  def atr
    self[:atr].to_ptr.get_bytes 0, self[:atr_length]
  end

  # Changes the smart-card ATR stored in the query.
  #
  # Smartcard::PCSC::Context#wait_for_status_change updates this value before it
  # returns.
  #
  # The new value should be a string containing the ATR bytes.
  def atr=(new_atr)
    if new_atr.length > max_length = FFILib::Consts::MAX_ATR_SIZE
      raise ArgumentError, "ATR above maximum length of #{max_length}"
    end

    self[:atr_length] = new_atr.length
    self[:atr].to_ptr.put_bytes 0, new_atr, 0, new_atr.length
  end

  # The name of the reader referenceed by this query.
  #
  # Smartcard::PCSC::Context#wait_for_status_change never changes this value.
  def reader_name
    self[:reader_name].read_string
  end

  # Changes the name of the reader referenceed by this query.
  #
  # Smartcard::PCSC::Context#wait_for_status_change never changes this value.
  def reader_name=(new_name)
    self[:reader_name].free if self[:reader_name].kind_of? FFI::MemoryPointer
    self[:reader_name] = FFI::MemoryPointer.from_string new_name
  end

  # Packs an unpacked card state (symbol or set of symbols) into a number.
  #
  # This should not be used by client code.
  def self.pack_state(unpacked_state)
    if unpacked_state.kind_of? Enumerable
      state = 0
      unpacked_state.each do |symbol_bit_or_number|
        if FFILib::CardState[symbol_bit_or_number]
          state |= FFILib::CardState[symbol_bit_or_number]
        else
          state |= symbol_bit_or_number
        end
      end
      return state
    end
    FFILib::CardState[unpacked_state]
  end

  # Unpacks a numeric card state into a Set of symbols.
  #
  # The returned Set may also have an Integer in it, if any of the bits set in
  # the packed state are not covered by the mapping in FFILib::CardState.
  def self.unpack_state(packed_state)
    state = Set.new
    FFILib::CardState.to_h.each do |symbol, mask|
      next if mask == 0
      if (packed_state & mask) == mask
        state << symbol
        packed_state ^= mask
      end
    end
    state << packed_state if packed_state != 0
    state
  end
end

end  # namespace Smartcard::PCSC
