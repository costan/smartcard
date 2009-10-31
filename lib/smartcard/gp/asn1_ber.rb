# Encoding and decoding of ASN.1-BER data.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2009 Massachusetts Institute of Technology
# License:: MIT

# :nodoc: namespace
module Smartcard::Gp
  

# Logic for encoding and decoding ASN.1-BER data as specified in X.690-0207.
#
# TODO(costan): encoding routines, when necessary.
module Asn1Ber
  # Decodes a TLV tag (the data type).
  #
  # Args:
  #   data:: the array to decode from
  #   offset:: the position of the first byte containing the tag 
  #
  # Returns the offset of the first byte after the tag, and the tag information.
  # Tag information is a hash with the following keys.
  #   :class:: the tag's class (symbol, named after X690-0207)
  #   :primitive:: if +false+, the tag's value is a sequence of TLVs
  #   :number:: the tag's number
  def self.decode_tag(data, offset)
    class_bits = data[offset] >> 6 
    tag_class = [:universal, :application, :context, :private][class_bits]
    tag_primitive = (data[offset] & 0x20) == 0
    tag_number = (data[offset] & 0x1F)
    if tag_number == 0x1F
      tag_number = 0
      loop do      
        offset += 1
        tag_number <<= 7
        tag_number |= (data[offset] & 0x7F)
        break if (data[offset] & 0x80) == 0
      end
    end
    return (offset + 1), { :class => tag_class, :primitive => tag_primitive,
                           :number => tag_number }
  end

  # Decodes a TLV length.
  #
  # Args:
  #   data:: the array to decode from
  #   offset:: the position of the first byte containing the length
  #
  # Returns the offset of the first byte after the length, and the length. The
  # returned value might be +:indefinite+ if the encoding uses the indefinite
  # length.
  def self.decode_length(data, offset)
    return (offset + 1), data[offset] if (data[offset] & 0x80) == 0
    len_bytes = (data[offset] & 0x7F)
    return (offset + 1), :indefinite if len_bytes == 0
    length = 0
    len_bytes.times do
      offset += 1
      length = (length << 8) | data[offset]
    end
    return (offset + 1), length
  end
  
  
  # Decodes a TLV value.
  #
  # Args:
  #   data:: the array to decode from
  #   offset:: the position of the first byte containing the length
  #
  # Returns the offset of the first byte after the value, and the value.
  def self.decode_value(data, offset, length)    
    return offset + length, data[offset, length] unless length == :indefinite
    
    length = 0
    loop do
      raise 'Unterminated data' if offset + length + 2 > data.length
      break if data[offset + length, 2] == [0, 0]
      length += 1
    end
    return (offset + length + 2), data[offset, length]
  end
  
  # Maps a TLV value with a known tag to a Ruby data type.
  def self.map_value(value, tag)
    # TODO(costan): map primitive types if necessary
    value
  end
  
  # Decodes a TLV (tag-length-value).
  #
  # Returns a 2-element array, where the first element has tag information, and
  # the second element is the value. See decode_tag for the format of the tag
  # information.
  def self.decode_tlv(data, offset)
    offset, tag = decode_tag data, offset
    offset, length = decode_length data, offset
    offset, value = decode_value data, offset, length
    
    value = tag[:primitive] ? map_value(value, tag) :
                              decode_tlv_sequence(value)
    return offset, [tag, value]
  end
  
  # Decodes a sequence of TLVs (tag-length-value).
  #
  # Returns an array with one element for each TLV in the sequence. See
  # decode_tlv for the format of each array element.
  def self.decode(data, offset = 0, length = data.length - offset)
    sequence = []
    loop do
      offset, tlv = decode_tlv data, offset
      sequence << tlv
      break if offset >= length
    end
    sequence
  end
end  # module Smartcard::Gp::Asn1Ber
  
end  # namespace
