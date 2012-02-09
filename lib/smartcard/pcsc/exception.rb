# Contains information about an exception at the PC/SC layer.
class Smartcard::PCSC::Exception  < RuntimeError
  def initialize(error_status)
    @pcsc_status_code = 2**32 + error_status
    @pcsc_status = Smartcard::PCSC::FFILib::Status.find @pcsc_status_code
    
    super "#{@pcsc_status} (0x#{@pcsc_status_code.to_s(16)})"
  end
  
  # Symbol for the PC/SC error status that caused this error.
  attr_reader :pcsc_status
  
  # The PC/SC error status that caused this error, as a number.
  attr_reader :pcsc_status_code
end
