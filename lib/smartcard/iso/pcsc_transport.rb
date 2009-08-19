# Interface to ISO7816 smart-cards in PC/SC readers.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT

require 'rubygems'
require 'smartcard'

# :nodoc: namespace
module Smartcard::Iso

# Implements the transport layer for a smartcard connected to a PC/SC reader.
class PcscTransport
  include IsoCardMixin
  PCSC = Smartcard::PCSC
  
  def initialize(options)
    @options = options
    @context = nil
    @card = nil
  end

  def exchange_apdu(apdu)
    xmit_apdu_string = apdu.pack('C*')
    result_string = @card.transmit xmit_apdu_string, @xmit_ioreq, @recv_ioreq
    return result_string.unpack('C*')
  end
  
  def connect
    @context = PCSC::Context.new(PCSC::SCOPE_SYSTEM) if @context.nil?
    
    if @options[:reader_name]
      @reader_name = @options[:reader_name]
    else
      # get the first reader      
      readers = @context.list_readers nil
      @reader_name = readers[@options[:reader_index] || 0]
    end
    
    # get the reader's status
    reader_states = PCSC::ReaderStates.new(1)
    reader_states.set_reader_name_of!(0, @reader_name)
    reader_states.set_current_state_of!(0, PCSC::STATE_UNKNOWN)
    @context.get_status_change reader_states, 100
    reader_states.acknowledge_events!
    
    # prompt for card insertion unless that already happened
    if (reader_states.current_state_of(0) & PCSC::STATE_PRESENT) == 0
      puts "Please insert TEM card in reader #{@reader_name}\n"
      while (reader_states.current_state_of(0) & PCSC::STATE_PRESENT) == 0 do
        @context.get_status_change reader_states, PCSC::INFINITE_TIMEOUT
        reader_states.acknowledge_events!
      end
      puts "Card detected\n"
    end
    
    # connect to card
    @card = PCSC::Card.new @context, @reader_name, PCSC::SHARE_EXCLUSIVE,
                           PCSC::PROTOCOL_ANY
    
    # build the transmit / receive IoRequests
    status = @card.status
    @xmit_ioreq = @@xmit_iorequest[status[:protocol]]
    if RUBY_PLATFORM =~ /win/ and (not RUBY_PLATFORM =~ /darwin/)
      @recv_ioreq = nil
    else
      @recv_ioreq = PCSC::IoRequest.new
    end
  end
  
  def disconnect
    unless @card.nil?
      @card.disconnect PCSC::DISPOSITION_LEAVE
      @card = nil
    end
    unless @context.nil?
      @context.release
      @context = nil
    end
  end  

  def to_s
    "#<PC/SC Terminal: disconnected>" if @card.nil?
    "#<PC/SC Terminal: #{@reader_name}>"
  end
  
  @@xmit_iorequest = {
    Smartcard::PCSC::PROTOCOL_T0 => Smartcard::PCSC::IOREQUEST_T0,
    Smartcard::PCSC::PROTOCOL_T1 => Smartcard::PCSC::IOREQUEST_T1,
  }
end  # class PcscTransport

end  # module Smartcard::Iso