# Declaration for the module enclosing the PC/SC FFI hooks.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2009 Massachusetts Institute of Technology
# License:: MIT

require 'ffi'

# :nodoc: namespace
module Smartcard::PCSC


# FFI to the native PC/SC libraries.
module FFILib
  extend FFI::Library
  # NOTE: the information is hacked together from the PCSClite headers reader.h,
  #       winscard.h, and pcsclite.h, available in /usr/include/PCSC  
  
  if FFI::Platform.windows?
    ffi_lib 'winscard'
  elsif FFI::Platform.mac?
    ffi_lib '/System/Library/Frameworks/PCSC.framework/PCSC'
  else
    ffi_lib 'pcsclite'
  end
end

end  # namespace Smartcard::PCSC

# Add Fixnum#ord to Ruby 1.8.6's Fixnum, if it's not already there. 
unless 0.respond_to?(:ord) or '0'.respond_to?(:ord)
  # :nodoc: all
  class Fixnum
    def ord
      self
    end
  end
end