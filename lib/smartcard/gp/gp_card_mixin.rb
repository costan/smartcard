# GlobalPlatform (formerly OpenPlatform) interface.
#
# Author:: Victor Costan
# Copyright:: Copyright (C) 2009 Massachusetts Institute of Technology
# License:: MIT

require 'set'

# :nodoc: namespace
module Smartcard::Gp


# Module intended to be mixed into transport implementations to add commands for
# talking to GlobalPlatform smart-cards.
#
# The module talks to the card exclusively via methods in
# Smartcard::Iso::IsoCardMixin, so the transport requirements are the same as
# for that module.
module GpCardMixin
  include Smartcard::Iso::IsoCardMixin
  
  # Selects a GlobalPlatform application.
  def select_application(app_id)
    ber_data = iso_apdu! :ins => 0xA4, :p1 => 0x04, :p2 => 0x00, :data => app_id
    app_tags = Asn1Ber.decode ber_data
    app_data = {}
    Asn1Ber.visit app_tags do |path, value|
      case path
      when [0x6F, 0xA5, 0x9F65]
        app_data[:max_apdu_length] = value.inject(0) { |acc, v| (acc << 8) | v }
      when [0x6F, 0x84]
        app_data[:aid] = value
      end
    end
    app_data
  end
  
  # The default application ID of the GlobalPlatform card manager. 
  def gp_card_manager_aid
    [0xA0, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00]
  end
  
  # Issues a GlobalPlatform INITIALIZE UPDATE command.
  #
  # This should not be called directly. Call secure_session insteaad.
  #
  # Args:
  #   host_challenge:: 8-byte array with a unique challenge for the session
  #   key_version:: the key in the Security domain to be used (0 = any key)
  #
  # Returns a hash containing the command's parsed response. The keys are:
  #   :key_diversification:: key diversification data
  #   :key_version:: the key in the Security domain chosen to be used
  #   :protocol_id:: numeric ID for the secure protocol to be used
  #   :counter:: counter for creating session keys
  #   :challenge:: the card's 6-byte challenge
  #   :auth:: the card's 8-byte authentication value
  def gp_setup_secure_channel(host_challenge, key_version = 0)
    raw = iso_apdu! :cla => 0x80, :ins => 0x50, :p1 => key_version, :p2 => 0,
                    :data => host_challenge
    response = {
      :key_diversification => raw[0, 10],
      :key_version => raw[10], :protocol_id => raw[11],
      :counter => raw[12, 2].pack('C*').unpack('n').first,
      :challenge => raw[14, 6], :auth => raw[20, 8]
    }
  end
  
  # Wrapper around iso_apdu! that adds a MAC to the APDU.
  def gp_signed_apdu!(apdu_data)    
    apdu_data = apdu_data.dup
    apdu_data[:cla] = (apdu_data[:cla] || 0) | 0x04
    apdu_data[:data] = (apdu_data[:data] || []) + [0, 0, 0, 0, 0, 0, 0, 0]
    
    apdu_bytes = Smartcard::Iso::IsoCardMixin.serialize_apdu(apdu_data)[0...-9]
    mac = Des.mac_retail @gp_secure_channel_keys[:cmac], apdu_bytes.pack('C*'),
                         @gp_secure_channel_keys[:mac_iv]
    @gp_secure_channel_keys[:mac_iv] = mac
    
    apdu_data[:data][apdu_data[:data].length - 8, 8] = mac.unpack('C*')
    iso_apdu! apdu_data
  end
    
  # Issues a GlobalPlatform EXTERNAL AUTHENTICATE command.
  #
  # This should not be called directly. Call secure_session insteaad.
  #
  # Args:
  #   host_auth:: 8-byte host authentication value
  #   security:: array of desired security flags (leave empty for the default
  #              of no security)
  #
  # The return value is irrelevant. The card will fire an ISO exception if the 
  # authentication doesn't work out.
  def gp_lock_secure_channel(host_auth, security = [])
    security_level = 0
    security_flags = { :command_mac => 0x01, :response_mac => 0x10,
                       :command_encryption => 0x02 }
    security.each do |flag|
      security_level |= security_flags[flag]
    end
    gp_signed_apdu! :cla => 0x80, :ins => 0x82, :p1 => security_level, :p2 => 0,
                    :data => host_auth
  end
  
  # Sets up a secure session with the current GlobalPlatform application.
  #
  # Args:
  #   keys:: hash containing 3 3DES encryption keys, identified by the following
  #          keys:
  #            :senc:: channel encryption key
  #            :smac:: channel MAC key
  #            :dek:: data encryption key
  def secure_channel(keys = gp_development_keys)
    host_challenge = Des.random_bytes 8
    card_info = gp_setup_secure_channel host_challenge.unpack('C*')
    card_counter = [card_info[:counter]].pack('n')
    card_challenge = card_info[:challenge].pack('C*')

    # Compute session keys.
    session_keys = {}
    derivation_data = "\x01\x01" + card_counter + "\x00" * 12
    session_keys[:cmac] = Des.crypt keys[:smac], derivation_data    
    derivation_data[0, 2] = "\x01\x02"
    session_keys[:rmac] = Des.crypt keys[:smac], derivation_data
    derivation_data[0, 2] = "\x01\x82"
    session_keys[:senc] = Des.crypt keys[:senc], derivation_data
    derivation_data[0, 2] = "\x01\x81"
    session_keys[:dek] = Des.crypt keys[:dek], derivation_data
    session_keys[:mac_iv] = "\x00" * 8
    @gp_secure_channel_keys = session_keys
        
    # Compute authentication cryptograms.
    card_auth = Des.mac_3des session_keys[:senc],
        host_challenge + card_counter + card_challenge
    host_auth = Des.mac_3des session_keys[:senc],
        card_counter + card_challenge + host_challenge
        
    unless card_auth == card_info[:auth].pack('C*')
      raise 'Card authentication invalid' 
    end    

    gp_lock_secure_channel host_auth.unpack('C*')
  end
  
  # Secure channel keys for development GlobalPlatform cards.
  #
  # Most importantly, the JCOP cards and simulator work with these keys.
  def gp_development_keys
    key = (0x40..0x4F).to_a.pack('C*')
    { :senc => key, :smac => key, :dek => key }
  end
  
  # Issues a GlobalPlatform GET STATUS command.
  #
  # Args:
  #   scope:: the information to be retrieved from the card, can be:
  #     :issuer_sd:: the issuer's security domain
  #     :apps:: applications and supplementary security domains
  #     :files:: executable load files
  #     :files_modules:: executable load files and executable modules
  #   query_aid:: the AID to look for (empty array to get everything)
  #
  # Returns an array of application information data. Each element represents an
  # application, and is a hash with the following keys:
  #   :aid:: the application or file's AID
  #   :lifecycle:: the state in the application's lifecycle (symbol)
  #   :permissions:: a Set of the application's permissions (symbols)
  #   :modules:: array of modules in an executable load file, each array element
  #              is a hash with the key :aid which has the module's AID
  def gp_get_status(scope, query_aid = [])
    scope_byte = { :issuer_sd => 0x80, :apps => 0x40, :files => 0x20,
                   :files_modules => 0x10 }[scope]
    data = Asn1Ber.encode [{:class => :application, :primitive => true,
                            :number => 0x0F, :value => query_aid}]
    apps = []    
    first = true  # Set to false after the first GET STATUS is issued.
    loop do
      raw = iso_apdu :cla => 0x80, :ins => 0xF2, :p1 => scope_byte,
                     :p2 => (first ? 0 : 1), :data => [0x4F, 0x00]
      if raw[:status] != 0x9000 && raw[:status] != 0x6310 
        Smartcard::Iso::IsoCardMixin.raise_response_exception raw
      end
      
      offset = 0
      loop do
        break if offset >= raw[:data].length
        aid_length, offset = raw[:data][offset], offset + 1
        app = { :aid => raw[:data][offset, aid_length] }
        offset += aid_length
        
        if scope == :issuer_sd
          lc_states = { 1 => :op_ready, 7 => :initialized, 0x0F => :secured,
                        0x7F => :card_locked, 0xFF => :terminated }
          lc_mask = 0xFF
        else
          lc_states = { 1 => :loaded, 3 => :installed, 7 => :selectable,
              0x83 => :locked, 0x87 => :locked }
          lc_mask = 0x87
        end
        app[:lifecycle] = lc_states[raw[:data][offset] & lc_mask]

        permission_bits = raw[:data][offset + 1]
        app[:permissions] = Set.new()
        [[1, :mandated_dap], [2, :cvm_management], [4, :card_reset],
         [8, :card_terminate], [0x10, :card_lock], [0x80, :security_domain],
         [0xA0, :delegate], [0xC0, :dap_verification]].each do |mask, perm|
          app[:permissions] << perm if (permission_bits & mask) == mask
        end
        offset += 2
        
        if scope == :files_modules
          num_modules, offset = raw[:data][offset], offset + 1
          app[:modules] = []
          num_modules.times do
            aid_length = raw[:data][offset]
            app[:modules] << { :aid => raw[:data][offset + 1, aid_length] }
            offset += 1 + aid_length            
          end
        end
        
        apps << app
      end
      break if raw[:status] == 0x9000
      first = false  # Need more GET STATUS commands.
    end
    apps
  end
  
  # The GlobalPlatform applications available on the card.
  def applications
    select_application gp_card_manager_aid
    secure_channel
    gp_get_status :apps
    
    # TODO(costan): there should be a way to query the AIDs without asking the
    #               SD, which requires admin keys.
  end
  
  # Issues a GlobalPlatform DELETE command targeting an executable load file.
  #
  # Args:
  #   aid:: the executable load file's AID
  #
  # The return value is irrelevant. 
  def gp_delete_file(aid)
    data = Asn1Ber.encode [{:class => :application, :primitive => true,
                            :number => 0x0F, :value => aid}]
    response = iso_apdu! :cla => 0x80, :ins => 0xE4, :p1 => 0x00, :p2 => 0x80,
                         :data => data
    delete_confirmation = response[1, response[0]]
    delete_confirmation
  end
  
  # Deletes a GlobalPlatform application.
  #
  # Returns +false+ if the application was not found on the card, or a true
  # value if the application was deleted.
  def delete_application(application_aid)
    select_application gp_card_manager_aid
    secure_channel
    
    files = gp_get_status :files_modules
    app_file_aid = nil
    files.each do |file|
      next unless modules = file[:modules]
      next unless modules.any? { |m| m[:aid] == application_aid }
      gp_delete_file file[:aid]
      app_file_aid = file[:aid]
    end    
    app_file_aid
  end
  
  # Issues a GlobalPlatform INSTALL command that loads an application's file.
  #
  # The command should be followed by a LOAD command (see gp_load).
  #
  # Args:
  #   file_aid:: the AID of the file to be loaded
  #   sd_aid:: the AID of the security domain handling the loading
  #   data_hash:: 
  #   params:: 
  #   token:: load token (needed by some SDs)
  #
  # Returns a true value if the command returns a valid install confirmation.
  def gp_install_load(file_aid, sd_aid = nil, data_hash = [], params = {},
                      token = [])
    ber_params = []
                      
    data = [file_aid.length, file_aid, sd_aid.length, sd_aid,
            Asn1Ber.encode_length(data_hash.length), data_hash,
            Asn1Ber.encode_length(ber_params.length), ber_params,
            Asn1Ber.encode_length(token.length), token].flatten
    response = iso_apdu! :cla => 0x80, :ins => 0xE6, :p1 => 0x02, :p2 => 0x00,
                         :data => data
    response == [0x00]
  end
  
  # Issues a GlobalPlatform INSTALL command that installs an application and
  # makes it selectable.
  #
  # Args:
  #   file_aid:: the AID of the application's executable load file
  #   module_aid:: the AID of the application's module in the load file
  #   app_aid:: the application's AID (application will be selectable by it)
  #   privileges:: array of application privileges (e.g. :security_domain)
  #   params:: application install parameters
  #   token:: install token (needed by some SDs)
  #
  # Returns a true value if the command returns a valid install confirmation.
  def gp_install_selectable(file_aid, module_aid, app_aid, privileges = [],
                            params = {}, token = [])
    privilege_byte = 0
    privilege_bits = { :mandated_dap => 1, :cvm_management => 2,
        :card_reset => 4, :card_terminate => 8, :card_lock => 0x10,
        :security_domain => 0x80, :delegate => 0xA0, :dap_verification => 0xC0 }
    privileges.each { |privilege| privilege_byte |= privilege_bits[privilege] }
    
    param_tags = [{:class => :private, :primitive => true, :number => 9,
                   :value => params[:app] || []}]
    ber_params = Asn1Ber.encode(param_tags)
    
    data = [file_aid.length, file_aid, module_aid.length, module_aid,
            app_aid.length, app_aid, 1, privilege_byte,
            Asn1Ber.encode_length(ber_params.length), ber_params,
            Asn1Ber.encode_length(token.length), token].flatten
    response = iso_apdu! :cla => 0x80, :ins => 0xE6, :p1 => 0x0C, :p2 => 0x00,
                         :data => data
    response == [0x00]
  end
    
  # Issues a GlobalPlatform LOAD command.
  #
  # Args:
  #   file_data:: the file's data
  #   max_apdu_length:: the maximum APDU length, returned from
  #                     select_application
  #
  # Returns a true value if the loading succeeds. 
  def gp_load_file(file_data, max_apdu_length)
    data_tag = { :class => :private, :primitive => true, :number => 4,
                 :value => file_data }
    ber_data = Asn1Ber.encode [data_tag]
    
    max_data_length = max_apdu_length - 5
    offset = 0
    block_number = 0
    loop do
      block_length = [max_data_length, ber_data.length - offset].min
      last_block = (offset + block_length >= ber_data.length)
      response = iso_apdu! :cla => 0x80, :ins => 0xE8,
                           :p1 => (last_block ? 0x80 : 0x00),
                           :p2 => block_number,
                           :data => ber_data[offset, block_length]
      offset += block_length
      block_number += 1
      break if last_block
    end
    true
  end
  
  # Installs a JavaCard applet on the JavaCard.
  #
  # Args:
  #   cap_file:: path to the applet's CAP file
  #   package_aid:: the applet's package AID
  #   applet_aid:: the AID used to select the applet; if nil, the first AID
  #                in the CAP's Applet section is used (this works pretty well)
  #   install_data:: data to be passed to the applet at installation time
  def install_applet(cap_file, package_aid, applet_aid = nil, install_data = [])
    load_data = CapLoader.cap_load_data(cap_file)
    applet_aid ||= load_data[:applets].first[:aid]

    delete_application applet_aid
    
    manager_data = select_application gp_card_manager_aid
    max_apdu = manager_data[:max_apdu_length]
    secure_channel
        
    gp_install_load package_aid, gp_card_manager_aid
    gp_load_file load_data[:data], max_apdu
    gp_install_selectable package_aid, applet_aid, applet_aid, [],
                          { :app => install_data }    
  end
end  # module GpCardMixin

end  # namespace Smartcard::Gp
