# DES and 3DES encryption and MAC logic for GlobalPlatform secure channels.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2009 Massachusetts Institute of Technology
# License:: MIT

require 'openssl'

# :nodoc: namespace
module Smartcard::Gp
  

# DES and 3DES encryption and MAC logic for GlobalPlatform secure channels.
module Des
  # Generates random bytes for session nonces.
  #
  # Args:
  #   bytes:: how many bytes are desired
  #
  # Returns a string of random bytes.
  def self.random_bytes(bytes)
    OpenSSL::Random.random_bytes bytes
  end

  # Perform DES or 3DES encryption.
  #
  # Args:
  #   key:: the encryption key to be used (8-byte or 16-byte)
  #   data:: the data to be encrypted or decrypted
  #   iv:: initialization vector
  #   decrypt:: if +false+ performs encryption, otherwise performs decryption
  #
  # Returns the encrypted / decrypted data.
  def self.crypt(key, data, iv = nil, decrypt = false)
    cipher_name = key.length == 8 ? 'DES-CBC' : 'DES-EDE-CBC'
    cipher = OpenSSL::Cipher::Cipher.new cipher_name
    decrypt ? cipher.decrypt : cipher.encrypt
    cipher.key = key
    cipher.iv = iv || ("\x00" * 8)
    cipher.padding = 0
    crypted = cipher.update data
    crypted += cipher.final
    crypted
  end
  
  # Computes a MAC using DES mixed with 3DES. 
  def self.mac_retail(key, data, iv = nil)
    # Output transformation: add 80, then 00 until it's block-sized.
    data = data + "\x80"
    data += "\x00" * (8 - data.length % 8) unless data.length % 8 == 0

    # DES-encrypt everything except for the last block.
    iv = crypt(key[0, 8], data[0, data.length - 8], iv)[-8, 8]
    # Take the chained block and supply it to a 3DES-encryption. 
    crypt(key, data[-8, 8], iv)
  end
  
  def self.mac_3des(key, data)
    # Output transformation: add 80, then 00 until it's block-sized.
    data = data + "\x80"
    data += "\x00" * (8 - data.length % 8) unless data.length % 8 == 0
    
    # The MAC is the last block from 3DES-encrypting the data.
    crypt(key, data)[-8, 8]
  end
end  # module Smartcard::Gp::Des

end  # namespace
