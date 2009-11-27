# Connects Ruby to the PC/SC resource manager (wraps SCARDCONTEXT).
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2009 Massachusetts Institute of Technology
# License:: MIT

# :nodoc: namespace
module Smartcard::PCSC
  
  
# Connects Ruby to the PC/SC resource manager.
class Context
  # Creates an application context connecting to the PC/SC resource manager.
  #
  # A context is required to access every piece of PC/SC functionality.
  #
  # Args:
  #   scope:: the scope of the smart-card connection; valid values are :system,
  #           :user, and :terminal (see the SCARD_SCOPE_ constants in the PC/SC
  #           API)
  def initialize(scope = :system)
    handle_ptr = FFILib::WordPtr.new
    status = FFILib.establish_context scope, nil, nil, handle_ptr
    raise Smartcard::PCSC::Exception, status unless status == :success
    
    @_handle = handle_ptr[:value]
  end
  
  # Releases this PC/SC context.
  #
  # Future calls to this context's methods will raise errors.
  #
  # Returns the now-released PC/SC context.
  def release
    return unless @_handle
    status = FFILib.release_context @_handle
    raise Smartcard::PCSC::Exception, status unless status == :success
    
    @_handle = nil
    self
  end

  # Returns +true+ if this PC/SC context is still valid, and +false+ otherwise.
  def valid?
    FFILib.is_valid_context(@_handle) == :success
  end
  
  # An array containing the currently available reader groups on the system.
  def reader_groups
    # Get the length of the readers concatenated string.
    length_ptr = FFILib::WordPtr.new
    status = FFILib.list_reader_groups @_handle, nil, length_ptr
    raise Smartcard::PCSC::Exception, status unless status == :success

    # Get the readers concatenated string.
    combined_length = length_ptr[:value]
    groups_ptr = FFI::MemoryPointer.new :char, combined_length
    begin
      status = FFILib.list_reader_groups @_handle, groups_ptr, length_ptr
      raise Smartcard::PCSC::Exception, status unless status == :success
      
      Context.decode_multi_string groups_ptr
    ensure
      groups_ptr.free  
    end
  end
  
  # An array containing the currently available readers in the system.
  #
  # Args:
  #   groups:: restrict the readers array to the given groups
  def readers(groups = [])
    groups_string = groups.join("\0") + "\0\0"
    groups_ptr = FFI::MemoryPointer.from_string groups_string
    
    # Get the length of the readers concatenated string.
    length_ptr = FFILib::WordPtr.new
    begin
      status = FFILib.list_readers @_handle, groups_ptr, nil, length_ptr
      raise Smartcard::PCSC::Exception, status unless status == :success
  
      # Get the readers concatenated string.
      combined_length = length_ptr[:value]
      readers_ptr = FFI::MemoryPointer.new :char, combined_length
      begin
        status = FFILib.list_readers @_handle, groups_ptr, readers_ptr,
                                     length_ptr
        raise Smartcard::PCSC::Exception, status unless status == :success
        
        Context.decode_multi_string readers_ptr
      ensure
        readers_ptr.free
      end
    ensure
      groups_ptr.free
    end
  end
  
  # Queries smart-card readers, blocking until a state change occurs.
  #
  # Args:
  #   queries:: Smartcard::PCSC::ReaderStateQueries instance
  #   timeout:: maximum ammount of time (in milliseconds) to block; the default
  #             value blocks forever
  #
  # The method blocks until the state of one of the queried readers becomes
  # different from the query's current_state. The new state is stored in the
  # query's event_state.  
  def wait_for_status_change(queries, timeout = FFILib::Consts::INFINITE)
    status = FFILib.get_status_change @_handle, timeout, queries._buffer,
                                      queries.length
    raise Smartcard::PCSC::Exception, status unless status == :success
    
    queries
  end
  
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
  def card(reader_name, sharing_mode = :exclusive, preferred_protocols = :any)
    Card.new self, reader_name, sharing_mode, preferred_protocols
  end
  
  # Turns a multi-string (concatenated C strings) into an array of Ruby strings.
  #
  # Args:
  #   strings_ptr:: FFI::Pointer to the buffer containing the multi-string
  def self.decode_multi_string(strings_ptr)
    strings_bytes = strings_ptr.get_bytes 0, strings_ptr.size
    strings, next_string = [], ''
    strings_bytes.each_byte do |byte|
      if byte.ord == 0
        break if next_string == ''
        strings << next_string
        next_string = ''
      else
        next_string << byte
      end
    end
    strings
  end
  
  # The low-level _SCARDCONTEXT_ data.
  #
  # This should not be used by client code.
  attr_reader :_handle
end  # class Smartcard::PCSC::Context

end  # namespace Smartcard::PCSC
