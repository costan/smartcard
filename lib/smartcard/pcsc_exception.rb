# Contains information about an exception at the PC/SC layer.
class Smartcard::PCSC::Exception  
  # The error number returned by the failed PC/SC function call. Should be one of the Smartcard::PCSC::SCARD_E_ constants.
  attr_reader :errno
end
