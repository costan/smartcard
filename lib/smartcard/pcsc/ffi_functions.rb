# Function declarations for the PC/SC FFI.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2009 Massachusetts Institute of Technology
# License:: MIT

require 'ffi'

# :nodoc: namespace
module Smartcard::PCSC


# FFI to the native PC/SC libraries.
module FFILib
  str_suffix = FFI::Platform.windows? ? 'A' : ''
  attach_function :establish_context, 'SCardEstablishContext',
                  [Scope, :pointer, :pointer, :pointer], Status
  attach_function :release_context, 'SCardReleaseContext', [Word], Status
  attach_function :is_valid_context, 'SCardIsValidContext', [Word], Status  
  attach_function :list_reader_groups, 'SCardListReaderGroups' + str_suffix,
                  [Word, :pointer, :pointer], Status
  attach_function :list_readers, 'SCardListReaders' + str_suffix,
                  [Word, :pointer, :pointer, :pointer], Status
  attach_function :get_status_change, 'SCardGetStatusChange' + str_suffix,
                  [Word, Word, :pointer, Word], Status
  
  attach_function :card_connect, 'SCardConnect' + str_suffix,
                  [Word, :string, Share, Protocol, :pointer, :pointer], Status
  attach_function :card_reconnect, 'SCardReconnect',
                  [Word, Share, Protocol, Disposition, :pointer], Status
  attach_function :card_disconnect, 'SCardDisconnect',
                  [Word, Disposition], Status
  attach_function :begin_transaction, 'SCardBeginTransaction', [Word], Status
  attach_function :end_transaction, 'SCardEndTransaction',
                  [Word, Disposition], Status
  attach_function :get_attrib, 'SCardGetAttrib',
                  [Word, Attribute, :pointer, :pointer], Status
  attach_function :set_attrib, 'SCardSetAttrib',
                  [Word, Attribute, :pointer, Word], Status
  attach_function :transmit, 'SCardTransmit',
                  [Word, IoRequest, :pointer, Word, IoRequest, :pointer,
                   :pointer], Status
  attach_function :card_control, 'SCardControl',
                  [Word, Word, :pointer, Word, :pointer, Word, :pointer], Status
  attach_function :card_status, 'SCardStatus' + str_suffix,
                  [Word, :pointer, :pointer, :pointer, :pointer, :pointer,
                   :pointer], Status
end  # module Smartcard::PCSC::FFILib

end  # namespace Smartcard::PCSC
