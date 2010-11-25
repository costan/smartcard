# Connects Ruby to a smart-card in a PC/SC reader (wraps SCARDHANDLE).
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2009 Massachusetts Institute of Technology
# License:: MIT

require 'set'

# :nodoc: namespace
module Smartcard::PCSC
  
  
# Connects a smart-card in a PC/SC reader to the Ruby world.
class Card
  # Establishes a connection to the card in a PC/SC reader.
  #
  # The first connection will power up the card and perform a reset on it.
  #
  # Args:
  #   context:: the Smartcard::PCSC::Context for the PC/SC resource manager
  #   reader_name:: friendly name of the reader to connect to; reader names can
  #                 be obtained from Smartcard::PCSC::Context#readers 
  #   sharing_mode:: whether a shared or exclusive lock will be requested on the
  #                  reader; the possible values are +:shared+, +:exclusive+ and
  #                  +:direct+ (see the SCARD_SHARE_ constants in the PC/SC API) 
  #   preferred_protocols:: the desired communication protocol; the possible
  #                         values are +:t0+, +:t1+, +:t15+, +:raw+, and +:any+
  #                         (see the SCARD_PROTOCOL_ constants in the PC/SC API)
  def initialize(context, reader_name, sharing_mode = :exclusive,
                 preferred_protocols = :any)
    handle_ptr = FFILib::WordPtr.new
    protocol_ptr = FFILib::WordPtr.new
    status = FFILib.card_connect context._handle, reader_name, sharing_mode,
                                 preferred_protocols, handle_ptr, protocol_ptr
    raise Smartcard::PCSC::Exception, status unless status == :success
    
    @context = context
    @sharing_mode = sharing_mode
    @_handle = handle_ptr[:value]    
    set_protocol FFILib::Protocol[protocol_ptr[:value]]
  end
  
  # Updates internal buffers to reflect a change in the communication protocol. 
  def set_protocol(protocol)
    @protocol = protocol
    
    case protocol
    when :t0
      @send_pci = @recv_pci = FFILib::PCI_T0
    when :t1
      @send_pci = @recv_pci = FFILib::PCI_T1
    when :raw
      @send_pci = @recv_pci = FFILib::PCI_RAW
    else
      reconnect sharing_mode, guess_protocol_from_atr, :leave
      return self      
    end
    
    # Windows really doesn't like a receiving IoRequest.
    if FFI::Platform.windows? || FFI::Platform.mac?
      @recv_pci = nil
    end
    self
  end
  private :set_protocol
  
  # Reconnects to the smart-card, potentially using a different protocol.
  #
  # Args:
  #   sharing_mode:: whether a shared or exclusive lock will be requested on the
  #                  reader; the possible values are +:shared+, +:exclusive+ and
  #                  +:direct+ (see the SCARD_SHARE_ constants in the PC/SC API) 
  #   preferred_protocols:: the desired communication protocol; the possible
  #                         values are +:t0+, +:t1+, +:t15+, +:raw+, and +:any+
  #                         (see the SCARD_PROTOCOL_ constants in the PC/SC API)  
  #   disposition:: what to do with the smart-card right before disconnecting;
  #                 the possible values are +:leave+, +:reset+, +:unpower+, and
  #                 +:eject+ (see the SCARD_*_CARD constants in the PC/SC API)
  def reconnect(sharing_mode = :exclusive, preferred_protocols = :any,
                disposition = :leave)
    protocol_ptr = FFILib::WordPtr.new
    status = FFILib.card_reconnect @_handle, sharing_mode,
        preferred_protocols, disposition, protocol_ptr
    raise Smartcard::PCSC::Exception, status unless status == :success
  
    @sharing_mode = sharing_mode
    set_protocol FFILib::Protocol[protocol_ptr[:value]]
  end
  
  # Disconnects from the smart-card.
  #
  # Future method calls on this object will raise PC/SC errors.
  #
  # Args:
  #   disposition:: what to do with the smart-card right before disconnecting;
  #                 the possible values are +:leave+, +:reset+, +:unpower+, and
  #                 +:eject+ (see the SCARD_*_CARD constants in the PC/SC API)
  def disconnect(disposition = :leave)
    status = FFILib.card_disconnect @_handle, disposition
    raise Smartcard::PCSC::Exception, status unless status == :success

    @_handle = nil
    @protocol = nil
  end

  # Starts a transaction, obtaining an exclusive lock on the smart-card.
  def begin_transaction
    status = FFILib.begin_transaction @_handle
    raise Smartcard::PCSC::Exception, status unless status == :success    
  end
  
  # Ends a transaction started with begin_transaction.
  #
  # The calling application must be the owner of the previously started
  # transaction or an error will occur.
  #
  # Args:
  #   disposition:: what to do with the smart-card after the transaction; the
  #                 possible values are +:leave+, +:reset+, +:unpower+, and
  #                 +:eject+ (see the SCARD_*_CARD constants in the PC/SC API)
  def end_transaction(disposition = :leave)
    status = FFILib.end_transaction @_handle, disposition
    raise Smartcard::PCSC::Exception, status unless status == :success
  end
  
  # Performs a block inside a transaction, with an exclusive smart-card lock.
  #
  # Args:
  #   disposition:: what to do with the smart-card after the transaction; the
  #                 possible values are +:leave+, +:reset+, +:unpower+, and
  #                 +:eject+ (see the SCARD_*_CARD constants in the PC/SC API)
  def transaction(disposition = :leave)
    begin_transaction
    yield
    end_transaction disposition
  end
  
  
  def [](attribute_name)
    length_ptr = FFILib::WordPtr.new
    status = FFILib.get_attrib @_handle, attribute_name, nil, length_ptr
    raise Smartcard::PCSC::Exception, status unless status == :success

    value_ptr = FFI::MemoryPointer.new :char, length_ptr[:value]
    begin
      status = FFILib.get_attrib @_handle, attribute_name, value_ptr,
                                 length_ptr
      raise Smartcard::PCSC::Exception, status unless status == :success
  
      value_ptr.get_bytes 0, length_ptr[:value]
    ensure
      value_ptr.free
    end      
  end
  
  # Sets the value of an attribute in the interface driver.
  #
  # The interface driver may not implement all possible attributes.
  #
  # Args:
  #   attribute_name:: the attribute to be set; possible values are the members
  #                    of Smartcard::PCSC::FFILib::Attribute, for example
  #                    +:vendor_name+)
  #   value:: string containing the value bytes to be assigned to the attribute
  def []=(attribute_name, value)
    value_ptr = FFI::MemoryPointer.from_string value
    begin
      status = FFILib.set_attrib @_handle, attribute_name, value_ptr,
                                 value.length
      raise Smartcard::PCSC::Exception, status unless status == :success    
      value
    ensure
      value_ptr.free    
    end
  end
  
  # Sends an APDU to the smart card, and returns the card's response.
  #
  # Args:
  #   send_data:: string containing the APDU bytes to be sent to the card
  #   receive_buffer_size: the maximum number of bytes that can be received  
  def transmit(data, receive_buffer_size = 65546)
    send_ptr = FFI::MemoryPointer.from_string data
    recv_ptr = FFI::MemoryPointer.new receive_buffer_size
    recv_size_ptr = FFILib::WordPtr.new
    recv_size_ptr[:value] = receive_buffer_size 
    begin
      status = FFILib.transmit @_handle, @send_pci, send_ptr, data.length,
                               @recv_pci, recv_ptr, recv_size_ptr
      raise Smartcard::PCSC::Exception, status unless status == :success    
      recv_ptr.get_bytes 0, recv_size_ptr[:value]
    ensure
      send_ptr.free
      recv_ptr.free
    end    
  end
  
  # Sends a interface driver command for the smart-card reader.
  #
  # This method is useful for creating client side reader drivers for functions
  # like PIN pads, biometrics, or other smart card reader extensions that are
  # not normally handled by the PC/SC API.
  #
  # Args:
  #   code:: control code for the operation; a driver-specific integer
  #   data:: string containing the data bytes to be sent to the driver
  #   receive_buffer_size:: the maximum number of bytes that can be received
  #
  # Returns a string containg the response bytes.
  def control(code, data, receive_buffer_size = 4096)
    # NOTE: In general, I tried to avoid specifying receive buffer sizes. This
    #       is the only case where that is impossible to achieve, because there
    #       is no well-known maximum buffer size, and the SCardControl call is
    #       not guaranteed to be idempotent, so it's not OK to re-issue it after
    #       guessing a buffer size works out.
    send_ptr = FFI::MemoryPointer.from_string data
    recv_ptr = FFI::MemoryPointer.new receive_buffer_size
    recv_size_ptr = FFILib::WordPtr.new
    recv_size_ptr[:value] = receive_buffer_size 
    begin
      status = FFILib.card_control @_handle, code, send_ptr, data.length,
                                   recv_ptr, receive_buffer_size, recv_size_ptr
      raise Smartcard::PCSC::Exception, status unless status == :success    
      recv_ptr.get_bytes 0, recv_size_ptr[:value]
    ensure
      send_ptr.free
      recv_ptr.free
    end
  end
  
  # Assorted information about this smart-card.
  # 
  # Returns a hash with the following keys:
  #   :state:: reader/card status, as a Set of symbols; the possible values are
  #            +:present+, +:swallowed+, +:absent+, +:specific+, and +:powered+
  #            (see the SCARD_* constants in the PC/SC API)
  #   :protocol:: the protocol established with the card
  #   :atr:: the card's ATR bytes, wrapped in a string
  #   :reader_names:: array of strings containing all the names of the reader
  #                   connected to this smart-card
  def info
    readers_length_ptr = FFILib::WordPtr.new
    state_ptr = FFILib::WordPtr.new
    protocol_ptr = FFILib::WordPtr.new
    atr_ptr = FFI::MemoryPointer.new FFILib::Consts::MAX_ATR_SIZE
    atr_length_ptr = FFILib::WordPtr.new
    atr_length_ptr[:value] = FFILib::Consts::MAX_ATR_SIZE    

    begin
      status = FFILib.card_status @_handle, nil, readers_length_ptr, state_ptr,
          protocol_ptr, atr_ptr, atr_length_ptr
      raise Smartcard::PCSC::Exception, status unless status == :success    

      readers_ptr = FFI::MemoryPointer.new :char, readers_length_ptr[:value]
      begin
        status = FFILib.card_status @_handle, readers_ptr, readers_length_ptr,
            state_ptr, protocol_ptr, atr_ptr, atr_length_ptr
        raise Smartcard::PCSC::Exception, status unless status == :success    
      
        state_word = state_ptr[:value]
        state = Set.new
        FFILib::CardState.to_h.each do |key, mask|
          state << key if (state_word & mask) == mask && mask != 0
        end
        
        { :readers => Context.decode_multi_string(readers_ptr),
          :protocol => FFILib::Protocol[protocol_ptr[:value]],
          :atr => atr_ptr.get_bytes(0, atr_length_ptr[:value]),
          :state => state }
      ensure
        readers_ptr.free
      end
    ensure
      atr_ptr.free
    end
  end
  
  # Returns the first valid protocol listed in the card's ATR.  
  def guess_protocol_from_atr
    atr = info[:atr]
    
    # TODO(costan): proper ATR decoding logic
    atr_protocols = [:t0]

    atr_protocols.first
  end
  private :guess_protocol_from_atr
  
  # The low-level _SCARDHANDLE_ data.
  #
  # This should not be used by client code.
  attr_reader :_handle
  
  # The communication protocol in use with this smart-card.
  attr_reader :protocol
  
  # The sharing mode for this smart-card session. (:shared or :exclusive)
  attr_reader :sharing_mode
end  # class Smartcard::PCSC::Card

end  # namespace Smartcard::PCSC
