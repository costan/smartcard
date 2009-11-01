# Interface to ISO7816 smart-cards in IBM JCOP simulators.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT

require 'socket'

# :nodoc: namespace
module Smartcard::Iso


# Implements the transport layer for a JCOP simulator instance.
class JcopRemoteTransport
  include IsoCardMixin
  include JcopRemoteProtocol
  
  # Creates a new unconnected transport for a JCOP simulator serving TCP/IP.
  #
  # The options parameter must have the following keys:
  #   host:: the DNS name or IP of the host running the JCOP simulator
  #   port:: the TCP/IP port of the JCOP simulator server
  def initialize(options)
    @host, @port = options[:host], options[:port]
    @socket = nil
    @atr = nil
  end
  
  # :nodoc: standard transport method
  def exchange_apdu(apdu)
    send_message @socket, :type => 1, :node => 0, :data => apdu
    loop do
      message = recv_message @socket
      return message[:data] if message[:type] == 1
    end
  end
  
  # :nodoc: standard transport method
  def card_atr
    @atr
  end

  # Makes a transport-level connection to the TEM.
  def connect
    begin
      Socket.getaddrinfo(@host, @port, Socket::AF_INET,
                         Socket::SOCK_STREAM).each do |addr_info|
        begin
          @socket = Socket.new(addr_info[4], addr_info[5], addr_info[6])
          @socket.connect Socket.pack_sockaddr_in(addr_info[1], addr_info[3])
          break
        rescue
          @socket = nil
        end
      end  
      raise 'Connection refused' unless @socket
      
      # Wait for the card to be inserted.
      send_message @socket, :type => 0, :node => 0, :data => [0, 1, 0, 0]
      message = recv_message @socket
      @atr = message[:data].pack('C*')
    rescue Exception
      @socket = nil
      raise
    end
  end

  # Breaks down the transport-level connection to the TEM.
  def disconnect
    if @socket
      @socket.close
      @socket = nil
      @atr = nil
    end
  end
  
  def to_s
    "#<JCOP Remote Terminal: disconnected>" if @socket.nil?
    "#<JCOP Remote Terminal: #{@host}:#{@port}>"
  end  
end  # class JcopRemoteTransport 

end  # module Smartcard::Iso
