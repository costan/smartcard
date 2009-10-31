# GlobalPlatform (formerly OpenPlatform) interface.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2009 Massachusetts Institute of Technology
# License:: MIT

# :nodoc: namespace
module Smartcard::Gp


module GpCardMixin
  include Smartcard::Iso::IsoCardMixin  
  
  # Selects a GlobalPlatform application.
  def select_application(app_id)
    app_data = iso_apdu! :ins => 0xA4, :p1 => 0x04, :p2 => 0x00, :data => app_id
    p app_data
    Asn1Ber.decode_tlv_sequence app_data
  end
  
  # The default application ID of the GlobalPlatform card manager. 
  def card_manager_aid
    [0xA0, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00]
  end
  
  # Retrieves the value associated with a key for the current application.
  def get_data(tag, tag_list = [])
    iso_apdu! :cla => 0x80, :ins => 0xCA, :p1p2 => tag, :data => tag_list
  end
  
  # The GlobalPlatform applications available on the card.
  def applications
    p select_application(card_manager_aid)
    response = get_data 0x2F00, [0x5C, 0x00]
    p response
  end
  
  # Installs a JavaCard applet on the JavaCard.
  #
  # This would be really, really nice to have. Sadly, it's a far away TBD right
  # now.
  def install_applet(cap_contents)
    raise "Not implemeted; it'd be nice though, right?"
  end
end  # module GpCardMixin

end  # namespace Smartcard::Gp
