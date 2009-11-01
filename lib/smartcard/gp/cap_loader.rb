# Loads JavaCard CAP files.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2009 Massachusetts Institute of Technology
# License:: MIT

require 'zip/zip'

# :nodoc: namespace
module Smartcard::Gp


# Logic for loading JavaCard CAP files.
module CapLoader
  # Loads a CAP file.
  #
  # Returns a hash mapping component names to component data.
  def self.load_cap(cap_file)
    components = {}    
    Zip::ZipFile.open(cap_file) do |file|
      file.each do |entry|
        data = entry.get_input_stream { |io| io.read }
        offset = 0
        while offset < data.length          
          tag = TAG_NAMES[data[offset, 1].unpack('C').first]
          length = data[offset + 1, 2].unpack('n').first
          value = data[offset + 3, length]
          components[tag] = value
          offset += 3 + length
        end
      end
    end    
    components
  end
  
  # Serializes CAP components for on-card loading.
  #
  # Returns an array of bytes.
  def self.serialize_components(components)
    [:header, :directory, :import, :applet, :class, :method, :static_field,
     :export, :constant_pool, :reference_location].map { |name|
      tag = TAG_NAMES.keys.find { |k| TAG_NAMES[k] == name }
      if components[name]
        length = [components[name].length].pack('n').unpack('C*')
        data = components[name].unpack('C*')
        [tag, length, data]
      else
        []
      end
    }.flatten
  end
  
  # Parses the Applet section in a CAP file, obtaining applet AIDs.
  #
  # Returns an array of hashes, one hash per applet. The hash has a key +:aid+
  # that contains the applet's AID.
  def self.parse_applets(components)    
    applets = []
    return applets unless section = components[:applet]
    offset = 1
    section[0].times do
      aid_length = section[offset]
      install_method = section[offset + 1 + aid_length, 2].unpack('n').first
      applets << { :aid => section[offset + 1, aid_length].unpack('C*'),
                   :install_method => install_method }
      offset += 3 + aid_length
    end
    applets
  end
  
  # Loads a CAP file and serializes its components for on-card loading.
  #
  # Returns an array of bytes.
  def self.cap_load_data(cap_file)
    components = load_cap cap_file
    { :data => serialize_components(components),
      :applets => parse_applets(components) } 
  end
    
  # Maps numeric tags to tag names.
  TAG_NAMES = {
    1 => :header, 2 => :directory, 3 => :applet, 4 => :import,
    5 => :constant_pool, 6 => :class, 7 => :method, 8 => :static_field,
    9 => :reference_location, 10 => :export, 11 => :descriptor, 12 => :debug
  }
end  # module Smartcard::Gp::CapLoader

end  # namespace