# Exception indicating an error code in an ISO-7618 response APDU.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2009 Massachusetts Institute of Technology
# License:: MIT

# :nodoc: namespace
module Smartcard::Iso
  

# Indicates an error code in an ISO-7618 response APDU.
#
# This exception should be raised if the response obtained from iso_apdu has an
# error status. When raising the exception, supply the entire response as the
# only argument to raise.
#
# Usage example:
#   response = transport.iso_apdu :ins => 0x12
#   raise Smartcard::Iso::ApduError, response unless response[:status] == 0x9000
class ApduError < RuntimeError
  # The data in the error APDU. 
  attr_accessor :data
  # The error status.
  attr_accessor :status
  
  # Creates a new exception (for raising).
  #
  # Args:
  #   response:: the APDU response (hash with +:data+ and +:status+ keys)
  def initialize(response)
    @data = response[:data]
    @status = response[:status]
    super ApduError.message_for_apdu_response response
  end
  
  # Computes the exception message for an APDU response.
  def self.message_for_apdu_response(response)
    "ISO-7816 response APDU has error status 0x#{'%04x' % response[:status]}" +
        " - #{response[:data].map { |ch| '%02x' % ch }.join(' ')}"
  end
end  # class Smartcard::Iso::ApduError

end  # namespace Smartcard::Iso
