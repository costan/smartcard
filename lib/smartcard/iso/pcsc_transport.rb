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
    @atr = nil
  end

  def exchange_apdu(apdu)
    xmit_apdu_string = apdu.pack('C*')
    result_string = @card.transmit xmit_apdu_string
    return result_string.unpack('C*')
  end
  
  def card_atr
    @atr
  end
  
  def connect
    @context = PCSC::Context.new if @context.nil?
    
    if @options[:reader_name]
      @reader_name = @options[:reader_name]
    else
      # Get the first reader.
      readers = @context.readers
      @reader_name = readers[@options[:reader_index] || 0]
    end
    
    # Query the reader's status.
    queries = PCSC::ReaderStateQueries.new 1
    queries[0].reader_name = @reader_name
    queries[0].current_state = :unknown
    @context.wait_for_status_change queries, 100
    queries.ack_changes
    
    # Prompt for card insertion unless that already happened.
    unless queries[0].current_state.include? :present
      puts "Please insert smart-card card in reader #{@reader_name}\n"
      until queries[0].current_state.include? :presentt do
        @context.wait_for_status_change queries
        queries.ack_changes
      end
      puts "Card detected\n"
    end
    
    # Connect to the card.
    @card = @context.card @reader_name, :shared 
    @atr = @card.info[:atr]
  end
  
  def disconnect
    unless @card.nil?
      @card.disconnect
      @card = nil
      @atr = nil
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
end  # class PcscTransport

end  # module Smartcard::Iso
