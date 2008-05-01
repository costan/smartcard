require 'test/unit'
require 'smartcard'

class ContainersTest < Test::Unit::TestCase
  def setup
    
  end
  
  def teardown
    
  end
  
  # tests the SmartCard::PCSC::ReaderStates container
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
    
    assert_equal Smartcard::PCSC::STATE_ATRMATCH, reader_states.current_state_of(1), 'ReaderStates.set_current_state_of! / current_state_of mismatch'
    assert_equal Smartcard::PCSC::STATE_CHANGED, reader_states.current_state_of(0), 'ReaderStates.set_current_state_of! / current_state_of mismatch'

    assert_equal Smartcard::PCSC::STATE_IGNORE, reader_states.event_state_of(0), 'ReaderStates.set_event_state_of! / event_state_of mismatch'
    assert_equal Smartcard::PCSC::STATE_PRESENT, reader_states.event_state_of(1), 'ReaderStates.set_event_state_of! / event_state_of mismatch' 

    assert_equal "Ruby\0rocks!", reader_states.atr_of(1), 'ReaderStates.set_atr_of! / atr_of mismatch'
    assert_equal "grreat success", reader_states.atr_of(0), 'ReaderStates.set_atr_of! / atr_of mismatch' 
    
    assert_equal "PC/SC Reader 0", reader_states.reader_name_of(0)
    assert_equal "CCID Reader 1", reader_states.reader_name_of(1)
    
    [[5, IndexError], [2, IndexError], [nil, TypeError]].each do |bad_index_test|
      assert_raise bad_index_test[1] do
        reader_states.current_state_of(bad_index_test[0])
      end
    end
  end

  # tests the SmartCard::PCSC::IoRequest container
  def test_io_request
    io_request = Smartcard::PCSC::IoRequest.new
    [Smartcard::PCSC::PROTOCOL_T0, Smartcard::PCSC::PROTOCOL_T1, Smartcard::PCSC::PROTOCOL_RAW].each do |t_protocol|
      io_request.protocol = t_protocol
      r_protocol = io_request.protocol
      assert_equal r_protocol, t_protocol, 'IoRequest.protocol= / protocol mismatch'
    end
  end  
end