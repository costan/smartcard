# Common code for talking to ISO7816 smart-cards on all transports.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT

# :nodoc: namespace
module Smartcard::Iso


# Module intended to be mixed into transport implementations to mediate between
# a high level format for ISO7816-specific APDUs and the wire-level APDU 
# request and response formats.
#
# The mix-in calls exchange_apdu in the transport implementation. It supplies
# the APDU data as an array of integers between 0 and 255, and expects a
# response in the same format.
module IsoCardMixin  
  # APDU exchange with the ISO7816 card, raising an exception if the return
  # code is not success (0x9000).
  #
  # :call_seq:
  #   transport.iso_apdu!(apdu_data) -> array
  #
  # The apdu_data should be in the format expected by
  # IsoCardMixin#serialize_apdu. Returns the response data, if the response
  # status indicates success (0x9000). Otherwise, raises an exeception.
  def iso_apdu!(apdu_data)
    response = self.iso_apdu apdu_data
    return response[:data] if response[:status] == 0x9000
    raise "JavaCard response has error status 0x#{'%04x' % response[:status]}"
  end

  # Performs an APDU exchange with the ISO7816 card.
  #
  # :call-seq:
  #   transport.iso_apdu(apdu_data) -> hash
  #
  # The apdu_data should be in the format expected by
  # IsoCardMixin#serialize_apdu. The response will be as specified in
  # IsoCardMixin#deserialize_response.
  def iso_apdu(apdu_data)
    response = self.exchange_apdu IsoCardMixin.serialize_apdu(apdu_data)
    IsoCardMixin.deserialize_response response
  end
  
  # Serializes an APDU for wire transmission.
  #
  # :call-seq:
  #   transport.wire_apdu(apdu_data) -> array
  #
  # The following keys are recognized in the APDU hash:
  #   cla:: the CLA byte in the APDU (optional, defaults to 0) 
  #   ins:: the INS byte in the APDU -- the first byte seen by a JavaCard applet
  #   p12:: 2-byte array containing the P1 and P2 bytes in the APDU
  #   p1, p2:: the P1 and P2 bytes in the APDU (optional, both default to 0)
  #   data:: the extra data in the APDU (optional, defaults to nothing)
  def self.serialize_apdu(apdu_data)
    raise 'Unspecified INS in apdu_data' unless apdu_data[:ins]
    apdu = [ apdu_data[:cla] || 0, apdu_data[:ins] ]
    if apdu_data[:p12]
      unless apdu_data[:p12].length == 2
        raise "Malformed P1,P2 - #{apdu_data[:p12]}"
      end
      apdu += apdu_data[:p12]
    else
      apdu << (apdu_data[:p1] || 0)
      apdu << (apdu_data[:p2] || 0)
    end
    if apdu_data[:data]
      apdu << apdu_data[:data].length
      apdu += apdu_data[:data]
    else
      apdu << 0
    end
    apdu
  end
  
  # De-serializes a ISO7816 response APDU.
  # 
  # :call-seq:
  #   transport.deserialize_response(response) -> hash
  #
  # The response contains the following keys:
  #   status:: the 2-byte status code (e.g. 0x9000 is OK)
  #   data:: the additional data in the response
  def self.deserialize_response(response)
    { :status => response[-2] * 256 + response[-1], :data => response[0...-2] }
  end  
end  # module IsoCardMixin

end  # module Smartcard::Iso
