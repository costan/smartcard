require 'test/unit'
require 'smartcard'

class SmokeTest < Test::Unit::TestCase
  def setup
  end

  def teardown    
  end

  # smoke-test to ensure that the extension loads and can call into the PC/SC library
  def test_smoke
    context = Smartcard::PCSC::Context.new(Smartcard::PCSC::SCOPE_SYSTEM)

    reader_groups = context.list_reader_groups
    readers1 = context.list_readers reader_groups
    readers2 = context.list_readers reader_groups.first
    readers3 = context.list_readers nil

    context.release
  end
end
