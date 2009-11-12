# The protocol used to talk to ISO7816 smart-cards in IBM JCOP simulators.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT

require 'socket'

# :nodoc: namespace
module Smartcard::Iso


# Stubs out the methods that can be implemented by the serving logic in a
# JCOP remote server. Serving logic classes should mix in this module, to
# avoid having unimplemented methods.
module JcopRemoteServingStubs
  # Called when a client connection accepted.
  #
  # This method serves as a notification to the serving logic implementation.
  # Its return value is discarded.
  def connection_start
    nil
  end
  
  # Called when a client connection is closed.
  #
  # This method serves as a notification to the serving logic implementation.
  # Its return value is discarded.
  def connection_end
    nil
  end
  
  # Serving logic handling an APDU exchange.
  #
  # :call-seq:
  #   logic.exchange_apdu(apdu) -> array
  #
  # The |apdu| parameter is the request APDU, formatted as an array of
  # integers between 0 and 255. The method should return the response APDU,
  # formatted in a similar manner.  
  def exchange_apdu(apdu)
    # Dumb implementation that always returns OK.
    [0x90, 0x00]
  end
  
  # The smartcard's ATR.
  def card_atr
    # ATR from the card simulator in JCOP 3.2.7.
    [0x3B, 0xF8, 0x13, 0x00, 0x00, 0x81, 0x31, 0xFE, 0x45, 0x4A, 0x43, 0x4F,
     0x50, 0x76, 0x32, 0x34, 0x31, 0xB7].pack('C*')
  end
end  # module JcopRemoteServingStubs
    

# A server for the JCOP simulator protocol.
#
# The JCOP simulator protocol is generally useful when talking to a real JCOP
# simulator. This server is only handy for testing, and for forwarding
# connections (JCOP's Eclipse plug-in makes the simulator listen to 127.0.0.1,
# and sometimes you want to use it from another box).
class JcopRemoteServer
  include JcopRemoteProtocol  
  
  # Creates a new JCOP server.
  #
  # The options hash supports the following keys:
  #   port:: the port to serve on
  #   ip:: the IP of the interface to serve on (defaults to all interfaces)
  #
  # If the |serving_logic| parameter is nil, a serving logic implementation
  # must be provided when calling JcopRemoteServer#run. The server will crash
  # otherwise.
  def initialize(options, serving_logic = nil)
    @logic = serving_logic
    @running = false
    @options = options
    @mutex = Mutex.new
  end
  
  # Runs the serving loop indefinitely.
  #
  # This method serves incoming conenctions until #stop is called.
  #
  # If |serving_logic| contains a non-nil value, it overrides any previously
  # specified serving logic implementation. If no implementation is specified
  # when the server is instantiated via JcopRemoteServer#new, one must be
  # passed into |serving_logic|.
  def run(serving_logic = nil)
    @mutex.synchronize do
      @logic ||= serving_logic
      @serving_socket = serving_socket @options
      @running = true
    end
    loop do
      break unless @mutex.synchronize { @running }
      begin
        client_socket, client_address = @serving_socket.accept
      rescue
        # An exception will occur if the socket is closed
        break
      end
      @logic.connection_start
      loop do        
        break unless @mutex.synchronize { @running }
        break unless process_request client_socket
      end
      client_socket.close rescue nil
      @logic.connection_end  # implemented by subclass
    end
    @mutex.synchronize do
      @serving_socket.close if @serving_socket
      @serving_socket = nil
    end
  end

  # Stops the serving loop.
  def stop
    @mutex.synchronize do
      if @running
        @serving_socket.close rescue nil
        @serving_socket = nil
        @running = false
      end
    end
    
    # TODO(costan): figure out a way to let serving logic reach this directly.
  end  
  
  # Creates a socket listening to incoming connections to this server.
  # 
  # :call-seq:
  #   server.serving_socket(options) -> Socket
  #
  # The |options| parameter supports the same keys as the options parameter
  # of JcopRemoteServer#new.
  #
  # Returns a Socket configured to accept incoming connections. 
  def serving_socket(options)
    port = options[:port] || 0
    interface_ip = options[:ip] || '0.0.0.0'
    socket = Zerg::Support::SocketFactory.socket :in_addr => interface_ip,
        :in_port => port, :no_delay => true, :reuse_addr => true
    socket.listen
    socket
  end
  private :serving_socket

  # Performs a request/response cycle.
  #
  # :call-seq:
  #   server.process_request(socket) -> Boolean
  #
  # Returns true if the server should do another request/response cycle, or
  # false if this client indicated it's done talking to the server.
  def process_request(socket)
    return false unless request = recv_message(socket)
    
    case request[:type]
    when 0
      # Wait for card (no-op, happened when the client connected) and return
      # card ATR.
      send_message socket, :type => 0, :node => 0,
                           :data => @logic.card_atr.unpack('C*')
    when 1
      # APDU exchange; the class' bread and butter
      response = @logic.exchange_apdu request[:data]
      send_message socket, :type => 1, :node => 0, :data => response
    else
      send_message socket, :type => request[:type], :node => 0,
                           :data => @logic.card_atr.unpack('C*')
    end
  end
  private :process_request    
end  # module JcopRemoteServer

end  # namespace Smartcard::Iso
