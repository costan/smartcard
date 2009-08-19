# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT

require 'smartcard'

require 'test/unit'

require 'rubygems'
require 'flexmock/test_unit'


# Tests JcopRemoteProtocol, JcopRemoteServer, and JcopRemoteTransport.
class JcopRemoteTest < Test::Unit::TestCase
  Protocol = Smartcard::Iso::JcopRemoteProtocol
  Server = Smartcard::Iso::JcopRemoteServer
  Transport = Smartcard::Iso::JcopRemoteTransport
  
  # Serving logic that records what it receives and replays a log.
  class Logic
    include Protocol
    attr_reader :received
    def initialize(responses)
      @responses = responses
      @received = []
    end
    def connection_start
      @received << :start
    end
    def connection_end
      @received << :end
    end
    def exchange_apdu(apdu)
      @received << apdu
      @responses.shift
    end
  end
  
  def setup
    @server = Server.new(:ip => '127.0.0.1', :port => 51995)
    @client = Transport.new :host => '127.0.0.1', :port => 51995
    @old_abort_on_exception = Thread.abort_on_exception
    Thread.abort_on_exception = true
  end
  
  def teardown
    Thread.abort_on_exception = @old_abort_on_exception
    @server.stop
  end

  def test_apdu_exchange
    apdu_request = [0x31, 0x41, 0x59, 0x26, 0x53]
    apdu_response = [0x27, 0x90, 0x00]
    
    logic = Logic.new([apdu_response])
    Thread.new do
      begin
        @server.run logic
      rescue Exception
        print $!, "\n"
        print $!.backtrace.join("\n")
        raise
      end
    end
    Kernel.sleep 0.05  # Wait for the server to start up.
    @client.connect
    assert_equal apdu_response, @client.exchange_apdu(apdu_request)
    @client.disconnect
    Kernel.sleep 0.05  # Wait for the server to process the disconnect.
    assert_equal [:start, apdu_request, :end], logic.received
  end
  
  def test_java_card_integration
    apdu_request = [0x00, 0x31, 0x41, 0x59, 0x00]
    apdu_response = [0x27, 0x90, 0x00]

    logic = Logic.new([apdu_response])
    Thread.new { @server.run logic }
    Kernel.sleep 0.05  # Wait for the server to start up.
    @client.connect
    assert_equal [0x27],
                 @client.iso_apdu!(:ins => 0x31, :p1 => 0x41, :p2 => 0x59)
    @client.disconnect
    Kernel.sleep 0.05  # Wait for the server to process the disconnect.
    assert_equal [:start, apdu_request, :end], logic.received
  end
end
