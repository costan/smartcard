# Interface for ISO7816 cards.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2008 Massachusetts Institute of Technology
# License:: MIT


# The transport module contains classes responsible for transferring APDUs
# from a high-level representation to the smart card hardware.
module Smartcard::Iso
  # Shortcut for Smartcard::Iso::AutoConfigurator#auto_transport
  def self.auto_transport
    Smartcard::Iso::AutoConfigurator.auto_transport
  end
end
