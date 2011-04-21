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
  if FFI::Platform.mac?
    # 64-bit MacOS is different from 64-bit Linux.
    Word = :uint32
  else
    Word = :ulong
  end

  # Used to synthesize pointers to unsigned integers.
  class WordPtr < FFI::Struct
    # NOTE: this hack is necessary because FFI::Pointer can only read signed
    #        values right now (FFI 0.5.3).
    layout :value, Word
  end

  # Used to obtain information and state changes about all PC/SC readers.
  class ReaderStateQuery < FFI::Struct
    layout :reader_name, :pointer,
           :user_data, :pointer,
           :current_state, Word,
           :event_state, Word,
           :atr_length, Word,
           :atr, [:char, Consts::MAX_ATR_SIZE]
  end
  
  # Low-level protocol information for APDU transmission and reception.
  class IoRequest < FFI::Struct
    layout :protocol, Word,
           :pci_length, Word
  end
  
  # Protocol enum members, indexed by their numeric value.
  PROTOCOLS = Protocol.to_h.invert

  # Global variables for IoRequests for protocols T=0, T=1, and RAW.
  begin
    PCI_T0 = attach_variable :pci_t0, 'g_rgSCardT0Pci', IoRequest
    PCI_T1 = attach_variable :pci_t1, 'g_rgSCardT1Pci', IoRequest
    PCI_RAW = attach_variable :pci_raw, 'g_rgSCardRawPci', IoRequest
  rescue
    # Couldn't find the global variables, so we must be on Windows.
    
    # TODO(costan): figure out the names of the Windows global variables
  end
end  # module Smartcard::PCSC::FFILib

end  # namespace Smartcard::PCSC
