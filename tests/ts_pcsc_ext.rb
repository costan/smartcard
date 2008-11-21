require 'smartcard'
require 'pp'

context = Smartcard::PCSC::Context.new(Smartcard::PCSC::SCOPE_SYSTEM)

reader_groups = context.list_reader_groups
pp reader_groups
readers1 = context.list_readers reader_groups
pp readers1
readers2 = context.list_readers reader_groups.first
pp readers2
readers3 = context.list_readers nil
pp readers3

context.cancel

reader0 = readers3.first
puts "Waiting for card in reader: #{reader0}\n"
reader_states = Smartcard::PCSC::ReaderStates.new(1)
reader_states.set_reader_name_of!(0, reader0)
reader_states.set_current_state_of!(0, Smartcard::PCSC::STATE_UNKNOWN)
while (reader_states.event_state_of(0) & Smartcard::PCSC::STATE_PRESENT) == 0 do
  context.get_status_change reader_states, Smartcard::PCSC::INFINITE_TIMEOUT
  puts "Status change: now it's #{reader_states.event_state_of(0)} and we want #{Smartcard::PCSC::STATE_PRESENT}\n"
  reader_states.acknowledge_events!
end

puts "Connecting to card\n"
card0 = Smartcard::PCSC::Card.new(context, reader0, Smartcard::PCSC::SHARE_SHARED, Smartcard::PCSC::PROTOCOL_ANY)

card0.begin_transaction
card0.end_transaction Smartcard::PCSC::DISPOSITION_LEAVE

begin
card0.reconnect Smartcard::PCSC::SHARE_EXCLUSIVE, Smartcard::PCSC::PROTOCOL_ANY, Smartcard::PCSC::INITIALIZATION_RESET
rescue RuntimeException => e
puts "Card.reconnect threw exception #{e}\n" 
end

card_status = card0.status
pp card_status
puts "ATR Length: #{card_status[:atr].length}\n"

begin
  puts "IFD vendor: #{card0.get_attribute Smartcard::PCSC::ATTR_VENDOR_IFD_VERSION}\n"
rescue RuntimeError => e
  puts "Card.get_attribute threw exception #{e}\n"
end

puts "Selecting applet\n"
aid = [0x19, 0x83, 0x12, 0x29, 0x10, 0xba, 0xbe]
select_apdu = [0x00, 0xA4, 0x04, 0x00, aid.length, aid].flatten
send_ioreq = {Smartcard::PCSC::PROTOCOL_T0 => Smartcard::PCSC::IOREQUEST_T0,
              Smartcard::PCSC::PROTOCOL_T1 => Smartcard::PCSC::IOREQUEST_T1}[card_status[:protocol]]
recv_ioreq = Smartcard::PCSC::IoRequest.new
select_response = card0.transmit(select_apdu.map {|byte| byte.chr}.join(''), send_ioreq, recv_ioreq)
select_response_str = (0...select_response.length).map { |i| ' %02x' % select_response[i].to_i }.join('')
puts "Response:#{select_response_str}\n"

begin
  # This only works with GemPlus readers... any other suggestions?
  puts "Testing low-level control\n"
  ctl_string = [0x82, 0x01, 0x07, 0x00].map {|byte| byte.chr}.join('')
  ctl_response = card0.control 2049, ctl_string, 4
  pp ctl_response
rescue RuntimeError => e
  puts "Card.control threw exception #{e}\n"
end

puts "Disconnecting and cleaning up\n"
card0.disconnect Smartcard::PCSC::DISPOSITION_LEAVE
context.release
