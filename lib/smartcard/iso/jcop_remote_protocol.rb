# The protocol used to talk to ISO7816 smart-cards in IBM JCOP simulators.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT

# :nodoc: namespace
module Smartcard::Iso


# Mixin implementing the JCOP simulator protocol.
#
# The (pretty informal) protocol specification is contained in the JavaDocs for
# the class com.ibm.jc.terminal.RemoteJCTerminal and should be easy to find by
# http://www.google.com/search?q=%22com.ibm.jc.terminal.RemoteJCTerminal%22  
module JcopRemoteProtocol
  # Encodes and sends a JCOP simulator message to a TCP socket.
  #
  # The message must contain the following keys:
  #   type:: Integer expressing the message type (e.g. 1 = APDU exchange)
  #   node:: Integer expressing the node address (e.g. 0 for most purposes)
  #   data:: message payload, as an array of Integers ranging from 0 to 255
  def send_message(socket, message)
    raw_message = [message[:type], message[:node], message[:data].length].
                  pack('CCn') + message[:data].pack('C*')
    socket.send raw_message, 0
  end
  
  # Reads and decodes a JCOP simulator message from a TCP socket.
  # 
  # :call_seq:
  #   client.read_message(socket) -> Hash or nil
  #
  # If the other side of the TCP socket closes the connection, this method
  # returns nil. Otherwise, a Hash is returned, with the format required by the
  # JcopRemoteProtocol#send_message.
  def recv_message(socket)
    header = ''
    while header.length < 4
      begin
        partial = socket.recv 4 - header.length
      rescue  # Abrupt hangups result in exceptions that we catch here.        
        return nil
      end
      return false if partial.length == 0
      header += partial
    end
    message_type, node_address, data_length = *header.unpack('CCn')
    raw_data = ''
    while raw_data.length < data_length
      begin
        partial = socket.recv data_length - raw_data.length
      rescue  # Abrupt hangups result in exceptions that we catch here.
        return nil
      end
      return false if partial.length == 0
      raw_data += partial
    end
    
    return false unless raw_data.length == data_length
    data = raw_data.unpack('C*')
    return { :type => message_type, :node => node_address, :data => data }
  end
end  # module JcopRemoteProtocol

end  # namespace Smartcard::Iso
