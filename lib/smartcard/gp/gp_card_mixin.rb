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
    iso_apdu! :ins => 0xA4, :p1 => 0x04, :p2 => 0x00, :data => app_id
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
