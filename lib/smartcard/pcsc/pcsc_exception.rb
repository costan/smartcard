# Contains information about an exception at the PC/SC layer.
class Smartcard::PCSC::Exception  < RuntimeError
  def initialize(error_status)
    @pcsc_status = error_status
    super error_status.to_s
  end
  
  # The PC/SC error status that caused this error.
  attr_reader :pcsc_status
end
