# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT

require 'smartcard'

require 'test/unit'

require 'rubygems'
require 'flexmock/test_unit'


class AutoConfiguratorTest < Test::Unit::TestCase
  AutoConfigurator = Smartcard::Iso::AutoConfigurator
  PcscTransport = Smartcard::Iso::PcscTransport
  JcopRemoteTransport = Smartcard::Iso::JcopRemoteTransport
    
  def setup
    @env_var = AutoConfigurator::ENVIRONMENT_VARIABLE_NAME 
  end

  def test_env_configuration_blank
    flexmock(ENV).should_receive(:[]).with(@env_var).and_return(nil)
    assert_equal nil, AutoConfigurator.env_configuration
  end
  def test_env_configuration_remote_port
    flexmock(ENV).should_receive(:[]).with(@env_var).and_return(':6996')
    conf = AutoConfigurator.env_configuration
    assert_equal JcopRemoteTransport, conf[:class]
    assert_equal({:host => '127.0.0.1', :port => 6996}, conf[:opts])
  end  
  def test_env_configuration_remote_noport
    flexmock(ENV).should_receive(:[]).with(@env_var).and_return(':')
    conf = AutoConfigurator.env_configuration
    assert_equal JcopRemoteTransport, conf[:class]
    assert_equal({:host => '127.0.0.1', :port => 8050}, conf[:opts])
  end
  def test_env_configuration_remote_host_port
    flexmock(ENV).should_receive(:[]).with(@env_var).
                  and_return('@moonstone:6996')
    conf = AutoConfigurator.env_configuration
    assert_equal JcopRemoteTransport, conf[:class]
    assert_equal({:host => 'moonstone', :port => 6996}, conf[:opts])
  end
  def test_env_configuration_remote_host_noport    
    flexmock(ENV).should_receive(:[]).with(@env_var).and_return('@moonstone')
    conf = AutoConfigurator.env_configuration
    assert_equal JcopRemoteTransport, conf[:class]
    assert_equal({:host => 'moonstone', :port => 8050}, conf[:opts])
  end
  def test_env_configuration_remote_ipv6_port
    flexmock(ENV).should_receive(:[]).with(@env_var).
                  and_return('@ff80::0080:6996')
    conf = AutoConfigurator.env_configuration
    assert_equal JcopRemoteTransport, conf[:class]
    assert_equal({:host => 'ff80::0080', :port => 6996}, conf[:opts])
  end
  def test_env_configuration_remote_ipv6_noport
    flexmock(ENV).should_receive(:[]).with(@env_var).and_return('@ff80::0080:')
    conf = AutoConfigurator.env_configuration
    assert_equal JcopRemoteTransport, conf[:class]
    assert_equal({:host => 'ff80::0080', :port => 8050}, conf[:opts])
  end

  def test_env_configuration_pcsc_reader_index
    flexmock(ENV).should_receive(:[]).with(@env_var).and_return('#1')
    conf = AutoConfigurator.env_configuration
    assert_equal PcscTransport, conf[:class]
    assert_equal({:reader_index => 0}, conf[:opts])
  end
  def test_env_configuration_pcsc_reader_name
    reader_name = 'Awesome Reader'
    flexmock(ENV).should_receive(:[]).with(@env_var).
                and_return(reader_name)
    conf = AutoConfigurator.env_configuration
    assert_equal PcscTransport, conf[:class]
    assert_equal({:reader_name => reader_name}, conf[:opts])
  end
  
  def test_try_transport
    transport = Object.new
    flexmock(PcscTransport).should_receive(:new).with(:reader_index => 1).
                            and_return(transport)
    flexmock(transport).should_receive(:connect)
    flexmock(PcscTransport).should_receive(:new).with(:reader_index => 2).
                            and_raise('Boom headshot')
    failport = Object.new
    flexmock(PcscTransport).should_receive(:new).with(:reader_index => 3).
                            and_return(failport)    
    flexmock(failport).should_receive(:connect).and_raise('Lag')
    
    config = { :class => PcscTransport, :opts => {:reader_index => 1} }
    assert_equal transport, AutoConfigurator.try_transport(config)
    config = { :class => PcscTransport, :opts => {:reader_index => 2} }
    assert_equal nil, AutoConfigurator.try_transport(config)
    config = { :class => PcscTransport, :opts => {:reader_index => 3} }
    assert_equal nil, AutoConfigurator.try_transport(config)
  end
  
  def test_auto_transport_uses_env
    flexmock(ENV).should_receive(:[]).with(@env_var).and_return('#1')
    transport = Object.new
    flexmock(PcscTransport).should_receive(:new).with(:reader_index => 0).
                            and_return(transport)
    flexmock(transport).should_receive(:connect)
    
    assert_equal transport, AutoConfigurator.auto_transport
  end
  
  def test_auto_transport_with_defaults
    flexmock(ENV).should_receive(:[]).with(@env_var).and_return(nil)
    transport = Object.new
    flexmock(JcopRemoteTransport).should_receive(:new).and_return(nil)
    flexmock(PcscTransport).should_receive(:new).and_return(transport)
    flexmock(transport).should_receive(:connect)    
        
    assert_equal transport, AutoConfigurator.auto_transport
  end
end
