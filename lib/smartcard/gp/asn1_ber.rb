# Encoding and decoding of ASN.1-BER data.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2009 Massachusetts Institute of Technology
# License:: MIT

# :nodoc: namespace
module Smartcard::Gp
  

# Logic for encoding and decoding ASN.1-BER data as specified in X.690-0207.
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
  # Returns a hash that contains tag and value information. See decode_tag for
  # the keys containing the tag information. Value information is contained in
  # the :value: tag.
  def self.decode_tlv(data, offset)
    offset, tag = decode_tag data, offset
    offset, length = decode_length data, offset
    offset, value = decode_value data, offset, length
    
    tag[:value] = tag[:primitive] ? map_value(value, tag) : decode(value)
    return offset, tag
  end
  
  # Decodes a sequence of TLVs (tag-length-value).
  #
  # Returns an array with one element for each TLV in the sequence. See
  # decode_tlv for the format of each array element.
  def self.decode(data, offset = 0, length = data.length - offset)
    sequence = []
    loop do
      break if offset >= length
      offset, tlv = decode_tlv data, offset
      sequence << tlv
    end
    sequence
  end
  
  # Encodes a TLV tag (the data type).
  #
  # Args:
  #   tag:: a hash with the keys produced by decode_tag.
  #
  # Returns an array of byte values.
  def self.encode_tag(tag)
    tag_classes = { :universal => 0, :application => 1, :context => 2,
                    :private => 3 } 
    tag_lead = (tag_classes[tag[:class]] << 6) | (tag[:primitive] ? 0x00 : 0x20)
    return [tag_lead | tag[:number]] if tag[:number] < 0x1F
    
    number_bytes, number = [], tag[:number]
    first = true
    while number != 0
      byte = (number & 0x7F)
      number >>= 7
      byte |= 0x80 unless first
      first = false
      number_bytes << byte
    end
    [tag_lead | 0x1F] + number_bytes.reverse
  end
  
  # Encodes a TLV length (the length of the data).
  #
  # Args::
  #   length:: the length to be encoded (number of :indefinite)
  #
  # Returns an array of byte values.
  def self.encode_length(length)
    return [0x80] if length == :indefinite
    return [length] if length < 0x80
    length_bytes = []
    while length > 0
      length_bytes << (length & 0xFF)
      length >>= 8
    end
    [0x80 | length_bytes.length] + length_bytes.reverse
  end
  
  # Encodes a TLV (tag-length-value).
  #
  # Args::
  #   tlv:: hash with tag and value information, to be encoeded as TLV; see
  #         decode_tlv for the hash keys encoding the tag and value
  #
  # Returns an array of byte values.
  def self.encode_tlv(tlv)
    value = tlv[:primitive] ? tlv[:value] : encode(tlv[:value])
    [encode_tag(tlv), encode_length(value.length), value].flatten
  end
  
  # Encodes a sequence of TLVs (tag-length-value).
  #
  # Args::
  #   tlvs:: an array of hashes to be encoded as TLV
  #
  # Returns an array of byte values.
  def self.encode(tlvs)
    tlvs.map { |tlv| encode_tlv tlv }.flatten
  end
  
  # Visitor pattern for decoded TLVs.
  #
  # Args:
  #   tlvs:: the TLVs to visit
  #   tag_path:: internal, do not use
  #
  # Yields: |tag_path, value| tag_path lists the numeric tags for the current
  # value's tag, and all the parents' tags.
  def self.visit(tlvs, tag_path = [], &block)
    tlvs.each do |tlv|
      tag_number = encode_tag(tlv).inject { |acc, v| (acc << 8) | v }
      new_tag_path = tag_path + [tag_number]
      yield new_tag_path, tlv[:value]
      next if tlv[:primitive]
      visit tlv[:value], new_tag_path, &block
    end
  end
end  # module Smartcard::Gp::Asn1Ber
  
end  # namespace
