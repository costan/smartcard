require 'rubygems'
gem 'smartcard', '>= 0.2.1'
require 'smartcard'
require 'pp'

def test_reader_states
  reader_states = Smartcard::PCSC::ReaderStates.new(2)
  reader_states.set_current_state_of!(1, Smartcard::PCSC::STATE_ATRMATCH)
  reader_states.set_current_state_of!(0, Smartcard::PCSC::STATE_CHANGED)
  reader_states.set_event_state_of!(0, Smartcard::PCSC::STATE_IGNORE)
  reader_states.set_event_state_of!(1, Smartcard::PCSC::STATE_PRESENT)
  reader_states.set_atr_of!(1, "Ruby\0rocks!")
  reader_states.set_atr_of!(0, "grreat success")
  reader_states.set_reader_name_of!(0, "PC/SC Reader 0")
  reader_states.set_reader_name_of!(1, "CCID Reader 1")
  
  test_state1, test_state0 = reader_states.current_state_of(1), reader_states.current_state_of(0) 
  if (test_state1 != Smartcard::PCSC::STATE_ATRMATCH) or (test_state0 != Smartcard::PCSC::STATE_CHANGED) 
    puts "FAILED: ReaderStates.set_current_state_of! / current_state_of returned #{test_state1},#{test_state0} instead of #{Smartcard::PCSC::STATE_ATRMATCH},#{Smartcard::PCSC::STATE_CHANGED}\n"
    return false
  end
  test_state0, test_state1 = reader_states.event_state_of(0), reader_states.event_state_of(1) 
  if (test_state0 != Smartcard::PCSC::STATE_IGNORE) or (test_state1 != Smartcard::PCSC::STATE_PRESENT) 
    puts "FAILED: ReaderStates.set_event_state_of! / event_state_of returned #{test_state0},#{test_state1} instead of #{Smartcard::PCSC::STATE_IGNORE},#{Smartcard::PCSC::STATE_PRESENT}\n"
    return false
  end
  test_atr1, test_atr0 = reader_states.atr_of(1), reader_states.atr_of(0)
  if (test_atr1 != "Ruby\0rocks!") or (test_atr0 != "grreat success") 
    puts "FAILED: ReaderStates.set_atr_of! / atr_of returned '#{test_atr1}','#{test_atr0}' instead of 'Ruby\\0rocks!','grreat success'\n"
    return false
  end
  test_reader0, test_reader1 = reader_states.reader_name_of(0), reader_states.reader_name_of(1)
  if (test_reader0 != "PC/SC Reader 0") or (test_reader1 != "CCID Reader 1") 
    puts "FAILED: ReaderStates.set_reader_name_of! / reader_name_of returned '#{test_reader0}','#{test_reader1}' instead of 'PC/SC Reader 0','CCID Reader 1'\n"
    return false
  end
  
  [5, 2, nil].each do |bad_index|
    exception_thrown = false
    begin
      reader_states.current_state_of(bad_index)
    rescue IndexError => e
      puts "(expected) exception thrown: #{e}\n"
      exception_thrown = e
    rescue TypeError => e
      puts "(expected) exception thrown: #{e}\n"
      exception_thrown = e
    end
    unless exception_thrown
      puts "FAILED: ReaderStates.current_state_of responded for bad index #{bad_index}\n"
      return false
    end
  end
  
  return true
end

def test_io_request
  io_request = Smartcard::PCSC::IoRequest.new
  [Smartcard::PCSC::PROTOCOL_T0, Smartcard::PCSC::PROTOCOL_T1, Smartcard::PCSC::PROTOCOL_RAW].each do |t_protocol|
    io_request.protocol = t_protocol
    r_protocol = io_request.protocol 
    if r_protocol != t_protocol
      puts "FAILED: IoRequest.protocol= / protocol failed for protocol #{t_protocol} (got #{r_protocol} instead)\n"
      return false
    end     
  end
end

test_reader_states
test_io_request


context = Smartcard::PCSC::Context.new(Smartcard::PCSC::SCOPE_SYSTEM);

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
aid = [0x19, 0x83, 0x12, 0x29, 0xba, 0xbe]
select_apdu = [0x00, 0xA4, 0x04, 0x00, aid.length, aid].flatten
send_ioreq = Smartcard::PCSC::IoRequest.new; send_ioreq.protocol = Smartcard::PCSC::PROTOCOL_T1;
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
