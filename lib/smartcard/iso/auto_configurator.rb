# Automatic smart-card transport selection and configuration.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT

# :nodoc: namespace
module Smartcard::Iso

# Automatic configuration code.
module AutoConfigurator  
  # The name of the environment variable that might supply the transport
  # configuration.
  ENVIRONMENT_VARIABLE_NAME = 'SCARD_PORT'
  
  # The default configurations to be tried if no configuration is specified.
  DEFAULT_CONFIGURATIONS = [
    { :class => JcopRemoteTransport,
      :opts => { :host => '127.0.0.1', :port => 8050} },
    { :class => PcscTransport, :opts => { :reader_index => 0 }}
  ]

  # Creates a transport based on available configuration information.
  def self.auto_transport
    configuration = env_configuration
    return try_transport(configuration) if configuration
    
    DEFAULT_CONFIGURATIONS.each do |config|
      transport = try_transport(config)
      return transport if transport
    end
    return nil
  end

  # Retrieves transport configuration information from an environment variable.
  #
  # :call-seq:
  #   AutoConfigurator.env_configuration -> hash
  #
  # The returned configuration has the keys required by
  # AutoConfigurator#try_transport
  def self.env_configuration
    return nil unless conf = ENV[ENVIRONMENT_VARIABLE_NAME]
    
    case conf[0]
    when ?:
      # :8050 -- JCOP emulator at port 8050
      transport_class = JcopRemoteTransport
      transport_opts = { :host => '127.0.0.1' }
      transport_opts[:port] = conf[1..-1].to_i
    when ?@
      # @127.0.0.1:8050 -- JCOP emulator at host 127.0.0.1 port 8050
      transport_class = JcopRemoteTransport
      port_index = conf.rindex(?:) || conf.length
      transport_opts = { :host => conf[1...port_index] }
      transport_opts[:port] = conf[(port_index + 1)..-1].to_i
    when ?#
      # #2 -- 2nd PC/SC reader in the system
      transport_class = PcscTransport
      transport_opts = { :reader_index => conf[1..-1].to_i - 1 }
    else
      # Reader Name -- the PC/SC reader with the given name
      transport_class = PcscTransport
      transport_opts = { :reader_name => conf }
    end
    
    transport_opts[:port] = 8050 if transport_opts[:port] == 0
    if transport_opts[:reader_index] and transport_opts[:reader_index] < 0
      transport_opts[:reader_index] = 0
    end
    { :class => transport_class, :opts => transport_opts }
  end
  
  # Attempts to create a new ISO7816 transport with the given configuration.
  # :call-seq:
  #   AutoConfigurator.try_transport(configuration) -> Transport or nil
  #
  # The configuration should have the following keys:
  #   class:: the Ruby class implementing the transport
  #   opts:: the options to be passed to the implementation's constructor
  def self.try_transport(configuration)
    raise 'No transport class specified' unless configuration[:class]
    begin
      transport = configuration[:class].new(configuration[:opts] || {})
      transport.connect
      return transport
    rescue Exception
      return nil
    end
  end
end  # module AutoConfigurator

end  # module Smartcard::Iso